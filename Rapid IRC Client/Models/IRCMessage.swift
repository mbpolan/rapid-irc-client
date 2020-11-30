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
    
    static func parse(_ message: String) -> IRCMessage {
        print("INCOMING: \(message)")
        var parts = message.split(separator: " ")
        
        // no-op
        if parts.isEmpty {
            return IRCMessage(raw: message)
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
        
        return IRCMessage(
            raw: message,
            prefix: prefix,
            command: command,
            target: target,
            parameters: parameters)
    }
    
    private init(raw: String) {
        self.raw = raw
        self.parameters = []
    }
    
    private init(raw: String, prefix: Prefix?, command: Command?, target: String?, parameters: [String]?) {
        self.raw = raw
        self.prefix = prefix
        self.command = command
        self.parameters = parameters ?? []
    }
}

extension IRCMessage {
    struct Prefix {
        
        // the raw prefix, without the leading colon
        var raw: String
        
        // either the server name or nick
        var subject: String
        
        // optional username from the !user@host segment
        var user: String?
        
        // optioanl hostname from the !user@host segment
        var host: String?
        
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
    }
}
