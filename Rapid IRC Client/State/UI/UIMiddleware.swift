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
