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
        case .connect(let serverInfo):
            let connection = Connection(
                name: serverInfo.host,
                serverInfo: serverInfo,
                store: Store.instance)
            
            let serverChannel = connection.addChannel(name: Connection.serverChannel)
            
            connection.client.connect()
            
            output.dispatch(.network(.connectionAdded(connection, serverChannel)))
            output.dispatch(.ui(.connectionAdded(connection)))
            
        case .reconnect(let connection):
            // client will dispatch an action to inform when it's connected
            connection.client.connect()
        
        case .disconnect(let connection):
            // client will dispatch an action to inform when it's disconnected
            connection.client.disconnect()
        
        case .prepareJoinChannel(let connection, let channelName, let identifier, let nick):
            output.dispatch(.network(
                                .joinedChannel(
                                    connection,
                                    channelName,
                                    identifier,
                                    nick)))
            
            // set this to be the active chanel
            output.dispatch(.ui(.changeChannel(connection, channelName)))
            
        case .messageSent(let channel, let text):
            let message = text.starts(with: "/") ? text.subString(from: 1) : text
            channel.connection.client.sendMessage(message)
        
        default:
            break
        }
    }
    
}
