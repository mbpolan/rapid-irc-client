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
            print("added: \(act.message)")
            connection!.addMessage(act.message)
        } else {
            print("**ERROR**")
        }
    
    case let act as MessageSentAction:
        let connection = newState.connections.connections[newState.connections.current]
        connection.client.sendMessage(act.message)
        
    default:
        break
    }

    return newState
}

