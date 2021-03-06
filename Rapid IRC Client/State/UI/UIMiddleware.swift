//
//  UIMiddleware.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 1/15/21.
//

import Foundation
import SwiftRex

class UIMiddleware: Middleware {
    
    typealias InputActionType = UIAction
    typealias OutputActionType = AppAction
    typealias StateType = AppState
    
    private var getState: GetState<AppState>!
    private var output: AnyActionHandler<AppAction>!
    
    func receiveContext(getState: @escaping GetState<AppState>, output: AnyActionHandler<AppAction>) {
        self.getState = getState
        self.output = output
    }
    
    func handle(action: UIAction, from dispatcher: ActionSource, afterReducer: inout AfterReducer) {
        switch action {
        case .sendOperatorLogin(let username, let password):
            let state = getState()
            
            if let connection = state.ui.pendingOperatorConnection {
                // send the OPER command to the server
                output.dispatch(.network(
                                    .operatorLogin(
                                        connection: connection,
                                        username: username,
                                        password: password)))
            }
            
            // hide the operator login sheet, if it's shown
            output.dispatch(.ui(.hideOperatorSheet))
        
        case .sendChannelModeChange(let modeChange):
            let state = getState()
            
            // send a MODE command to the server
            if let channel = state.ui.pendingChannelPropertiesChannel {
                output.dispatch(.network(
                                    .setChannelMode(
                                        connection: channel.connection,
                                        channelName: channel.name,
                                        mode: modeChange.toModeString())))
            }
            
            // hide the channel mode properties sheet
            output.dispatch(.ui(.hideChannelPropertiesSheet))
        
        case .sendChannelTopicChange(let topic):
            let state = getState()
            
            // send a TOPIC command to the server
            if let channel = state.ui.pendingChannelTopicChannel {
                output.dispatch(.network(
                                    .setChannelTopic(
                                        connection: channel.connection,
                                        channelName: channel.name,
                                        topic: topic)))
            }
            
            // hide the channel topic sheet
            output.dispatch(.ui(.hideChannelTopicSheet))
        
        case .connectToServer(let serverInfo):
            // initiate the connection to the server
            output.dispatch(.network(.connect(serverInfo: serverInfo)))
            
            // hide the connect sheet
            output.dispatch(.ui(.toggleConnectSheet(shown: false)))
            
        case .openPrivateMessage(let connection, let nick):
            let state = getState()
            guard let target = state.network.connections.first(where: { $0 === connection }) else { return }
            
            // do we have a channel for private messages to this nick? if so, change to that channel
            // otherwise, open a new channel and change to it
            if !target.channels.contains(where: { $0.name == nick && $0.descriptor == .user }) {
                output.dispatch(.network(
                                    .clientJoinedChannel(
                                        connection: target,
                                        channelName: nick,
                                        descriptor: .user)))
            }
            
            output.dispatch(.ui(
                                .changeChannel(
                                    connection: connection,
                                    channelName: nick)))
            
        case .closeServer(let connection):
            let state = getState()
            guard let target = state.network.connections.first(where: { $0 === connection }) else { return }
            
            // if the connection is active, we need to first disconnect it
            if target.state == .connected {
                output.dispatch(.network(
                                    .disconnect(
                                        connection: target)))
            }
            
            // if the currently active channel belongs to this connection, we need to choose another one
            // or default to no open channel if this is our only connection
            if state.ui.currentChannel?.connection === connection {
                if let newConnection = state.network.connections.first(where: { $0 !== connection }) {
                    output.dispatch(.ui(
                                        .changeChannel(
                                            connection: newConnection,
                                            channelName: Connection.serverChannel)))
                } else {
                    output.dispatch(.ui(.resetActiveChannel))
                }
            }
            
            // remove the connection and all of its associated channels
            output.dispatch(.network(
                                .removeConnection(
                                    connection: target)))
            
        case .closeChannel(let connection, let channelName, let descriptor):
            let state = getState()
            
            // are we closing the channel that is currently open? if so, open the default server channel instead
            if channelName == state.ui.currentChannel?.name {
                output.dispatch(.ui(
                                    .changeChannel(
                                        connection: connection,
                                        channelName: Connection.serverChannel)))
            }
            
            // if this is a multiuser channel, ensure we part the channel server-side
            if descriptor == .multiUser {
                connection.client.sendMessage("part \(channelName)")
            }
            
            // remove the channel from network management entirely
            output.dispatch(.network(
                                .removeChannel(
                                    connection: connection,
                                    channelName: channelName)))
            
        default:
            break
        }
    }
}
