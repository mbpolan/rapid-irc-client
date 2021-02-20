//
//  NetworkActions.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/28/20.
//

import Foundation

// MARK: - Actions
// sourcery: Prism
enum NetworkAction {
    case connect(serverInfo: ServerInfo, joinChannelNames: [String]? = [])
    case reconnect(connection: Connection, joinChannelNames: [String]? = [])
    case disconnect(connection: Connection)
    case messageSent(channel: IRCChannel?, rawMessage: String)
    case operatorLogin(connection: Connection, username: String, password: String)
    case disconnectAllForSleep(completion: () -> Void)
    
    case addChannelNotification(connection: Connection, channelName: String, notification: IRCChannel.Notification)
    
    case connectionAdded(connection: Connection, serverChannel: IRCChannel)
    case connectionStateChanged(connection: Connection, connectionState: Connection.State)
    case welcomeReceived(connection: Connection, identifier: String)
    case hostnameReceived(connection: Connection, hostname: String)
    case nickReceived(connection: Connection, identifier: IRCMessage.Prefix, nick: String)
    case kickReceived(connection: Connection, identifier: IRCMessage.Prefix, channelName: String, nick: String, reason: String?)
    case inviteConfirmed(connection: Connection, channelName: String, nick: String)
    case messageReceived(connection: Connection, channelName: String, message: ChannelMessage)
    case channelTopicReceived(connection: Connection, channelName: String, topic: String)
    case channelTopicChanged(connection: Connection, channelName: String, identifier: IRCMessage.Prefix, topic: String)
    case channelTopicMetadataReceived(connection: Connection, channelName: String, who: String, when: Date)
    case updateChannelTopic(connection: Connection, channelName: String, topic: String)
    case updateChannelTopicMetadata(connection: Connection, channelName: String, who: String, when: Date)
    case usernamesReceived(connection: Connection, channelName: String, usernames: [String])
    case allUsernamesReceived(connection: Connection, channelName: String)
    case applyIncomingChannelUsers(connection: Connection, channelName: String)
    case addIncomingChannelUsers(connection: Connection, channelName: String, users: Set<User>)
    case clearIncomingChannelUsers(connection: Connection, channelName: String)
    case joinedChannel(connection: Connection, channelName: String, identifier: IRCMessage.Prefix)
    case partedChannel(connection: Connection, channelName: String, identifier: String, nick: String, reason: String?)
    case channelStateChanged(connection: Connection, channelName: String, channelState: IRCChannel.State)
    case channelModeChanged(connection: Connection, channelName: String, mode: ChannelMode)
    case userJoinedChannel(connection: Connection, channelName: String, user: User)
    case clientJoinedChannel(connection: Connection, channelName: String, descriptor: IRCChannel.Descriptor)
    case clientLeftChannel(connection: Connection, channelName: String)
    case userLeftChannel(conn: Connection, channelName: String, user: User)
    case removeConnection(connection: Connection)
    case renameChannel(connection: Connection, oldChannelName: String, newChannelName: String)
    case removeChannel(connection: Connection, channelName: String)
    case modeReceived(connection: Connection, identifier: IRCMessage.Prefix, target: String, modeString: String, modeArgs: [String])
    case channelModeReceived(connection: Connection, channelName: String, modeString: String, modeArgs: [String])
    case setChannelTopic(connection: Connection, channelName: String, topic: String)
    case setChannelMode(connection: Connection, channelName: String, mode: String)
    case setUserMode(connection: Connection, channelName: String, nick: String, mode: String)
    case privateMessageReceived(connection: Connection, identifier: IRCMessage.Prefix, recipient: String, message: ChannelMessage)
    case userChannelModeAdded(connection: Connection, channelName: String, nick: String, privilege: User.ChannelPrivilege)
    case userChannelModeRemoved(connection: Connection, channelName: String, nick: String, privilege: User.ChannelPrivilege)
    case userAwayReceived(connection: Connection, nick: String, message: ChannelMessage)
    case kickUserFromChannel(connection: Connection, channelName: String, nick: String, reason: String?)
    case inviteUserToChannel(connection: Connection, nick: String, channelName: String)
    case userQuit(connection: Connection, identifier: IRCMessage.Prefix, reason: String)
    
    case errorReceived(connection: Connection, message: ChannelMessage)
}
