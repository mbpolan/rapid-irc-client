//
//  Store.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/28/20.
//

import CombineRex
import SwiftUI
import SwiftRex

// MARK: - State
struct AppState {
    var network: NetworkState = NetworkState()
    var ui: UIState = .empty
}

enum AppAction {
    case network(NetworkAction)
    case ui(UIAction)
}

// MARK: Actions
extension AppAction {
    public var network: NetworkAction? {
        get {
            guard case let .network(value) = self else { return nil }
            return value
        }
        set {
            guard case .network = self, let newValue = newValue else { return }
            self = .network(newValue)
        }
    }
    
    public var ui: UIAction? {
        get {
            guard case let .ui(value) = self else { return nil }
            return value
        }
        set {
            guard case .ui = self, let newValue = newValue else { return }
            self = .ui(newValue)
        }
    }
}

// MARK: - Reducer
let appReducer = uiReducer.lift(
    action: \AppAction.ui,
    state: \AppState.ui
) <> networkReducer.lift(
    action: \AppAction.network,
    state: \AppState.network
)

// MARK: - Middleware
let appMiddleware = NetworkMiddleware().lift(
    inputAction: \AppAction.network,
    outputAction: identity,
    state: identity)

// MARK: - Store
class Store: ReduxStoreBase<AppAction, AppState> {
    
    public static let instance = Store()
    
    init() {
        super.init(
            subject: .combine(initialValue: AppState()),
            reducer: appReducer,
            middleware: appMiddleware)
    }
}

// MARK: - Functional helpers
func ignore<T>(_ t: T) -> Void { }
func identity<T>(_ t: T) -> T { t }
func absurd<T>(_ never: Never) -> T { }
