//
//  UIActions.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 11/23/20.
//

// MARK: - Actions
// sourcery: Prism
enum UIAction {
    case toggleConnectSheet(shown: Bool)
    case toggleChatTimestamps(shown: Bool)
    case toggleJoinPartEvents(shown: Bool)
    case connectionAdded(connection: Connection)
    case changeChannel(connection: Connection, channelName: String)
    case openPrivateMessage(connection: Connection, nick: String)
    
    case closeChannel(connection: Connection, channelName: String, descriptor: IRCChannel.Descriptor)
}
