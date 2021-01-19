//
//  NetworkMiddleware.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 12/12/20.
//

import SwiftRex

class NetworkMiddleware: Middleware {
    
    typealias InputActionType = NetworkAction
    typealias OutputActionType = AppAction
    typealias StateType = AppState
    
    private var getState: GetState<AppState>!
    private var output: AnyActionHandler<AppAction>!
    
    func receiveContext(getState: @escaping GetState<AppState>, output: AnyActionHandler<AppAction>) {
        self.getState = getState
        self.output = output
    }
    
    func handle(action: NetworkAction, from dispatcher: ActionSource, afterReducer: inout AfterReducer) {
        switch action {
        case .connect(let serverInfo):
            let connection = Connection(
                name: serverInfo.host,
                serverInfo: serverInfo,
                store: Store.instance)
            
            let serverChannel = IRCChannel(
                connection: connection,
                name: Connection.serverChannel,
                state: .joined)
            
            // FIXME: should be a reducer action
            connection.channels.append(serverChannel)
            
            connection.client.connect()
            
            output.dispatch(.network(
                                .connectionAdded(
                                    connection: connection,
                                    serverChannel: serverChannel)))
            
            output.dispatch(.ui(
                                .connectionAdded(
                                    connection: connection)))
            
        case .reconnect(let connection):
            // client will dispatch an action to inform when it's connected
            connection.client.connect()
            
        case .disconnect(let connection):
            // client will dispatch an action to inform when it's disconnected
            connection.client.disconnect()
            
        case .joinedChannel(let connection, let channelName, let identifier):
            let state = getState()
            
            guard let target = state.network.connections.first(where: { $0 === connection }) else { break }
            
            // does this join message refer to us? if so, add a new channel and set it to be active
            // otherwise, this message refers to another user joining a channel we are listening on already
            if identifier == target.identifier {
                // if we already have this channel registered, set its status to joined
                // otherwise, add a new channel and set it as our active channel
                if target.channels.contains(where: { $0.name == channelName }) {
                    output.dispatch(.network(
                                        .channelStateChanged(
                                            connection: target,
                                            channelName: channelName,
                                            channelState: .joined)))
                } else {
                    output.dispatch(.network(
                                        .clientJoinedChannel(
                                            connection: target,
                                            channelName: channelName)))
                    
                    output.dispatch(.ui(
                                        .changeChannel(
                                            connection: target,
                                            channelName: channelName)))
                }
            } else {
                output.dispatch(.network(
                                    .userJoinedChannel(
                                        connection: target,
                                        channelName: channelName,
                                        user: User(from: identifier))))
            }
            
            // add a message indicating a user joined
            output.dispatch(.network(
                                .messageReceived(
                                    connection: target,
                                    channelName: channelName,
                                    message: ChannelMessage(
                                        text: "\(identifier.raw) has joined \(channelName)",
                                        variant: .userJoined))))
            
        case .partedChannel(let connection, let channelName, let identifier, let nick, let reason):
            let state = getState()
            
            guard let target = state.network.connections.first(where: { $0 === connection }),
                  let channel = target.channels.first(where: { $0.name == channelName }) else { break }
            
            // append the parting reason, if one was given
            var message = "\(identifier) has left \(channelName)"
            if let reasonText = reason, !reasonText.isEmpty {
                message = "\(message) (\(reasonText))"
            }
            
            // dispatch an action to inform that a a user has left
            output.dispatch(.network(
                                .messageReceived(
                                    connection: target,
                                    channelName: channelName,
                                    message: ChannelMessage(
                                        text: message,
                                        variant: .userParted))))
            
            // does this message refer to us? if so, part the channel from our perspective.
            // if another user has left, remove them from the user list.
            if identifier == target.identifier?.raw {
                output.dispatch(.network(
                                    .clientLeftChannel(
                                        connection: target,
                                        channelName: channelName)))
            } else if let targetUser = channel.users.first(where: { $0.name == nick }) {
                output.dispatch(.network(
                                    .userLeftChannel(
                                        conn: connection,
                                        channelName: channelName,
                                        user: targetUser)))
            }
            
        case .usernamesReceived(let connection, let channelName, let usernames):
            let state = getState()
            guard let target = state.network.connections.first(where: { $0 === connection }) else { break }
            
            let users = usernames.map { (nick: String) -> User in
                // does this user have elevated privileges in this channel? if so, parse the prefix and remove it
                // from the nick itself
                if let privilege = User.ChannelPrivilege(rawValue: nick.first!) {
                    return User(name: String(nick.dropFirst()), privilege: privilege)
                }
                
                return User(name: nick, privilege: .none)
            }
            
            output.dispatch(.network(
                                .updateChannelUsers(
                                    connection: target,
                                    channelName: channelName,
                                    users: users)))
            
        case .channelTopicReceived(let connection, let channelName, let topic):
            // update the topic on the channel
            output.dispatch(.network(
                                .updateChannelTopic(
                                    connection: connection,
                                    channelName: channelName,
                                    topic: topic)))
            
            // add a message to the channel
            dispatchChannelMessage(
                connection: connection,
                channelName: channelName,
                message: ChannelMessage(
                    text: "Channel topic is: \(topic)",
                    variant: .channelTopicEvent))
            
        case .channelTopicChanged(let connection, let channelName, let identifier, let topic):
            // update the topic on the channel
            output.dispatch(.network(
                                .updateChannelTopic(
                                    connection: connection,
                                    channelName: channelName,
                                    topic: topic)))
            
            // add a message to the channel
            dispatchChannelMessage(
                connection: connection,
                channelName: channelName,
                message: ChannelMessage(
                    text: "\(identifier.subject) sets channel topic to: \(topic)",
                    variant: .channelTopicEvent))
            
        case .messageSent(let channel, let text):
            var message = text
            
            switch text.lowercased() {
            // when joining a previously parted channel, we can automatically add the channel name to the join
            // command to effectively "rejoin" that channel without the user explicitly stating the channel name
            case _ where text.starts(with: "/join"):
                let state = getState()
                guard let currentChannel = state.ui.currentChannel else { break }
                
                let parts = text.components(separatedBy: " ")
                if parts.count == 1 {
                    message = "\(parts[0]) \(currentChannel.name)"
                }
                
                break
                
            // when parting a channel, try and detect if we need to include the name of the currently active
            // channel in the command
            case _ where text.starts(with: "/part"):
                let state = getState()
                guard let currentChannel = state.ui.currentChannel else { break }
                
                var parts = text.components(separatedBy: " ")
                if parts.count == 1 {
                    // no channel name given; append the current channel to the end of the command
                    parts.append(currentChannel.name)
                } else if parts.count > 1 {
                    // multiple parameters given; is the first parameter the name of a channel we know?
                    let knownChannels = parts[1].components(separatedBy: ",").filter { chan in
                        return state.network.channelUuids.values.contains(where: { $0.name == chan })
                    }
                    
                    // if none of the channels are known, insert the current channel name as the first parameter
                    if knownChannels.isEmpty {
                        parts.insert(currentChannel.name, at: 1)
                    }
                }
                
                // rebuild the original command with our modifications
                message = parts.joined(separator: " ")
                
            // when setting a channel topic, set the channel name if we are currently in a channel
            case _ where text.starts(with: "/topic"):
                let state = getState()
                var parts = text.components(separatedBy: " ")
                
                // first parameter should be a channel. this may not be the case if the user is currently in a
                // channel, and issues a "/topic my topic" command, for example. in this situation, we need to
                // insert the channel name to form a valid command.
                if (parts.count == 1 || IRCChannel.ChannelType.parseString(string: parts[1]) == nil),
                   let currentChannel = state.ui.currentChannel {
                    parts.insert(currentChannel.name, at: 1)
                }
                
                // if there is a second parameter (the new channel topic), make sure to prefix it with a leading colon
                if parts.count > 2 && parts[2].first != ":" {
                    parts[2] = ":\(parts[2])"
                }
                
                message = parts.joined(separator: " ")
                
            // not a command; could be a normal chat message sent in a channel. in this case, convert the plain text
            // message into a /privmsg command
            case _ where !text.starts(with: "/"):
                let state = getState()
                
                guard let currentChannel = state.ui.currentChannel,
                      let identifier = currentChannel.connection.identifier else { break }
                
                // don't sent messages on the server channel though
                if currentChannel.name == Connection.serverChannel {
                    break
                }
                
                output.dispatch(.network(
                                    .messageReceived(
                                        connection: currentChannel.connection,
                                        channelName: currentChannel.name,
                                        message: ChannelMessage(
                                            sender: identifier.subject,
                                            text: text,
                                            variant: .privateMessage))))
                
                message = "/privmsg \(currentChannel.name) :\(text)"
                
            default:
                break
            }
            
            // strip the leading slash if the message contains a command
            message = message.starts(with: "/") ? message.subString(from: 1) : message
            channel.connection.client.sendMessage(message)
            
        case .privateMessageReceived(let connection, _, _, let recipient, let message):
            let state = getState()
            guard let target = state.network.connections.first(where: { $0 === connection }) else { break }
            
            // is the recipient a channel? if so, add the message to the channel
            if let channel = target.channels.first(where: { $0.name == recipient }) {
                dispatchChannelMessage(
                    connection: connection,
                    channelName: channel.name,
                    message: message)
            }
            
        case .errorReceived(let connection, let message):
            let state = getState()
            
            if let target = state.network.connections.first(where: { $0 === connection }) {
                dispatchChannelMessage(
                    connection: target,
                    channelName: Connection.serverChannel,
                    message: message)
            }
            
        default:
            break
        }
    }
    
    private func dispatchChannelMessage(connection: Connection, channelName: String, message: ChannelMessage) {
        let state = getState()
        
        output.dispatch(.network(
                            .messageReceived(
                                connection: connection,
                                channelName: channelName,
                                message: message)))
        
        guard let channel = connection.channels.first(where: { $0.name == channelName }) else { return }
        
        // if this channel is not currently active, mark this message as new
        if channel != state.ui.currentChannel {
            // did we get mentioned? see if our nick appears anywhere in the message
            if let nick = connection.identifier?.subject,
               message.text.range(of: "\\s?(\(nick))\\s?", options: .regularExpression, range: nil, locale: nil) != nil {
                
                output.dispatch(.network(
                                    .addChannelNotification(
                                        connection: connection,
                                        channelName: channel.name,
                                        notification: .mention)))
                
            } else {
                output.dispatch(.network(
                                    .addChannelNotification(
                                        connection: connection,
                                        channelName: channel.name,
                                        notification: .newMessages)))
            }
        }
    }
}
