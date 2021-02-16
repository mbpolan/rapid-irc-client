//
//  UIActions.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 11/23/20.
//

// MARK: - Actions
// sourcery: Prism
enum UIAction {
    case resetActiveChannel
    
    case showOperatorSheet(connection: Connection)
    case hideOperatorSheet
    case showChannelPropertiesSheet(connection: Connection, channelName: String)
    case hideChannelPropertiesSheet
    case showChannelTopicSheet(connection: Connection, channelName: String)
    case hideChannelTopicSheet
    case sendOperatorLogin(username: String, password: String)
    case sendChannelModeChange(modeChange: ChannelModeChange)
    case sendChannelTopicChange(topic: String)
    case connectToServer(serverInfo: ServerInfo)
    case toggleConnectSheet(shown: Bool)
    case toggleChatTimestamps(shown: Bool)
    case toggleJoinPartEvents(shown: Bool)
    case connectionAdded(connection: Connection)
    case changeChannel(connection: Connection, channelName: String)
    case openPrivateMessage(connection: Connection, nick: String)
    
    case closeServer(connection: Connection)
    case closeChannel(connection: Connection, channelName: String, descriptor: IRCChannel.Descriptor)
}
