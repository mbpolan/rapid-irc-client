//
//  SnapshotAction.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 2/1/21.
//

import Foundation

// MARK: - Actions
// sourcery: Prism
enum SnapshotAction {
    case save(completion: () -> Void)
    case restore
    
    case push(timestamp: Date, connectionsToChannels: Dictionary<UUID, [String]>)
    case pop
}
