//
//  Types.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/28/20.
//

import SwiftUI

class Connection {
    
    var name: String
    var client: ServerConnection
    var messages: [String] = []
    
    init(name: String, client: ServerConnection) {
        self.name = name
        self.client = client
    }
    
    func addMessage(_ message: String) {
        messages.append(message)
    }
}
