//
//  Connection.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/24/20.
//

import SwiftSocket

struct ServerConnection {
    
    let id = UUID()
    var info: ServerInfo
    var client: TCPClient
}
