//
//  Reducer.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/28/20.
//

import CombineRex
import SwiftRex

let networkReducer = Reducer<NetworkAction, NetworkState> { (action: NetworkAction, state: NetworkState) in
    switch action {
    case .connectionAdded(let connection, let serverChannel):
        // add the server channel to the channel map
        var channelUuids = state.channelUuids
        channelUuids[serverChannel.id] = serverChannel
        
        return NetworkState(
            connections: state.connections + [connection],
            channelUuids: channelUuids)
        
    case .welcomeReceived(let connection, let identifier):
        let newState = state
        if let target = newState.connections.first(where: { $0 === connection }) {
            target.identifier = identifier
        }
        
        return state
        
    case .messageReceived(let channel, let message):
        let newState = state
        newState.channelUuids[channel.id]?.messages.append(message)
        return newState
        
    case .joinedChannel(let connection, let channelName, let identifier, let nick):
        var newState = state
        if let target = newState.connections.first(where: { $0 === connection }) {
            let channel = target.addChannel(name: channelName)
            newState.channelUuids[channel.id] = channel
            
            
            channel.messages.append(ChannelMessage(
                                        text: "\(identifier) has joined \(channelName)",
                                        variant: .userJoined))
            
            channel.users.insert(User(
                                    name: nick,
                                    privilege: nil))
        }
        
        return newState
        
    case .partedChannel(let connection, let channelName, let identifier, let nick, let reason):
        var newState = state
        if let target = newState.connections.first(where: { $0 === connection }),
           let channel = target.channels.first(where: { $0.name == channelName }) {
            
            // append the parting reason, if one was given
            if reason != nil {
                channel.messages.append(ChannelMessage(
                                            text: "\(identifier) has left \(channelName)",
                                            variant: .userParted))
            }
            
            // does this message refer to us? if so, part the channel from our perspective.
            // if another user has left, remove them from the user list.
            if identifier == target.identifier {
                target.leaveChannel(channel: channelName)
            } else if let targetUser = channel.users.first(where: { $0.name == nick }) {
                channel.users.remove(targetUser)
            }
        }
        
        return newState
        
    default:
        return state
    }
}

//
//func connectionsReducer(state: AppState, action: ActionWrapper) -> AppState {
//    var newState = state
//
//    switch action.action {
//    case let act as ConnectAction:
//        let connection = Connection(
//            name: act.server.host,
//            client: ServerConnection(server: act.server, store: action.store))
//        
//        let serverChannel = connection.addChannel(name: Connection.serverChannel)
//        newState.connections.channelUuids[serverChannel.id] = serverChannel
//        newState.ui.currentChannel = serverChannel.id
//        
//        connection.client.connect()
//
//        newState.connections.connections.append(connection)
//        
//    case let act as WelcomeAction:
//        let connection = newState.connections.connections.first { conn in
//            conn.client === act.connection
//        }
//        
//        connection?.identifier = act.identifier
//    
//    case let act as MessageReceivedAction:
//        let connection = newState.connections.connections.first { conn in
//            conn.client === act.connection
//        }
//        
//        if connection != nil {
//            connection!.addMessage(channel: Connection.serverChannel, message: act.message)
//        } else {
//            print("**ERROR**")
//        }
//        
//    case let act as MessageSentAction:
//        let connection = newState.connections.connections.first { conn in
//            conn.client === act.connection
//        }
//        
//        if connection != nil {
//            let message = act.message.starts(with: "/") ? act.message.subString(from: 1) : act.message
//            act.connection.sendMessage(message)
//        }
//        
//    case let act as JoinedChannelAction:
//        let connection = newState.connections.connections.first { conn in
//            conn.client === act.connection
//        }
//        
//        if connection != nil {
//            let channel = connection!.addChannel(name: act.channel)
//            newState.connections.channelUuids[channel.id] = channel
//            
//            channel.messages.append(ChannelMessage(
//                                        text: "\(act.identifier) has joined \(act.channel)",
//                                        variant: .userJoined))
//            
//            channel.users.insert(User(
//                                    name: act.nick,
//                                    privilege: nil))
//        }
//        
//    case let act as PartChannelAction:
//        let connection = newState.connections.connections.first { conn in
//            conn.client === act.connection
//        }
//        
//        if connection != nil {
//            let channel = connection!.channels.first { $0.name == act.channel }!
//            
//            channel.messages.append(ChannelMessage(
//                                        text: "\(act.identifier) has left \(act.channel)",
//                                        variant: .userParted))
//            
//            // does this message refer to us? if so, part the channel from our perspective.
//            // if another user has left, remove them from the user list.
//            if act.identifier == connection?.identifier {
//                connection!.leaveChannel(channel: act.channel)
//            } else if let targetUser = channel.users.first(where: { $0.name == act.nick }) {
//                channel.users.remove(targetUser)
//            }
//        }
//        
//    case let act as PrivateMessageAction:
//        let connection = newState.connections.connections.first { conn in
//            conn.client === act.connection
//        }
//        
//        if connection != nil {
//            // FIXME: this can also include other users instead of just channels
//            if let channel = connection!.channels.first(where: { $0.name == act.recipient }) {
//                channel.messages.append(act.message)
//            }
//        }
//        
//    case let act as UsersInChannelAction:
//        let connection = newState.connections.connections.first { conn in
//            conn.client === act.connection
//        }
//        
//        connection?.channels.first { $0.name == act.channel }?.users.formUnion(act.users)
//    
//    case let act as ChannelTopicAction:
//        let connection = newState.connections.connections.first { conn in
//            conn.client === act.connection
//        }
//        
//        connection?.channels.first { $0.name == act.channel }?.topic = act.topic
//        
//    default:
//        break
//    }
//
//    return newState
//}

