//
//  SavedServerInfo.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 2/27/21.
//

import Foundation

/// Model that represents a saved IRC server.
class SavedServerInfo: Identifiable, ObservableObject, Codable {
    
    enum CodingKeys: CodingKey {
        case id
        case label
        case secure
        case sslVerificationMode
        case nick
        case realName
        case username
        case host
        case port
        case password
    }
    
    let id: UUID
    @Published var label: String
    @Published var secure: Bool
    @Published var sslVerificationMode: SSLVerificationMode
    @Published var nick: String
    @Published var realName: String
    @Published var username: String
    @Published var host: String
    @Published var port: String
    @Published var password: String
    
    init(id: UUID,
         label: String,
         secure: Bool,
         sslVerificationMode: SSLVerificationMode,
         nick: String,
         realName: String,
         username: String,
         host: String,
         port: String,
         password: String) {
        
        self.id = id
        self.label = label
        self.secure = secure
        self.sslVerificationMode = sslVerificationMode
        self.nick = nick
        self.realName = realName
        self.username = username
        self.host = host
        self.port = port
        self.password = password
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.label = try container.decode(String.self, forKey: .label)
        self.secure = try container.decode(Bool.self, forKey: .secure)
        self.sslVerificationMode = try container.decode(SSLVerificationMode.self, forKey: .sslVerificationMode)
        self.nick = try container.decode(String.self, forKey: .nick)
        self.realName = try container.decode(String.self, forKey: .realName)
        self.username = try container.decode(String.self, forKey: .username)
        self.host = try container.decode(String.self, forKey: .host)
        self.port = try container.decode(String.self, forKey: .port)
        self.password = try container.decode(String.self, forKey: .password)
    }
    
    static var empty: SavedServerInfo {
        SavedServerInfo(
            id: UUID(),
            label: "",
            secure: false,
            sslVerificationMode: .disabled,
            nick: "",
            realName: "",
            username: "",
            host: "",
            port: "",
            password: "")
    }
    
    static func == (lhs: SavedServerInfo, rhs: SavedServerInfo) -> Bool {
        return lhs.id == rhs.id &&
            lhs.label == rhs.label &&
            lhs.secure == rhs.secure &&
            lhs.sslVerificationMode == rhs.sslVerificationMode &&
            lhs.nick == rhs.nick &&
            lhs.realName == rhs.realName &&
            lhs.username == rhs.username &&
            lhs.host == rhs.host &&
            lhs.port == rhs.port &&
            lhs.password == rhs.password
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(label, forKey: .label)
        try container.encode(secure, forKey: .secure)
        try container.encode(sslVerificationMode, forKey: .sslVerificationMode)
        try container.encode(nick, forKey: .nick)
        try container.encode(realName, forKey: .realName)
        try container.encode(username, forKey: .username)
        try container.encode(host, forKey: .host)
        try container.encode(port, forKey: .port)
        try container.encode(password, forKey: .password)
    }
}
