//
//  Actions.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/28/20.
//

protocol ConnectionsAction: Action {
}

struct ConnectAction: ConnectionsAction {
    var server: ServerInfo
}

struct WelcomeAction: ConnectionsAction {
    var connection: ServerConnection
    var identifier: String
}

struct PrivateMessageAction: ConnectionsAction {
    var connection: ServerConnection
    var identifier: String
    var nick: String
    var recipient: String
    var message: ChannelMessage
}

struct MessageReceivedAction: ConnectionsAction {
    var connection: ServerConnection
    var message: ChannelMessage
    var channel: String
}

struct MessageSentAction: ConnectionsAction {
    var connection: ServerConnection
    var message: String
    var channel: String
}

struct JoinedChannelAction: ConnectionsAction {
    var connection: ServerConnection
    var identifier: String
    var nick: String
    var channel: String
}

struct PartChannelAction: ConnectionsAction {
    var connection: ServerConnection
    var identifier: String
    var nick: String
    var message: String?
    var channel: String
}

struct ChannelTopicAction: ConnectionsAction {
    var connection: ServerConnection
    var channel: String
    var topic: String
}

struct UsersInChannelAction: ConnectionsAction {
    var connection: ServerConnection
    var users: [User]
    var channel: String
}
