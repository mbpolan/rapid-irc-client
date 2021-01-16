//
//  NetworkActions.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/28/20.
//

// MARK: - Actions
// sourcery: Prism
enum NetworkAction {
    case connect(ServerInfo)
    case reconnect(Connection)
    case disconnect(Connection)
    case messageSent(IRCChannel, String)
    
    case connectionAdded(Connection, IRCChannel)
    case connectionStateChanged(Connection, Connection.State)
    case welcomeReceived(Connection, String)
    case messageReceived(IRCChannel, ChannelMessage)
    case channelTopic(Connection, String, String)
    case usersInChannel(Connection, String, [User])
    case prepareJoinChannel(Connection, String, String, String)
    case joinedChannel(Connection, String, String, String)
    case partedChannel(Connection, String, String, String, String?)
    case privateMessageReceived(Connection, String, String, String, ChannelMessage)
    
    case errorReceived(Connection, ChannelMessage)
}
