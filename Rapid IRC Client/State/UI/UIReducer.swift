//
//  UIReducer.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 11/23/20.
//

import SwiftRex

// MARK: - Reducer
let uiReducer = Reducer<UIAction, UIState> { action, state in
    switch action {
    case .resetActiveChannel:
        var newState = state
        newState.currentChannel = nil
        return newState
        
    case .showOperatorSheet(let connection):
        var newState = state
        newState.pendingOperatorConnection = connection
        newState.requestOperatorSheetShown = true
        return newState
        
    case .hideOperatorSheet:
        var newState = state
        newState.pendingOperatorConnection = nil
        newState.requestOperatorSheetShown = false
        return newState
        
    case .showChannelPropertiesSheet(let connection, let channelName):
        var newState = state
        if let channel = connection.channels.first(where: { $0.name == channelName }) {
            newState.channelPropertiesSheetShown = true
            newState.pendingChannelPropertiesChannel = channel
        }
        
        return newState
        
    case .hideChannelPropertiesSheet:
        var newState = state
        newState.channelPropertiesSheetShown = false
        newState.pendingChannelPropertiesChannel = nil
        return newState
        
    case .showChannelTopicSheet(let connection, let channelName):
        var newState = state
        if let channel = connection.channels.first(where: { $0.name == channelName }) {
            newState.channelTopicSheetShown = true
            newState.pendingChannelTopicChannel = channel
        }
        
        return newState
        
    case .hideChannelTopicSheet:
        var newState = state
        newState.channelTopicSheetShown = false
        newState.pendingChannelTopicChannel = nil
        return newState
        
    case .toggleConnectSheet(let value):
        var newState = state
        newState.connectSheetShown = value
        return newState
        
    case .toggleChatTimestamps(let value):
        var newState = state
        newState.showTimestampsInChat = value
        return newState
        
    case .toggleJoinPartEvents(let value):
        var newState = state
        newState.showJoinAndPartEvents = value
        return newState
        
    case .connectionAdded(let connection):
        var newState = state
        newState.currentChannel = connection.channels.first
        return newState
        
    case .changeChannel(let connection, let channelName):
        var newState = state
        if let channel = connection.channels.first(where: { $0.name == channelName }) {
            // clear any outstanding notifications
            channel.notifications = []
            
            // set this as our current channel
            newState.currentChannel = channel
        }
        
        return newState
        
    default:
        return state
    }
}
