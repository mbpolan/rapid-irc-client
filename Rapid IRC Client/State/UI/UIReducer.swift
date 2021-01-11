//
//  Reducer.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 11/23/20.
//

import SwiftRex

// MARK: - Reducer
let uiReducer = Reducer<UIAction, UIState> { action, state in
    switch action {
    case .toggleConnectSheet(let value):
        return UIState(
            connectSheetShown: value,
            currentChannel: state.currentChannel)
    
    case .connectionAdded(let connection):
        return UIState(
            connectSheetShown: state.connectSheetShown,
            currentChannel: connection.channels.first)
        
    case .changeChannel:
        return UIState(
            connectSheetShown: state.connectSheetShown,
            currentChannel: action.changeChannel)
    }
}
