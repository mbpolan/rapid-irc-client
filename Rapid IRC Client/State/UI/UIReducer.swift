//
//  Reducer.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 11/23/20.
//

struct UIState {
    var currentChannel: IRCChannel?
}

func uiReducer(state: AppState, action: ActionWrapper) -> AppState {
    var newState = state

    switch action.action {
    case let act as SetChannelAction:
        newState.ui.currentChannel = act.connection.channels.first { $0.name == act.channel}
        print(newState.ui.currentChannel)
    
    default:
        break
    }

    return newState
}
