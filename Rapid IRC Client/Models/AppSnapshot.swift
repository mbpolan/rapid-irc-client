//
//  AppSnapshot.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 2/1/21.
//

import Foundation

struct AppSnapshot {
    
    let timestamp: Date
    let connections: [ConnectionSnapshot]
    
    init(from store: Store) {
        var connections: [ConnectionSnapshot] = []
        
        _ = store.mapState { state in
            state.network.connections.forEach { connection in
                connections.append(
                    ConnectionSnapshot(
                        connection: connection,
                        joinedChannelNames: connection.channels
                            .filter { $0.state == .joined }
                            .map { $0.name }))
            }
        }
        
        self.timestamp = Date()
        self.connections = connections
    }
}

extension AppSnapshot {
    
    struct ConnectionSnapshot {
        
        let connection: Connection
        let joinedChannelNames: [String]
    }
}
