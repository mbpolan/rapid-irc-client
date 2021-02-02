//
//  SnapshotReducer.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 2/1/21.
//

import Foundation
import SwiftRex

let snapshotReducer = Reducer<SnapshotAction, SnapshotState> { action, state in
    switch action {
    case .push(let timestamp, let connectionsToChannels):
        return SnapshotState(
            timestamp: timestamp,
            connectionsToChannels: connectionsToChannels)
        
    case .pop:
        return .empty
        
    default:
        return state
    }
}
