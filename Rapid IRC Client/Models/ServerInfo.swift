//
//  ServerInfo.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/28/20.
//

/// Connection information for an IRC server.
struct ServerInfo: Equatable {
    let secure: Bool
    let sslVerificationMode: SSLVerificationMode?
    let nick: String
    let realName: String
    let username: String
    let host: String
    let port: Int
    let password: String?
}
