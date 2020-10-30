//
//  Store.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/28/20.
//

import Combine
import SwiftUI

struct AppState {
    var connections: ConnectionsState = ConnectionsState()
}

struct StateWrapper {
    var state: AppState
    var store: Store
}

protocol Action {}

struct ActionWrapper {
    var store: Store
    var action: Action
}

typealias Reducer = (AppState, ActionWrapper) -> AppState

let reducers = [
    connectionsReducer
]

func rootReducer(state: AppState, action: ActionWrapper) -> AppState {
    var newState = state

    for reducer in reducers {
        newState = reducer(newState, action)
    }

    return newState
}

class Store: ObservableObject {

    private var reducer: Reducer
    @Published var state: AppState

    init(reducer: @escaping Reducer, state: AppState = AppState()) {
        self.reducer = reducer
        self.state = state
    }

    func dispatch(action: Action) {
        self.state = self.reducer(state, ActionWrapper(store: self, action: action))
        objectWillChange.send()
    }
}

