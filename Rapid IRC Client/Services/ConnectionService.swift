//
//  ConnectionManager.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/24/20.
//

import SwiftUI
import SwiftSocket

protocol ConnectionService {

    func addConnection(info: ServerInfo)
}

struct DefaultConnectionService: ConnectionService {

    private let store: ConnectionsStore
    
    init(store: ConnectionsStore) {
        self.store = store
    }

    func addConnection(info: ServerInfo) {
        let client = TCPClient(address: info.server, port: info.port)
        
        switch client.connect(timeout: 3000) {
        case .success:
            print("success")
        case .failure(let error):
            print(error)
        }

        store.connections.append(ServerConnection(info: info, client: client))
    }
}

struct StubConnectionService: ConnectionService {

    func addConnection(info: ServerInfo) {
    }
}
