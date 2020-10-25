//
//  ConnectionsState.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/24/20.
//

import Combine

final class ConnectionsStore: ObservableObject {
    
    @Published var connections: [ServerConnection] = []
}
