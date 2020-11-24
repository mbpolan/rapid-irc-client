//
//  Types.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/28/20.
//

import SwiftUI

class Connection {
    
    static let serverChannel = "Server"
    
    var name: String
    var client: ServerConnection
    var channels: [IRCChannel] = []
    
    init(name: String, client: ServerConnection) {
        self.name = name
        self.client = client
    }
    
    func addChannel(name: String) {
        self.channels.append(IRCChannel(name: name))
    }
    
    func addServerMessage(_ message: String) {
        addMessage(channel: Connection.serverChannel, message: message)
    }
    
    func addMessage(channel: String, message: String) {
        var ircChannel = channels.first { $0.name == channel }
        if (ircChannel == nil) {
            ircChannel = IRCChannel(name: channel)
            channels.append(ircChannel!)
        }
        
        ircChannel!.messages.append(message)
    }
}

class IRCChannel {
    
    var name: String
    var messages: [String] = []
    
    init(name: String) {
        self.name = name
    }
}
