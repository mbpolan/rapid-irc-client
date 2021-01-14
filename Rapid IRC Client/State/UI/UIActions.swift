//
//  UIActions.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 11/23/20.
//

// MARK: - Actions
// sourcery: Prism
enum UIAction {
    case toggleConnectSheet(Bool)
    case connectionAdded(Connection)
    case changeChannel(IRCChannel)
}
