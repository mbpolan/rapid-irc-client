//
//  ServerInfo.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/28/20.
//

/// Connection information for an IRC server.
struct ServerInfo: Equatable {
    var nick: String
    var realName: String
    var username: String
    var host: String
    var port: Int
    var password: String?
}
