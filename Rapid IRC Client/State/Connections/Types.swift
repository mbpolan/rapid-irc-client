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
    }
    
    func addChannel(name: String) -> IRCChannel {
        // avoid adding a channel with the same name. if it does exist, set it as joined.
        var channel = channels.first { $0.name == name }
        if channel == nil {
            channel = IRCChannel(connection: self, name: name, state: .joined)
            channels.append(channel!)
        } else if channel!.state != .joined {
            channel!.state = .joined
        }
        
        return channel!
    }
    
    func getServerChannel() -> IRCChannel? {
        return channels.first { $0.name == Connection.serverChannel }
    }
    
    func leaveChannel(channel: String) {
        let channel = channels.first { $0.name == channel }
        if channel != nil {
            channel!.state = .parted
            channel!.users.removeAll()
        }
    }
    
    func addServerMessage(_ message: String) {
        addMessage(channel: Connection.serverChannel, message: message)
    }
    
    func addMessage(channel: String, message: String) {
        var ircChannel = channels.first { $0.name == channel }
        if (ircChannel == nil) {
            ircChannel = IRCChannel(connection: self, name: channel, state: .joined)
            channels.append(ircChannel!)
        }
        
        ircChannel!.messages.append(message)
    }
}

class IRCChannel: Identifiable {
    
    var id: String = UUID().uuidString
    var connection: Connection
    var topic: String?
    var name: String
    var state: State
    var access: AccessType?
    var messages: [String] = []
    var users: [User] = []
    
    init(connection: Connection, name: String, state: State) {
        self.connection = connection
        self.name = name
        self.state = state
    }
}

extension IRCChannel {
    enum State {
        case joined
        case parted
    }
    
    enum AccessType: String {
        case secretAccess = "@"
        case privateAccess = "*"
        case publicAccess = "="
    }
}

class User: Identifiable {
    var id: String {
        return name
    }
    
    var name: String
    var privilege: ChannelPrivilege?
    
    init(name: String, privilege: ChannelPrivilege?) {
        self.name = name
        self.privilege = privilege
    }
}

extension User {
    enum ChannelPrivilege: Character {
        case owner = "~"
        case admin = "&"
        case fullOperator = "@"
        case halfOperator = "%"
        case voiced = "+"
    }
}

extension User.ChannelPrivilege {
    func ordinal() -> Int {
        switch self {
        case .owner:
            return 5
        case .admin:
            return 4
        case .fullOperator:
            return 3
        case.halfOperator:
            return 2
        case .voiced:
            return 1
        }
    }
}
