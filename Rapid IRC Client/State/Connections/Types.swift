//
//  Types.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/28/20.
//

import SwiftUI

class Connection: Identifiable {
    
    static let serverChannel = "_"
    
    var name: String
    var client: ServerConnection
    var channels: [IRCChannel] = []
    
    init(name: String, client: ServerConnection) {
        self.name = name
        self.client = client
        addChannel(name: Connection.serverChannel)
    }
    
    func addChannel(name: String) {
        // avoid adding a channel with the same name. if it does exist, set it as joined.
        let channel = channels.first { $0.name == name }
        if channel == nil {
            channels.append(IRCChannel(name: name, state: .joined))
        } else if channel!.state != .joined {
            channel!.state = .joined
        }
    }
    
    func leaveChannel(channel: String) {
        channels.first { $0.name == channel }?.state = .parted
    }
    
    func addServerMessage(_ message: String) {
        addMessage(channel: Connection.serverChannel, message: message)
    }
    
    func addMessage(channel: String, message: String) {
        var ircChannel = channels.first { $0.name == channel }
        if (ircChannel == nil) {
            ircChannel = IRCChannel(name: channel, state: .joined)
            channels.append(ircChannel!)
        }
        
        ircChannel!.messages.append(message)
    }
}

class IRCChannel {
    
    var name: String
    var state: State
    var messages: [String] = []
    
    init(name: String, state: State) {
        self.name = name
        self.state = state
    }
}

extension IRCChannel {
    enum State {
        case joined
        case parted
    }
}
