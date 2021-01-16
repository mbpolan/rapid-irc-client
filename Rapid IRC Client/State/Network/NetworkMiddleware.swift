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
            
            let serverChannel = connection.addChannel(name: Connection.serverChannel)
            
            connection.client.connect()
            
            output.dispatch(.network(.connectionAdded(connection, serverChannel)))
            output.dispatch(.ui(.connectionAdded(connection)))
            
        case .reconnect(let connection):
            // client will dispatch an action to inform when it's connected
            connection.client.connect()
        
        case .disconnect(let connection):
            // client will dispatch an action to inform when it's disconnected
            connection.client.disconnect()
        
        case .prepareJoinChannel(let connection, let channelName, let identifier, let nick):
            output.dispatch(.network(
                                .joinedChannel(
                                    connection,
                                    channelName,
                                    identifier,
                                    nick)))
            
            // set this to be the active chanel
            output.dispatch(.ui(.changeChannel(connection, channelName)))
            
        case .messageSent(let channel, let text):
            var message = text
            
            switch text.lowercased() {
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
                
            // not a command; could be a normal chat message sent in a channel. in this case, convert the plain text
            // message into a /privmsg command
            case _ where !text.starts(with: "/"):
                let state = getState()
                guard let currentChannel = state.ui.currentChannel,
                      let identifier = currentChannel.connection.identifier else { break }
                
                output.dispatch(.network(
                                    .messageReceived(
                                        currentChannel,
                                        ChannelMessage(
                                            sender: identifier.subject,
                                            text: text,
                                            variant: .privateMessage))))
                
                message = "/privmsg \(currentChannel.name) \(text)"
                
            default:
                break
            }
            
            // strip the leading slash if the message contains a command
            message = message.starts(with: "/") ? message.subString(from: 1) : message
            channel.connection.client.sendMessage(message)
        
        default:
            break
        }
    }
    
}
