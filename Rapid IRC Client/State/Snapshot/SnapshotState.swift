//
//  SnapshotState.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 2/1/21.
//

import Foundation

struct SnapshotState {
    var timestamp: Date
    var connectionsToChannels: [UUID: [String]]
    
    static var empty: SnapshotState {
        .init(
            timestamp: Date(),
            connectionsToChannels: [:])
    }
}
