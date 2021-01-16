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
        case .closeChannel(let connection, let channelName):
            let state = getState()
            
            // are we closing the channel that is currently open? if so, open the default server channel instead
            if channelName == state.ui.currentChannel?.name {
                output.dispatch(.ui(.changeChannel(connection, Connection.serverChannel)))
            }
            
            // ensure we part the channel server-side
            connection.client.sendMessage("part \(channelName)")
            
            // remove the channel from network management entirely
            output.dispatch(.network(
                                .removeChannel(
                                    connection,
                                    channelName)))
            break
            
        default:
            break
        }
    }
}
