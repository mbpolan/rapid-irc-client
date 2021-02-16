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
        case .connect(let serverInfo, let joinChannelNames):
            let connection = Connection(
                name: serverInfo.host,
                serverInfo: serverInfo,
                store: Store.instance)
            
            let serverChannel = IRCChannel(
                connection: connection,
                name: Connection.serverChannel,
                descriptor: .server,
                state: .joined)
            
            // FIXME: should be a reducer action
            connection.channels.append(serverChannel)
            
            output.dispatch(.network(
                                .connectionAdded(
                                    connection: connection,
                                    serverChannel: serverChannel)))
            
            output.dispatch(.ui(
                                .connectionAdded(
                                    connection: connection)))
            
            connection.client.connect { result in
                self.updateServerConnectionStatus(connection: connection, result: result)
                
                if let joinChannelNames = joinChannelNames {
                    self.joinChannelsAfterConnect(result, connection: connection, channelNames: joinChannelNames)
                }
            }
            
        case .reconnect(let connection, let joinChannelNames):
            connection.client.connect { result in
                self.updateServerConnectionStatus(connection: connection, result: result)
                
                if let joinChannelNames = joinChannelNames {
                    self.joinChannelsAfterConnect(result, connection: connection, channelNames: joinChannelNames)
                }
            }
            
        case .disconnect(let connection):
            connection.client.disconnect { _ in
                let serverInfo = connection.client.server
                
                // put a message into the server channel indicating we're disconnected
                self.output.dispatch(.network(
                                        .messageReceived(
                                            connection: connection,
                                            channelName: Connection.serverChannel,
                                            message: ChannelMessage(
                                                text: "Disconnected from \(serverInfo.host):\(serverInfo.port)",
                                                variant: .client))))
                
                // dispatch the connection is no longer active
                self.updateServerConnectionStatus(
                    connection: connection,
                    result: .success(.disconnected))
            }
        
        case .disconnectAllForSleep(let completion):
            let state = getState()
            let group = DispatchGroup()
            
            // find all active connections
            state.network.connections
                .filter { $0.state == .connected }
                .forEach { connection in
                    group.enter()
                    
                    // disconnect from the server
                    connection.client.disconnect(status: { _ in
                        // push a message indicating we disconnected because of sleep mode
                        self.output.dispatch(.network(
                                            .messageReceived(
                                                connection: connection,
                                                channelName: Connection.serverChannel,
                                                message: ChannelMessage(
                                                    text: "Disconnected due to sleep",
                                                    variant: .client))))
                        
                        // update connection state to indicate it's disconnected
                        self.updateServerConnectionStatus(
                            connection: connection,
                            result: .success(.disconnected))
                        
                        // upon disconnect, mark that this task is complete
                        group.leave()
                    })
            }
            
            // wait for all connections to be dropped
            group.wait()
            
            // invoke the completion handler to indicate we're done
            afterReducer = .do(completion)
            
        case .joinedChannel(let connection, let channelName, let identifier):
            let state = getState()
            
            guard let target = state.network.connections.first(where: { $0 === connection }) else { break }
            
            // does this join message refer to us? if so, add a new channel and set it to be active
            // otherwise, this message refers to another user joining a channel we are listening on already
            if identifier.subject == target.identifier?.subject {
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
                                            channelName: channelName,
                                            descriptor: .multiUser)))
                    
                    output.dispatch(.ui(
                                        .changeChannel(
                                            connection: target,
                                            channelName: channelName)))
                }
                
                // ask for the latest channel mode
                target.client.sendMessage("MODE \(channelName)")
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
            } else if let targetUser = channel.users.first(where: { $0.nick == nick }) {
                output.dispatch(.network(
                                    .userLeftChannel(
                                        conn: connection,
                                        channelName: channelName,
                                        user: targetUser)))
            }
            
        case .nickReceived(let connection, let identifier, let nick):
            let state = getState()
            guard let target = state.network.connections.first(where: { $0 === connection }) else { break }
            
            // rename the user in all known multiuser channels on this connection
            target.channels
                .filter { $0.descriptor == .multiUser }
                .forEach { channel in
                    if let user = channel.users.first(where: { $0.nick == identifier.subject }) {
                        // remove the user from the channel
                        output.dispatch(.network(
                                            .userLeftChannel(
                                                conn: target,
                                                channelName: channel.name,
                                                user: user)))
                        
                        // rename the user
                        let updatedUser = user
                        updatedUser.nick = nick
                        
                        // add them back to the channel
                        output.dispatch(.network(
                                            .userJoinedChannel(
                                                connection: target,
                                                channelName: channel.name,
                                                user: updatedUser)))
                        
                        // dispatch a message into the channel
                        dispatchChannelMessage(
                            connection: target,
                            channelName: channel.name,
                            message: ChannelMessage(
                                text: "\(identifier.subject) is now known as \(nick)",
                                variant: .other))
                    }
                }
            
            // does this nick change refer to us? if so, update our own nick references
            if identifier.subject == target.identifier?.subject {
                target.identifier = target.identifier?.withSubject(nick)
                
                // dispatch a message into the server channel and each private channel we have open with other users
                target.channels
                    .filter { $0.descriptor == .user || $0.descriptor == .server }
                    .forEach { channel in
                        let text = channel.descriptor == .server
                            ? "You are now known as \(nick)"
                            : "\(identifier.subject) is now known as \(nick)"
                        
                        dispatchChannelMessage(
                            connection: target,
                            channelName: channel.name,
                            message: ChannelMessage(
                                text: text,
                                variant: .other))
                    }
            }
            
            // if we have a private channel open with this user, we need to rename it as well
            if target.channels.contains(where: { $0.name == identifier.subject && $0.descriptor == .user }) {
                output.dispatch(.network(
                                    .renameChannel(
                                        connection: target,
                                        oldChannelName: identifier.subject,
                                        newChannelName: nick)))
            }
            
        case .usernamesReceived(let connection, let channelName, let usernames):
            let state = getState()
            guard let target = state.network.connections.first(where: { $0 === connection }) else { break }
            
            let users = usernames.map { (nick: String) -> User in
                return User(from: nick)
            }
            
            // if the channel corresponds to the server channel, then this names list is for all users on the server
            if channelName == Connection.serverChannel {
                let text = users.map { " - \($0.nick)" }.joined(separator: "\n")
                
                dispatchChannelMessage(
                    connection: target,
                    channelName: Connection.serverChannel,
                    message: ChannelMessage(
                        text: text,
                        variant: .other))
            } else {
                // dispatch an action that contains this new list of incoming users for this channel
                output.dispatch(.network(
                                    .addIncomingChannelUsers(
                                        connection: target,
                                        channelName: channelName,
                                        users: Set(users))))
            }
            
        case .allUsernamesReceived(let connection, let channelName):
            let state = getState()
            guard let target = state.network.connections.first(where: { $0 === connection }) else { break }
            
            // if the channel corresponds to the server channel, then this names list was for all users on the server
            if channelName == Connection.serverChannel {
                dispatchChannelMessage(
                    connection: target,
                    channelName: Connection.serverChannel,
                    message: ChannelMessage(
                        text: "End of user list",
                        variant: .other))
            } else {
                // the list of incoming users becomes the complete list of users
                output.dispatch(.network(
                                    .applyIncomingChannelUsers(
                                        connection: target,
                                        channelName: channelName)))
                
                // the list of incoming users is cleared out
                output.dispatch(.network(
                                    .clearIncomingChannelUsers(
                                        connection: target,
                                        channelName: channelName)))
            }
            
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
            
            // show a different message if the topic was removed
            let text = topic.isEmptyOrWhitespace
                ? "\(identifier.subject) removes the current channel topic"
                : "\(identifier.subject) sets channel topic to: \(topic)"
            
            // add a message to the channel
            dispatchChannelMessage(
                connection: connection,
                channelName: channelName,
                message: ChannelMessage(
                    text: text,
                    variant: .channelTopicEvent))
            
        case .channelTopicMetadataReceived(let connection, let channelName, let who, let when):
            // store the metadata for later viewing
            output.dispatch(.network(
                                .updateChannelTopicMetadata(
                                    connection: connection,
                                    channelName: channelName,
                                    who: who,
                                    when: when)))
            
            let formattedDate = DateFormatter.displayDateFormatter.string(from: when)
            
            // add a message to the channel
            dispatchChannelMessage(
                connection: connection,
                channelName: channelName,
                message: ChannelMessage(
                    text: "Channel topic set by \(who) on \(formattedDate)",
                    variant: .channelTopicEvent))
            
        case .messageSent(let channel, let text):
            var message = text
            var deferred: (() -> Void)?
            
            switch text.lowercased() {
            // prefix away messages with a leading colon
            case _ where text.starts(with: "/away"):
                let parts = text.components(separatedBy: " ")
                
                // if there is at least one parameter, that implies there is an away message
                if parts.count > 1 {
                    message = "\(parts[0]) :\(parts[1...].joined(separator: " "))"
                } else {
                    message = text
                }
                
            // add the origin name to a ping commnd
            case _ where text.starts(with: "/ping"):
                let state = getState()
                guard let currentChannel = state.ui.currentChannel else { break }
                
                let parts = text.components(separatedBy: " ")
                if parts.count == 1,
                   let hostname = currentChannel.connection.hostname {
                    message = "\(parts[0]) :\(hostname)"
                } else {
                    message = "\(parts[0]) :\(parts[1...].joined(separator: " "))"
                }
                
            // when joining a previously parted channel, we can automatically add the channel name to the join
            // command to effectively "rejoin" that channel without the user explicitly stating the channel name
            case _ where text.starts(with: "/join"):
                let state = getState()
                guard let currentChannel = state.ui.currentChannel else { break }
                
                let parts = text.components(separatedBy: " ")
                if parts.count == 1 {
                    message = "\(parts[0]) \(currentChannel.name)"
                }
                
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
                
            // when querying or changing a mode, append the channel name if it is missing
            case _ where text.starts(with: "/mode"):
                let state = getState()
                guard let currentChannel = state.ui.currentChannel else { break }
                
                // if the user issued the mode command from the server channel, assume they are requesting mode
                // information about themselves. otherwise, if they do so in a channel, assume they are requesting
                // mode reply for the channel itself.
                guard let modeTarget = currentChannel.descriptor == .server
                        ? currentChannel.connection.identifier?.subject
                        : currentChannel.name else { break }
                
                var parts = text.components(separatedBy: " ")
                
                // if no parameters are given, append the target to the command
                // if the command is issued in a channel, and the first parameter is not the channel, insert the channel name
                if parts.count == 1 {
                    parts.append(modeTarget)
                } else if currentChannel.descriptor == .multiUser && parts[1] != modeTarget {
                    parts.insert(modeTarget, at: 1)
                }
                
                message = parts.joined(separator: " ")
                
            // ctcp action command
            case _ where text.starts(with: "/me"):
                let state = getState()
                
                guard let currentChannel = state.ui.currentChannel,
                      let identifier = currentChannel.connection.identifier else { break }
                
                let action = text.components(separatedBy: " ").dropFirst().joined(separator: " ")
                
                // echo this message back to us
                output.dispatch(.network(
                                    .messageReceived(
                                        connection: currentChannel.connection,
                                        channelName: currentChannel.name,
                                        message: ChannelMessage(
                                            sender: identifier.subject,
                                            text: action,
                                            variant: .action))))
                
                message = "/privmsg \(currentChannel.name) :\u{01}ACTION \(action)\u{01}"
                
            // quit commands result in all channels being parted and a quit message sent to the server
            case _ where text.starts(with: "/quit"):
                var parts = text.components(separatedBy: " ")
                
                // if a message is given, prefix it with a colon
                if parts.count > 1 {
                    parts[1] = ":\(parts[1])"
                }
                
                message = parts.joined(separator: " ")
                
                // defer the disconnect until after we sent the quit command
                deferred = { [weak self] in
                    self?.output.dispatch(.network(.disconnect(connection: channel.connection)))
                }
                
            // not a command; could be a normal chat message sent in a channel. in this case, convert the plain text
            // message into a /privmsg command
            case _ where !text.starts(with: "/"):
                let state = getState()
                
                guard let currentChannel = state.ui.currentChannel,
                      let identifier = currentChannel.connection.identifier else { break }
                
                // don't sent messages on the server channel though
                if currentChannel.descriptor == .server {
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
            
            // execute any deferred actions now
            if let finalizer = deferred {
                finalizer()
            }
            
        case .operatorLogin(let connection, let username, let password):
            let state = getState()
            guard let target = state.network.connections.first(where: { $0 === connection }) else { break }
            
            target.client.sendMessage("OPER \(username) \(password)")
        
        case .modeReceived(let connection, let identifier, let modeTarget, let modeString, let modeArgs):
            let state = getState()
            guard let target = state.network.connections.first(where: { $0 === connection }),
                  let modeTargetPrefix = modeTarget.first else { break }
            
            var text = "\(identifier.subject) sets mode \(modeString)"
            if !modeArgs.isEmpty {
                text = "\(text) \(modeArgs.joined(separator: " "))"
            }
            
            // if the target is a channel, add a message to the channel in question.
            // otherwise, if this is a user mode message, add a message to the corresponding server channel
            let channelName = IRCChannel.ChannelType.parseString(string: String(modeTargetPrefix)) == nil
                ? Connection.serverChannel
                : modeTarget
            
            output.dispatch(.network(
                                .messageReceived(
                                    connection: target,
                                    channelName: channelName,
                                    message: ChannelMessage(
                                        text: text,
                                        variant: .modeEvent))))
            
            // if the target is a channel, and the mode affects one or more users, we need to determine what that
            // impact is
            if let channel = target.channels.first(where: { $0.name == channelName && $0.descriptor == .multiUser }) {
                updateChannelMode(channel: channel, modeString: modeString, modeArgs: modeArgs)
            }
            
        case .channelModeReceived(let connection, let channelName, let modeString, let modeArgs):
            let state = getState()
            guard let target = state.network.connections.first(where: { $0 === connection }),
                  let channel = target.channels.first(where: { $0.name == channelName }) else { break }
            
            var text = "Channel mode is \(modeString)"
            if !modeArgs.isEmpty {
                text = "\(text) (\(modeArgs.joined(separator: ", ")))"
            }
            
            // dispatch a message to the channel
            output.dispatch(.network(
                                .messageReceived(
                                    connection: target,
                                    channelName: channelName,
                                    message: ChannelMessage(
                                        text: text,
                                        variant: .modeEvent))))
            
            // update the mode on the channel
            updateChannelMode(channel: channel, modeString: modeString, modeArgs: modeArgs)
        
        case .setChannelTopic(let connection, let channelName, let topic):
            let state = getState()
            guard let target = state.network.connections.first(where: { $0 === connection }) else { break }
            
            target.client.sendMessage("TOPIC \(channelName) :\(topic)")
        
        case .setChannelMode(let connection, let channelName, let mode):
            let state = getState()
            guard let target = state.network.connections.first(where: { $0 === connection }) else { break }
            
            target.client.sendMessage("MODE \(channelName) \(mode)")
        
        case .setUserMode(let connection, let channelName, let nick, let mode):
            let state = getState()
            guard let target = state.network.connections.first(where: { $0 === connection }) else { break }
            
            target.client.sendMessage("MODE \(channelName) \(mode) \(nick)")
            
        case .privateMessageReceived(let connection, let identifier, let recipient, let message):
            let state = getState()
            guard let target = state.network.connections.first(where: { $0 === connection }) else { break }
            
            // is the recipient a channel? if so, add the message to the channel
            // otherwise, if this is a private message, add the message to the private message channel instead
            if IRCChannel.ChannelType(rawValue: recipient.first!) != nil,
               let channel = target.channels.first(where: { $0.name == recipient }) {
                
                dispatchChannelMessage(
                    connection: connection,
                    channelName: channel.name,
                    message: message)
                
            } else if recipient == target.identifier?.subject || recipient == "*" {
                var targetChannelName = identifier.subject
                
                // is the message from the server itself?
                if identifier.subject == target.hostname {
                    targetChannelName = Connection.serverChannel
                } else if !target.channels.contains(where: { $0.name == identifier.subject }) {
                    // this our first message from this user; add a channel for the private message
                    output.dispatch(.network(
                                        .clientJoinedChannel(
                                            connection: target,
                                            channelName: identifier.subject,
                                            descriptor: .user)))
                }
                
                dispatchChannelMessage(connection: target,
                                       channelName: targetChannelName,
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
            
        case .userAwayReceived(let connection, let nick, let message):
            let state = getState()
            guard let target = state.network.connections.first(where: { $0 === connection }) else { break }
            
            // do we have a private message channel open with this user? send a message to that channel
            // otherwise open the channel and send the message to the server channel
            if !target.channels.contains(where: { $0.name == nick && $0.descriptor == .user }) {
                output.dispatch(.network(
                                    .clientJoinedChannel(
                                        connection: target,
                                        channelName: nick,
                                        descriptor: .user)))
            }
            
            dispatchChannelMessage(
                connection: target,
                channelName: nick,
                message: message)
        
        case .kickReceived(let connection, let identifier, let channelName, let nick, let reason):
            let state = getState()
            guard let target = state.network.connections.first(where: { $0 === connection }),
                  let channel = target.channels.first(where: { $0.name == channelName }) else { break }
            
            // dispatch a message to the channel
            var message = "\(identifier.subject) has kicked \(nick)"
            if let reason = reason {
                message = "\(message) (\(reason))"
            }
            
            dispatchChannelMessage(
                connection: target,
                channelName: channelName,
                message: ChannelMessage(
                    text: message,
                    variant: .kick))
            
            // if this kick was for us, then we need to also part the channel
            // otherwise, remove the kickd user from the user list in said channel
            if nick == target.identifier?.subject {
                output.dispatch(.network(
                                    .clientLeftChannel(
                                        connection: target,
                                        channelName: channelName)))
            } else if let user = channel.users.first(where: { $0.nick == nick }) {
                output.dispatch(.network(
                                    .userLeftChannel(
                                        conn: target,
                                        channelName: channelName,
                                        user: user)))
            }
        
        case .kickUserFromChannel(let connection, let channelName, let nick, let reason):
            let state = getState()
            guard let target = state.network.connections.first(where: { $0 === connection }) else { break }
            
            var message = "KICK \(channelName) \(nick)"
            if let reason = reason, !reason.isEmptyOrWhitespace {
                message = "\(message) :\(reason)"
            }
            
            target.client.sendMessage(message)
            
        case .userQuit(let connection, let identifier, let reason):
            let state = getState()
            guard let target = state.network.connections.first(where: { $0 === connection }) else { break }
            
            var message = "\(identifier.subject) (\(identifier.user!)@\(identifier.host!)) has disconnected"
            if !reason.isEmpty {
                message = "\(message) (\(reason))"
            }
            
            // find all channels where this user is present
            target.channels.forEach { channel in
                if let user = channel.users.first(where: { $0.nick == identifier.subject }) {
                    // remove the user from the channel
                    output.dispatch(.network(
                                        .userLeftChannel(
                                            conn: target,
                                            channelName: channel.name,
                                            user: user)))
                    
                    // dispatch a message indicating the user left the network
                    dispatchChannelMessage(
                        connection: target,
                        channelName: channel.name,
                        message: ChannelMessage(
                            text: message,
                            variant: .userQuit))
                }
            }
            
        default:
            break
        }
    }
    
    private func joinChannelsAfterConnect(_ result: Result<Connection.State, Error>, connection: Connection, channelNames: [String]) {
        // once connected, automatically join the given set of channels
        switch result {
        case .success(let state):
            if state == .connected {
                channelNames.forEach { channelName in
                    connection.client.sendMessage("JOIN \(channelName)")
                }
            }
        default:
            break
        }
    }
    
    private func updateServerConnectionStatus(connection: Connection, result: Result<Connection.State, Error>) {
        let serverInfo = connection.client.server
        
        switch result {
        case .success(let state):
            switch state {
            case .connecting:
                // push a status message to indicate we're connecting
                self.output.dispatch(.network(
                                        .messageReceived(
                                            connection: connection,
                                            channelName: Connection.serverChannel,
                                            message: ChannelMessage(
                                                text: "Connecting to \(serverInfo.host):\(serverInfo.port)...",
                                                variant: .client))))
                
            case .connected:
                // ensure that the server channel is "joined" once we connect
                self.output.dispatch(.network(
                                        .channelStateChanged(
                                            connection: connection,
                                            channelName: Connection.serverChannel,
                                            channelState: .joined)))
                
            case .disconnected:
                // ensure that all active channels are no longer in joined status upon disconnecting
                connection.channels
                    .filter { $0.state == .joined && ($0.descriptor == .multiUser || $0.descriptor == .server) }
                    .forEach { channel in
                        self.output.dispatch(.network(
                                                .channelStateChanged(
                                                    connection: connection,
                                                    channelName: channel.name,
                                                    channelState: .parted)))
                    }
            }
            
            // propagate the connection state change down the pipeline
            self.output.dispatch(.network(
                                    .connectionStateChanged(
                                        connection: connection,
                                        connectionState: state)))
            
        case .failure(let error):
            self.output.dispatch(.network(
                                    .messageReceived(
                                        connection: connection,
                                        channelName: Connection.serverChannel,
                                        message: ChannelMessage(
                                            text: "Failed to connect to \(serverInfo.host):\(serverInfo.port): \(error.localizedDescription)",
                                            variant: .error))))
            
            // reset the status to disconnected since we could not establish a valid connection
            output.dispatch(.network(
                                .connectionStateChanged(
                                    connection: connection,
                                    connectionState: .disconnected)))
            
        }
    }
    
    private func updateChannelMode(channel: IRCChannel, modeString: String, modeArgs: [String]) {
        // parse the mode string and apply the deltas to the current channel mode
        let modeChange = ChannelModeChange(from: modeString, modeArgs: modeArgs)
        let newMode = channel.mode.apply(modeChange)
        
        // update the current channel mode
        output.dispatch(.network(
                            .channelModeChanged(
                                connection: channel.connection,
                                channelName: channel.name,
                                mode: newMode)))
        
        // update modes added for users
        modeChange.privilegesAdded.forEach { privilege, nicks in
            nicks.forEach { nick in
                output.dispatch(.network(
                                    .userChannelModeAdded(
                                        connection: channel.connection,
                                        channelName: channel.name,
                                        nick: nick,
                                        privilege: privilege)))
            }
        }
        
        // update modes removed from users
        modeChange.privilegesRemoved.forEach { privilege, nicks in
            nicks.forEach { nick in
                output.dispatch(.network(
                                    .userChannelModeRemoved(
                                        connection: channel.connection,
                                        channelName: channel.name,
                                        nick: nick,
                                        privilege: privilege)))
            }
        }
    }
    
    private func dispatchChannelMessage(connection: Connection, channelName: String, message: ChannelMessage) {
        let state = getState()
        
        output.dispatch(.network(
                            .messageReceived(
                                connection: connection,
                                channelName: channelName,
                                message: message)))
        
        let channel = connection.channels.first(where: { $0.name == channelName })
        
        // if this channel is not currently active, mark this message as new
        if channel != state.ui.currentChannel {
            // did we get mentioned? see if our nick appears anywhere in the message
            if let nick = connection.identifier?.subject,
               message.text.range(of: "\\s?(\(nick))\\s?", options: .regularExpression, range: nil, locale: nil) != nil {
                
                output.dispatch(.network(
                                    .addChannelNotification(
                                        connection: connection,
                                        channelName: channelName,
                                        notification: .mention)))
                
            } else {
                output.dispatch(.network(
                                    .addChannelNotification(
                                        connection: connection,
                                        channelName: channelName,
                                        notification: .newMessages)))
            }
        }
    }
}
