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

struct MessageReceivedAction: ConnectionsAction {
    var connection: ServerConnection
    var message: String
    var channel: String
}

struct MessageSentAction: ConnectionsAction {
    var message: String
}

struct JoinedChannelAction: ConnectionsAction {
    var connection: ServerConnection
    var channel: String
}

struct PartChannelAction: ConnectionsAction {
    var connection: ServerConnection
    var channel: String
}

struct UsersInChannelAction: ConnectionsAction {
    var connection: ServerConnection
    var users: [User]
    var channel: String
}
