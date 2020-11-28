//
//  Reducer.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/28/20.
//

struct ConnectionsState {
    var connections: [Connection] = []
    var current = -1
}

func connectionsReducer(state: AppState, action: ActionWrapper) -> AppState {
    var newState = state

    switch action.action {
    case let act as ConnectAction:
        let connection = Connection(
            name: act.server.host,
            client: ServerConnection(server: act.server, store: action.store))
        
        connection.client.connect()

        newState.connections.connections.append(connection)
        newState.connections.current = newState.connections.connections.count - 1
    
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
        let connection = newState.connections.connections[newState.connections.current]
        
        let message = act.message.starts(with: "/") ? act.message.subString(from: 1) : act.message
        connection.client.sendMessage(message)
        
    case let act as JoinedChannelAction:
        let connection = newState.connections.connections.first { conn in
            conn.client === act.connection
        }
        
        connection?.addChannel(name: act.channel)
        
    case let act as PartChannelAction:
        let connection = newState.connections.connections.first { conn in
            conn.client === act.connection
        }
        
        // TODO
        
    default:
        break
    }

    return newState
}

