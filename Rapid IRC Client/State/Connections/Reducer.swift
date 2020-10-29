//
//  Reducer.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/28/20.
//

struct ConnectionsState {
    var connections: [Connection] = []
    var current = -1
}

func connectionsReducer(state: AppState, action: Action) -> AppState {
    var newState = state
    
    switch action {
    default:
        break
    }
    
    return newState
}
