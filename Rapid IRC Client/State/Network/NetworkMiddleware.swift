//
//  NetworkMiddleware.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 12/12/20.
//

import SwiftRex

class NetworkMiddleware: Middleware {
    
    typealias InputActionType = NetworkAction
    typealias OutputActionType = AppAction
    typealias StateType = AppState
    
    private var getState: GetState<AppState>!
    private var output: AnyActionHandler<AppAction>!
    
    func receiveContext(getState: @escaping GetState<AppState>, output: AnyActionHandler<AppAction>) {
        self.getState = getState
        self.output = output
    }
    
    func handle(action: NetworkAction, from dispatcher: ActionSource, afterReducer: inout AfterReducer) {
        switch action {
        case .connect:
            let serverInfo = action.connect!
            let connection = Connection(
                name: serverInfo.host,
                serverInfo: serverInfo,
                store: Store.instance)
            
            let serverChannel = connection.addChannel(name: Connection.serverChannel)
            
            connection.client.connect()
            
            output.dispatch(.network(.connectionAdded(connection, serverChannel)))
            output.dispatch(.ui(.connectionAdded(connection)))
        
            
        
        default:
            break
        }
    }
    
}
