//
//  Types.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/28/20.
//

import SwiftUI

class Connection: Identifiable {
    
    static let serverChannel = "_"
    
    let id = UUID()
    var name: String
    var hostname: String?
    var state: State
    var identifier: IRCMessage.Prefix?
    var client: ServerConnection
    var channels: [IRCChannel] = []
    var pendingChannels: [String] = []
    
    init(name: String, serverInfo: ServerInfo, store: Store) {
        self.name = name
        self.state = .disconnected
        self.client = ServerConnection(server: serverInfo, store: store)
        self.client.withConnection(self)
    }
    
    func getServerChannel() -> IRCChannel? {
        return channels.first { $0.descriptor == .server }
    }
}

extension Connection {
    enum State {
        case connected
        case connecting
        case disconnected
    }
}

struct ChannelMessage {
    
    var timestamp: Date = Date()
    var sender: String?
    var text: String
    var variant: Variant
}

extension ChannelMessage {
    enum Variant {
        case action
        case privateMessage
        case notice
        case userJoined
        case userParted
        case userQuit
        case channelTopicEvent
        case modeEvent
        case error
        case client
        case other
    }
}

class IRCChannel: Identifiable, Equatable {
    
    let id = UUID()
    var connection: Connection
    var topic: String?
    var topicSetBy: String?
    var topicSetOn: Date?
    var name: String
    var descriptor: Descriptor
    var type: ChannelType?
    var state: State
    var notifications: Set<Notification> = Set()
    var access: AccessType?
    var messages: [ChannelMessage] = []
    var lastUserListUpdate: Date
    var incomingUsers: Set<User> = []
    var users: Set<User> = []
    
    static func == (lhs: IRCChannel, rhs: IRCChannel) -> Bool {
        return lhs.id == rhs.id
    }
    
    init(connection: Connection, name: String, descriptor: Descriptor, state: State) {
        self.connection = connection
        self.name = name
        self.descriptor = descriptor
        self.type = ChannelType.parseString(string: name)
        self.lastUserListUpdate = Date()
        self.state = state
    }
}

extension IRCChannel {
    
    enum UserListState {
        case receiving
        case received
    }
    
    enum State {
        case joined
        case parted
    }
    
    enum Notification: Int {
        case mention = 0
        case newMessages = 1
    }
    
    enum Descriptor {
        case server
        case multiUser
        case user
    }
    
    enum ChannelType: Character {
        case local = "&"
        case network = "#"
        case safe = "!"
        case unmoderated = "+"
        case soft = "."
        case global = "~"
        
        static func parseString(string: String) -> ChannelType? {
            guard let first = string.first else { return nil }
            return ChannelType.init(rawValue: first)
        }
    }
    
    enum AccessType: String {
        case secretAccess = "@"
        case privateAccess = "*"
        case publicAccess = "="
    }
}

class User: Identifiable, Hashable {
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.name == rhs.name && lhs.privilege == rhs.privilege
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self).hashValue)
    }
    
    var id: String {
        return name
    }
    
    var name: String
    var privilege: ChannelPrivilege?
    
    init(name: String, privilege: ChannelPrivilege?) {
        self.name = name
        self.privilege = privilege
    }
    
    init(from identifier: IRCMessage.Prefix) {
        self.name = identifier.subject
        
        let subject = identifier.subject
        if let privilege = ChannelPrivilege.init(rawValue: subject.first!) {
            self.privilege = privilege
        } else {
            self.privilege = .none
        }
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
