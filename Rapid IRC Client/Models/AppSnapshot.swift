//
//  AppSnapshot.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 2/1/21.
//

import Foundation

/// A snapshot of the application at a particular point in time.
///
/// The snapshot includes the list of connections to IRC servers, and the channels that are
/// open (whether joined or not) in the current session.
struct AppSnapshot {
    
    let timestamp: Date
    let connections: [ConnectionSnapshot]
    
    /// Initializes a snapshot based on the current store.
    ///
    /// - Parameter store: The store instance.
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

// MARK: - AppSnapshot structs
extension AppSnapshot {
    
    /// A snapshot of a single IRC connection.
    struct ConnectionSnapshot {
        let connection: Connection
        let joinedChannelNames: [String]
    }
}
