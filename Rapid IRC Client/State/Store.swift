//
//  Store.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/28/20.
//

import SwiftUI

struct AppState {
    var connections: ConnectionsState = ConnectionsState()
}

protocol Action { }

typealias Reducer = (AppState, Action) -> AppState

let reducers = [
    connectionsReducer
]

func rootReducer(state: AppState, action: Action) -> AppState {
    var newState = state
    
    for reducer in reducers {
        newState = reducer(newState, action)
    }
    
    return state
}

class Store: ObservableObject {
    
    private var reducer: Reducer
    @Published var state: AppState
    
    init(reducer: @escaping Reducer, state: AppState = AppState()) {
        self.reducer = reducer
        self.state = state
    }
    
    func dispatch(action: Action) {
        self.state = self.reducer(state, action)
    }
}

