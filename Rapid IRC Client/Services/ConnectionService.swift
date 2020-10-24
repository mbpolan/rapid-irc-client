//
//  ConnectionManager.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/24/20.
//

import Foundation
import SwiftSocket

protocol ConnectionService {
    
    func addConnection()
}

struct Connection {
    var host: String
    var port: Int
    var client: TCPClient
}

struct DefaultConnectionService: ConnectionService {
    
    private var connections = [Connection]()
    
    func addConnection() {
        
    }
}

struct StubConnectionService: ConnectionService {
    
    func addConnection() {
    }
}
