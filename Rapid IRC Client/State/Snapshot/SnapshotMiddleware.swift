//
//  SnapshotMiddleware.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 2/1/21.
//

import Foundation
import SwiftRex

class SnapshotMiddleware: Middleware {
    
    typealias InputActionType = SnapshotAction
    typealias OutputActionType = AppAction
    typealias StateType = AppState
    
    private var getState: GetState<AppState>!
    private var output: AnyActionHandler<AppAction>!
    
    func receiveContext(getState: @escaping GetState<AppState>, output: AnyActionHandler<AppAction>) {
        self.getState = getState
        self.output = output
    }
    
    func handle(action: SnapshotAction, from dispatcher: ActionSource, afterReducer: inout AfterReducer) {
        switch action {
        case .save(let completion):
            let state = getState()
            
            // find all active connections, and each multi-user channel that is joined
            let connections = state.network.connections
                .filter { $0.state == .connected }
                .map { connection -> (UUID, [String]) in
                    let channelNames = connection.channels
                        .filter { $0.state == .joined && $0.descriptor == .multiUser }
                        .map { $0.name }
                    
                    return (connection.id, channelNames)
                }
            
            let connectionsToChannels = Dictionary(uniqueKeysWithValues: connections)
            
            output.dispatch(.snapshot(
                                .push(
                                    timestamp: Date(),
                                    connectionsToChannels: connectionsToChannels)))
            
            afterReducer = .do(completion)
            
        case .restore:
            let state = getState()
            
            // examine each connection that was previously active
            state.snapshot.connectionsToChannels.forEach { (id: UUID, channelNames: [String]) in
                guard let connection = state.network.connections.first(where: { $0.id == id }) else { return }
                
                // and reconnect to that server, optionally rejoining any previously active channels
                self.output.dispatch(.network(
                                        .reconnect(
                                            connection: connection,
                                            joinChannelNames: channelNames)))
            }
            
            output.dispatch(.snapshot(.pop))
        
        default:
            break
        }
    }
}
