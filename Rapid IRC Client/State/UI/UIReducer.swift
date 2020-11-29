//
//  Reducer.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 11/23/20.
//

struct UIState {
    var currentChannel: String?
}

func uiReducer(state: AppState, action: ActionWrapper) -> AppState {
    var newState = state

    switch action.action {
    case let act as SetChannelAction:
        newState.ui.currentChannel = act.channel
    
    default:
        break
    }

    return newState
}
