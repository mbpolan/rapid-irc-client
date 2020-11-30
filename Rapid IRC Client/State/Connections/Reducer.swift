//
//  Reducer.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/28/20.
//

struct ConnectionsState {
    var connections: [Connection] = []
    var channelUuids: [String: IRCChannel] = [:]
}

func connectionsReducer(state: AppState, action: ActionWrapper) -> AppState {
    var newState = state

    switch action.action {
    case let act as ConnectAction:
        let connection = Connection(
            name: act.server.host,
            client: ServerConnection(server: act.server, store: action.store))
        
        let serverChannel = connection.addChannel(name: Connection.serverChannel)
        newState.connections.channelUuids[serverChannel.id] = serverChannel
        newState.ui.currentChannel = serverChannel.id
        
        connection.client.connect()

        newState.connections.connections.append(connection)
        
    case let act as WelcomeAction:
        let connection = newState.connections.connections.first { conn in
            conn.client === act.connection
        }
        
        connection?.identifier = act.identifier
    
    case let act as MessageReceivedAction:
        let connection = newState.connections.connections.first { conn in
            conn.client === act.connection
        }
        
        if connection != nil {
            connection!.addMessage(channel: Connection.serverChannel, message: act.message)
        } else {
            print("**ERROR**")
        }
        
    case let act as MessageSentAction:
        let message = act.message.starts(with: "/") ? act.message.subString(from: 1) : act.message
        act.connection.sendMessage(message)
        
    case let act as JoinedChannelAction:
        let connection = newState.connections.connections.first { conn in
            conn.client === act.connection
        }
        
        if connection != nil {
            let channel = connection!.addChannel(name: act.channel)
            newState.connections.channelUuids[channel.id] = channel
            
            channel.messages.append(ChannelMessage(
                                        text: "\(act.identifier) has joined \(act.channel)",
                                        variant: .userJoined))
            
            channel.users.insert(User(
                                    name: act.nick,
                                    privilege: nil))
        }
        
    case let act as PartChannelAction:
        let connection = newState.connections.connections.first { conn in
            conn.client === act.connection
        }
        
        if connection != nil {
            let channel = connection!.channels.first { $0.name == act.channel }!
            
            channel.messages.append(ChannelMessage(
                                        text: "\(act.identifier) has left \(act.channel)",
                                        variant: .userParted))
            
            // does this message refer to us? if so, part the channel from our perspective.
            // if another user has left, remove them from the user list.
            if act.identifier == connection?.identifier {
                connection!.leaveChannel(channel: act.channel)
            } else if let targetUser = channel.users.first(where: { $0.name == act.nick }) {
                channel.users.remove(targetUser)
            }
        }
        
    case let act as PrivateMessageAction:
        let connection = newState.connections.connections.first { conn in
            conn.client === act.connection
        }
        
        if connection != nil {
            // FIXME: this can also include other users instead of just channels
            if let channel = connection!.channels.first(where: { $0.name == act.recipient }) {
                channel.messages.append(act.message)
            }
        }
        
    case let act as UsersInChannelAction:
        let connection = newState.connections.connections.first { conn in
            conn.client === act.connection
        }
        
        connection?.channels.first { $0.name == act.channel }?.users.formUnion(act.users)
    
    case let act as ChannelTopicAction:
        let connection = newState.connections.connections.first { conn in
            conn.client === act.connection
        }
        
        connection?.channels.first { $0.name == act.channel }?.topic = act.topic
        
    default:
        break
    }

    return newState
}

