//
//  NetworkActions.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/28/20.
//

// MARK: - Actions
// sourcery: Prism
enum NetworkAction {
    case connect(serverInfo: ServerInfo)
    case reconnect(connection: Connection)
    case disconnect(connection: Connection)
    case messageSent(channel: IRCChannel, rawMessage: String)
    
    case addChannelNotification(connection: Connection, channelName: String, notification: IRCChannel.Notification)
    
    case connectionAdded(connection: Connection, serverChannel: IRCChannel)
    case connectionStateChanged(connection: Connection, connectionState: Connection.State)
    case welcomeReceived(connection: Connection, identifier: String)
    case hostnameReceived(connection: Connection, hostname: String)
    case messageReceived(connection: Connection, channelName: String, message: ChannelMessage)
    case channelTopicReceived(connection: Connection, channelName: String, topic: String)
    case channelTopicChanged(connection: Connection, channelName: String, identifier: IRCMessage.Prefix, topic: String)
    case updateChannelTopic(connection: Connection, channelName: String, topic: String)
    case usernamesReceived(connection: Connection, channelName: String, usernames: [String])
    case allUsernamesReceived(connection: Connection, channelName: String)
    case applyIncomingChannelUsers(connection: Connection, channelName: String)
    case addIncomingChannelUsers(connection: Connection, channelName: String, users: Set<User>)
    case clearIncomingChannelUsers(connection: Connection, channelName: String)
    case joinedChannel(connection: Connection, channelName: String, identifier: IRCMessage.Prefix)
    case partedChannel(connection: Connection, channelName: String, identifier: String, nick: String, reason: String?)
    case channelStateChanged(connection: Connection, channelName: String, channelState: IRCChannel.State)
    case userJoinedChannel(connection: Connection, channelName: String, user: User)
    case clientJoinedChannel(connection: Connection, channelName: String, descriptor: IRCChannel.Descriptor)
    case clientLeftChannel(connection: Connection, channelName: String)
    case userLeftChannel(conn: Connection, channelName: String, user: User)
    case removeChannel(connection: Connection, channelName: String)
    case privateMessageReceived(connection: Connection, identifier: IRCMessage.Prefix, recipient: String, message: ChannelMessage)
    case userQuit(connection: Connection, identifier: IRCMessage.Prefix, reason: String)
    
    case errorReceived(connection: Connection, message: ChannelMessage)
}
