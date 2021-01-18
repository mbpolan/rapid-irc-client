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
    var currentChannel: IRCChannel?
    var showTimestampsInChat: Bool
    
    static var empty: UIState {
        .init(
            connectSheetShown: false,
            currentChannel: nil,
            showTimestampsInChat: UserDefaults.standard.bool(forKey: AppSettings.timestampsInChat.rawValue))
    }
}
