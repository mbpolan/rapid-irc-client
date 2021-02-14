//
//  UIState.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 1/10/21.
//

import Foundation

// MARK: - State
struct UIState {
    var connectSheetShown: Bool
    var requestOperatorSheetShown: Bool
    var pendingOperatorConnection: Connection?
    var channelPropertiesSheetShown: Bool
    var pendingChannelPropertiesChannel: IRCChannel?
    var currentChannel: IRCChannel?
    var showTimestampsInChat: Bool
    var showJoinAndPartEvents: Bool
    
    static var empty: UIState {
        .init(
            connectSheetShown: false,
            requestOperatorSheetShown: false,
            channelPropertiesSheetShown: false,
            pendingChannelPropertiesChannel: nil,
            currentChannel: nil,
            showTimestampsInChat: UserDefaults.standard.bool(forKey: AppSettings.timestampsInChat.rawValue),
            showJoinAndPartEvents: UserDefaults.standard.bool(forKey: AppSettings.showJoinAndPartEvents.rawValue))
    }
}
