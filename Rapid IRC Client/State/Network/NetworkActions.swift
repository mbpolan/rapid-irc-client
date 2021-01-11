//
//  Actions.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/28/20.
//

// MARK: - Actions
enum NetworkAction {
    case connect(ServerInfo)
    case connectionAdded(Connection, IRCChannel)
    case messageReceived(IRCChannel, ChannelMessage)
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
