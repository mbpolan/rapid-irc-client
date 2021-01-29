//
//  IRCMessage.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/31/20.
//

import SwiftUI

struct IRCMessage {
    
    var raw: String
    var prefix: Prefix?
    var command: Command?
    var target: String?
    var parameters: [String] = []
    var timestamp: Date
    
    init(from message: String) {
        var parts = message.split(separator: " ")
        
        // no-op
        if parts.isEmpty {
            self.raw = message
            self.timestamp = Date()
            return
        }
        
        // prefix is optional, but if it exists, it's always lead by a colon
        var prefix: Prefix? = nil
        if parts.first!.starts(with: ":") {
            prefix = Prefix.parse(String(parts.first!).subString(from: 1))
            parts.removeFirst()
        }
        
        // command is either a text string or a three digit numeric
        let rawCommand = String(parts.first!).lowercased()
        let command = rawCommand.isNumber ? Command.fromCode(code: rawCommand) : Command.fromString(name: rawCommand)
        
        parts.removeFirst()
        
        // extract the parameters
        var parameters = parts.map{ String($0) }
        
        // if the command is a numeric reply, the first parameter is the target
        var target: String?
        if rawCommand.isNumber {
            target = parameters.removeFirst()
        }
        
        self.raw = message
        self.prefix = prefix
        self.command = command
        self.target = target
        self.parameters = parameters
        self.timestamp = Date()
    }
}

extension IRCMessage {
    struct Prefix: Equatable {
        
        // the raw prefix, without the leading colon
        var raw: String
        
        // either the server name or nick
        var subject: String
        
        // optional username from the !user@host segment
        var user: String?
        
        // optioanl hostname from the !user@host segment
        var host: String?
        
        static func == (lhs: IRCMessage.Prefix, rhs: IRCMessage.Prefix) -> Bool {
            return lhs.raw == rhs.raw
        }
        
        static func parse(_ raw: String) -> Prefix? {
            let subject: String
            var user: String?
            var host: String?
            
            // check for presence of ! separator
            if let ex = raw.range(of: "!") {
                subject = String(raw[..<ex.lowerBound])
                let network = raw[ex.upperBound...]
                
                // check for presence of @ separator
                if let at = network.range(of: "@") {
                    user = String(network[..<at.lowerBound])
                    host = String(network[at.upperBound...])
                } else {
                    user = String(network)
                }
            } else {
                subject = raw
            }
            
            return Prefix(
                raw: raw,
                subject: subject,
                user: user,
                host: host)
        }
        
        func withSubject(_ subject: String) -> IRCMessage.Prefix {
            return IRCMessage.Prefix(
                raw: self.raw.replacingOccurrences(of: self.subject, with: subject),
                subject: subject,
                user: self.user,
                host: self.host)
        }
    }
}
