//
//  ServerInfo.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/28/20.
//

// MARK: - ServerInfo

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

// MARK: - Extensions
extension ServerInfo {
    
    init(from server: SavedServerInfo) {
        self.secure = server.secure
        self.sslVerificationMode = server.sslVerificationMode
        self.nick = server.nick
        self.realName = server.realName
        self.username = server.username
        self.host = server.host
        self.port = Int(server.port) ?? 6667
        self.password = server.password
    }
}
