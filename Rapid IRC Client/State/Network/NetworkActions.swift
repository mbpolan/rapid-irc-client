//
//  Actions.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/28/20.
//

// MARK: - Actions
enum NetworkAction {
    case connect(ServerInfo)
    case messageSent(IRCChannel, String)
    
    case connectionAdded(Connection, IRCChannel)
    case welcomeReceived(Connection, String)
    case messageReceived(IRCChannel, ChannelMessage)
    case joinedChannel(Connection, String, String, String)
    case partedChannel(Connection, String, String, String, String?)
}

// MARK: - Action properties
extension NetworkAction {
    public var connect: ServerInfo? {
        get {
            guard case let .connect(value) = self else { return nil }
            return value
        }
        set {
            guard case .connect = self, let value = newValue else { return }
            self = .connect(value)
        }
    }
    
    public var messageSent: (IRCChannel, String)? {
        get {
            guard case let .messageSent(value1, value2) = self else { return nil }
            return (value1, value2)
        }
        set {
            guard case .messageSent = self, let (value1, value2) = newValue else { return }
            self = .messageSent(value1, value2)
        }
    }
    
    public var connectionAdded: (Connection, IRCChannel)? {
        get {
            guard case let .connectionAdded(value1, value2) = self else { return nil }
            return (value1, value2)
        }
        set {
            guard case .connectionAdded = self, let (value1, value2) = newValue else { return }
            self = .connectionAdded(value1, value2)
        }
    }
    
    public var welcomeReceived: (Connection, String)? {
        get {
            guard case let .welcomeReceived(value1, value2) = self else { return nil }
            return (value1, value2)
        }
        set {
            guard case .welcomeReceived = self, let (value1, value2) = newValue else { return }
            self = .welcomeReceived(value1, value2)
        }
    }
    
    public var messageReceived: (IRCChannel, ChannelMessage)? {
        get {
            guard case let .messageReceived(value1, value2) = self else { return nil }
            return (value1, value2)
        }
        set {
            guard case .messageReceived = self, let (value1, value2) = newValue else { return }
            self = .messageReceived(value1, value2)
        }
    }
    
    public var joinedChannel: (Connection, String, String, String)? {
        get {
            guard case let .joinedChannel(value1, value2, value3, value4) = self else { return nil }
            return (value1, value2, value3, value4)
        }
        set {
            guard case .joinedChannel = self, let (value1, value2, value3, value4) = newValue else { return }
            self = .joinedChannel(value1, value2, value3, value4)
        }
    }
    
    public var partedChannel: (Connection, String, String, String, String?)? {
        get {
            guard case let .partedChannel(value1, value2, value3, value4, value5) = self else { return nil }
            return (value1, value2, value3, value4, value5)
        }
        set {
            guard case .partedChannel = self, let (value1, value2, value3, value4, value5) = newValue else { return }
            self = .partedChannel(value1, value2, value3, value4, value5)
        }
    }
}
//
//protocol ConnectionsAction: Action {
//}
//
//struct ConnectAction: ConnectionsAction {
//    var server: ServerInfo
//}
//
//struct WelcomeAction: ConnectionsAction {
//    var connection: ServerConnection
//    var identifier: String
//}
//
//struct PrivateMessageAction: ConnectionsAction {
//    var connection: ServerConnection
//    var identifier: String
//    var nick: String
//    var recipient: String
//    var message: ChannelMessage
//}
//
//struct MessageReceivedAction: ConnectionsAction {
//    var connection: ServerConnection
//    var message: ChannelMessage
//    var channel: String
//}
//
//struct MessageSentAction: ConnectionsAction {
//    var connection: ServerConnection
//    var message: String
//    var channel: String
//}
//
//struct JoinedChannelAction: ConnectionsAction {
//    var connection: ServerConnection
//    var identifier: String
//    var nick: String
//    var channel: String
//}
//
//struct PartChannelAction: ConnectionsAction {
//    var connection: ServerConnection
//    var identifier: String
//    var nick: String
//    var message: String?
//    var channel: String
//}
//
//struct ChannelTopicAction: ConnectionsAction {
//    var connection: ServerConnection
//    var channel: String
//    var topic: String
//}
//
//struct UsersInChannelAction: ConnectionsAction {
//    var connection: ServerConnection
//    var users: [User]
//    var channel: String
//}
