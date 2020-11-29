//
//  Reducer.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/28/20.
//

struct ConnectionsState {
    var connections: [Connection] = []
    var channelUuids: [String: IRCChannel] = [:]
}

func connectionsReducer(state: AppState, action: ActionWrapper) -> AppState {
    var newState = state

    switch action.action {
    case let act as ConnectAction:
        let connection = Connection(
            name: act.server.host,
            client: ServerConnection(server: act.server, store: action.store))
        
        let serverChannel = connection.addChannel(name: Connection.serverChannel)
        newState.connections.channelUuids[serverChannel.id] = serverChannel
        newState.ui.currentChannel = serverChannel.id
        
        connection.client.connect()

        newState.connections.connections.append(connection)
    
    case let act as MessageReceivedAction:
        let connection = newState.connections.connections.first { conn in
            conn.client === act.connection
        }
        
        if connection != nil {
            connection!.addMessage(channel: Connection.serverChannel, message: act.message)
        } else {
            print("**ERROR**")
        }
        
    case let act as MessageSentAction:
        let message = act.message.starts(with: "/") ? act.message.subString(from: 1) : act.message
        act.connection.sendMessage(message)
        
    case let act as JoinedChannelAction:
        let connection = newState.connections.connections.first { conn in
            conn.client === act.connection
        }
        
        if connection != nil {
            let channel = connection!.addChannel(name: act.channel)
            newState.connections.channelUuids[channel.id] = channel
        }
        
    case let act as PartChannelAction:
        let connection = newState.connections.connections.first { conn in
            conn.client === act.connection
        }
        
        connection?.leaveChannel(channel: act.channel)
        
    case let act as UsersInChannelAction:
        let connection = newState.connections.connections.first { conn in
            conn.client === act.connection
        }
        
        connection?.channels.first { $0.name == act.channel }?.users.append(contentsOf: act.users)
    
    case let act as ChannelTopicAction:
        let connection = newState.connections.connections.first { conn in
            conn.client === act.connection
        }
        
        connection?.channels.first { $0.name == act.channel }?.topic = act.topic
        
    default:
        break
    }

    return newState
}

