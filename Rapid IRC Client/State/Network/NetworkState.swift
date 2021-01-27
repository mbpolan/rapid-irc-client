//
//  NetworkState.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 1/10/21.
//

import Foundation

// MARK: - State
struct NetworkState {
    var connections: [Connection] = []
    var channelUuids: [UUID: IRCChannel] = [:]
}
