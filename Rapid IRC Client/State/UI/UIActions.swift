//
//  Actions.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 11/23/20.
//

protocol UIAction: Action {
}

struct SetChannelAction: UIAction {
    var connection: Connection
    var channel: String
}
