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
        case userAway
        case userQuit
        case channelTopicEvent
        case modeEvent
        case error
        case kick
        case userInvited
        case client
        case other
        case motd
    }
}

class IRCChannel: Identifiable, Equatable {
    
    let id = UUID()
    var connection: Connection
    var mode: ChannelMode = .default
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
        return lhs.nick == rhs.nick && lhs.privileges == rhs.privileges
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self).hashValue)
    }
    
    var id: String {
        return nick
    }
    
    var nick: String
    var privileges: [ChannelPrivilege]
    
    init(from nick: String) {
        self.privileges = []
        
        // parse all known privilege characters from the nick
        var privilegeString = nick
        while let code = privilegeString.first,
              let privilege = ChannelPrivilege.init(rawValue: code) {
            
            self.privileges.append(privilege)
            privilegeString = String(privilegeString.dropFirst())
        }
        
        // the remaining characters are the actual nick
        self.nick = privilegeString
    }
    
    convenience init(from identifier: IRCMessage.Prefix) {
        self.init(from: identifier.subject)
    }
    
    func highestPrivilege() -> ChannelPrivilege? {
        // swiftlint:disable identifier_name
        return privileges.max(by: { (a, b) -> Bool in
            return a.ordinal < b.ordinal
        })
    }
}

extension User {
    enum ChannelPrivilege: Character {
        case founder = "~"
        case protected = "&"
        case fullOperator = "@"
        case halfOperator = "%"
        case voiced = "+"
        
        var modeString: String {
            switch self {
            case .founder:
                return "q"
            case .protected:
                return "a"
            case .fullOperator:
                return "o"
            case .halfOperator:
                return "h"
            case .voiced:
                return "v"
            }
        }
        
        var given: String {
            return "+\(self.modeString)"
        }
        
        var taken: String {
            return "-\(self.modeString)"
        }
    }
}

extension User.ChannelPrivilege {
    var ordinal: Int {
        switch self {
        case .founder:
            return 5
        case .protected:
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
