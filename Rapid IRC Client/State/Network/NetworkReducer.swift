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
        
    case .hostnameReceived(let connection, let hostname):
        let newState = state
        if let target = newState.connections.first(where: { $0 === connection }) {
            target.hostname = hostname
        }
        
        return state
        
    case .messageReceived(let connection, let channelName, let message):
        let newState = state
        if let target = newState.connections.first(where: { $0 === connection }),
           let channel = target.channels.first(where: { $0.name == channelName }) {
            channel.messages.append(message)
        }
        
        return newState
        
    case .updateChannelTopic(let connection, let channelName, let topic):
        let newState = state
        if let target = newState.connections.first(where: { $0 === connection }),
           let channel = target.channels.first(where: { $0.name == channelName }) {
            channel.topic = topic
        }
        
        return newState
        
    case .updateChannelTopicMetadata(let connection, let channelName, let who, let when):
        let newState = state
        if let target = newState.connections.first(where: { $0 === connection }),
           let channel = target.channels.first(where: { $0.name == channelName }) {
            channel.topicSetBy = who
            channel.topicSetOn = when
        }
        
        return newState
        
    case .applyIncomingChannelUsers(let connection, let channelName):
        let newState = state
        if let target = newState.connections.first(where: { $0 === connection }),
           var channel = target.channels.first(where: { $0.name == channelName }) {
            channel.users = channel.incomingUsers
            channel.lastUserListUpdate = Date()
        }
        
        return newState
        
    case .addIncomingChannelUsers(let connection, let channelName, let users):
        let newState = state
        if let target = newState.connections.first(where: { $0 === connection }),
           var channel = target.channels.first(where: { $0.name == channelName }) {
            channel.incomingUsers.formUnion(users)
        }
        
        return newState
        
    case .clearIncomingChannelUsers(let connection, let channelName):
        let newState = state
        if let target = newState.connections.first(where: { $0 === connection }),
           var channel = target.channels.first(where: { $0.name == channelName }) {
            channel.incomingUsers = Set()
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
            channel.lastUserListUpdate = Date()
        }
        
        return newState
    
    case .clientJoinedChannel(let connection, let channelName, let descriptor):
        var newState = state
        if let target = newState.connections.first(where: { $0 === connection }) {
            if target.channels.contains(where: { $0.name == channelName }) {
                print("WARN: already have channel with name \(channelName)")
                return state
            }
            
            let channel = IRCChannel(
                connection: connection,
                name: channelName,
                descriptor: descriptor,
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
            channel.lastUserListUpdate = Date()
        }
        
        return newState
    
    case .userLeftChannel(let connection, let channelName, let user):
        let newState = state
        if let target = newState.connections.first(where: { $0 === connection }),
           let channel = target.channels.first(where: { $0.name == channelName }) {
            channel.users.remove(user)
            channel.lastUserListUpdate = Date()
        }
        
        return newState
    
    case .removeConnection(let connection):
        var newState = state
        if let target = newState.connections.first(where: { $0 === connection }) {
            newState.channelUuids = state.channelUuids.filter { $0.value.connection !== connection }
            newState.connections = state.connections.filter { $0 !== connection }
        }
        
        return newState
        
    case .removeChannel(let connection, let channelName):
        let newState = state
        if let target = newState.connections.first(where: { $0 === connection }) {
            target.channels = target.channels.filter { $0.name != channelName }
        }
        
        return newState
        
    case .renameChannel(let connection, let oldChannelName, let newChannelName):
        let newState = state
        if let target = newState.connections.first(where: { $0 === connection }),
           var channel = target.channels.first(where: { $0.name == oldChannelName }) {
            
            channel.name = newChannelName
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
