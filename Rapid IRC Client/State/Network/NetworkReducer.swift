//
//  NetworkReducer.swift
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
        
    case .connectionStateChanged(let connection, let connectionState):
        let newState = state
        if let target = newState.connections.first(where: { $0 === connection }) {
            // if a connection is no longer active, then all of its channels are also parted
            if connectionState == .disconnected {
                target.channels = target.channels.map { channel in
                    channel.state = .parted
                    return channel
                }
            }
            
            target.state = connectionState
        }
        
        return newState
        
    case .welcomeReceived(let connection, let identifier):
        let newState = state
        if let target = newState.connections.first(where: { $0 === connection }) {
            target.identifier = IRCMessage.Prefix.parse(identifier)
        }
        
        return state
        
    case .messageReceived(let channel, let message):
        let newState = state
        newState.channelUuids[channel.id]?.messages.append(message)
        return newState
        
    case .channelTopic(let connection, let channelName, let topic):
        let newState = state
        if let target = newState.connections.first(where: { $0 === connection }),
           let channel = target.channels.first(where: { $0.name == channelName }) {
            channel.topic = topic
        }
        
        return newState
        
    case .usersInChannel(let connection, let channelName, let users):
        let newState = state
        if let target = newState.connections.first(where: { $0 === connection }),
           let channel = target.channels.first(where: { $0.name == channelName }) {
            channel.users = Set(users)
        }
        
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
                var message = "\(identifier) has left \(channelName)"
                if let reasonText = reason {
                    message = "\(message) (\(reasonText))"
                }
                
                channel.messages.append(ChannelMessage(
                                            text: message,
                                            variant: .userParted))
            }
            
            // does this message refer to us? if so, part the channel from our perspective.
            // if another user has left, remove them from the user list.
            if identifier == target.identifier?.raw {
                target.leaveChannel(channel: channelName)
            } else if let targetUser = channel.users.first(where: { $0.name == nick }) {
                channel.users.remove(targetUser)
            }
        }
        
        return newState
        
    case .privateMessageReceived(let connection, let identifier, let nick, let recipient, let message):
        let newState = state
        // FIXME: recipient can also be another user
        if let target = newState.connections.first(where: { $0 === connection }),
           let channel = target.channels.first(where: { $0.name == recipient }) {
            
            channel.messages.append(message)
        }
        
        return state
        
    case .errorReceived(let connection, let message):
        let newState = state
        if let target = newState.connections.first(where: { $0 === connection }),
           let channel = target.channels.first(where: { $0.name == Connection.serverChannel }) {
            
            channel.messages.append(message)
        }
        
        return newState
        
    default:
        return state
    }
}
