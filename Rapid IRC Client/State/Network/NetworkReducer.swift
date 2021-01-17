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
        
    case .messageReceived(let connection, let channelName, let message):
        let newState = state
        if let target = newState.connections.first(where: { $0 === connection }),
           let channel = target.channels.first(where: { $0.name == channelName }) {
            channel.messages.append(message)
        }
        
        return newState
        
    case .channelTopic(let connection, let channelName, let topic):
        let newState = state
        if let target = newState.connections.first(where: { $0 === connection }),
           let channel = target.channels.first(where: { $0.name == channelName }) {
            channel.topic = topic
        }
        
        return newState
        
    case .updateChannelUsers(let connection, let channelName, let users):
        let newState = state
        if let target = newState.connections.first(where: { $0 === connection }),
           var channel = target.channels.first(where: { $0.name == channelName }) {
            channel.users = Set(users)
        }
        
        return newState
        
    case .channelStateChanged(let connection, let channelName, let channelState):
        let newState = state
        if let target = newState.connections.first(where: { $0 === connection }),
           var channel = target.channels.first(where: { $0.name == channelName}) {
            channel.state = channelState
        }
        
        return newState
        
    case .userJoinedChannel(let connection, let channelName, let user):
        var newState = state
        if let target = newState.connections.first(where: { $0 === connection }),
           var channel = target.channels.first(where: { $0.name == channelName}) {
            channel.users.insert(user)
        }
        
        return newState
    
    case .clientJoinedChannel(let connection, let channelName):
        var newState = state
        if let target = newState.connections.first(where: { $0 === connection }) {
            let channel = IRCChannel(
                connection: connection,
                name: channelName,
                state: .joined)
            
            connection.channels.append(channel)
            newState.channelUuids[channel.id] = channel
        }
        
        return newState
        
    case .clientLeftChannel(let connection, let channelName):
        let newState = state
        if let target = newState.connections.first(where: { $0 === connection }),
           let channel = target.channels.first(where: { $0.name == channelName }) {
            
            channel.state = .parted
            channel.users.removeAll()
        }
        
        return newState
    
    case .userLeftChannel(let connection, let channelName, let user):
        let newState = state
        if let target = newState.connections.first(where: { $0 === connection }),
           let channel = target.channels.first(where: { $0.name == channelName }) {
            channel.users.remove(user)
        }
        
        return newState
        
    case .removeChannel(let connection, let channelName):
        let newState = state
        if let target = newState.connections.first(where: { $0 === connection }) {
            target.channels = target.channels.filter { $0.name != channelName }
        }
        
        return newState
        
    case .addChannelNotification(let connection, let channelName, let notification):
        let newState = state
        if let target = newState.connections.first(where: { $0 === connection }),
           let channel = target.channels.first(where: { $0.name == channelName }) {
            
            channel.notifications.insert(notification)
        }
        
        return newState
        
    default:
        return state
    }
}
