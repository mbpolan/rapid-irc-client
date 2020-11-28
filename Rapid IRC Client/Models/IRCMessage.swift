//
//  IRCMessage.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/31/20.
//

import SwiftUI

struct IRCMessage {
    
    var raw: String
    var prefix: String?
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
        var prefix: String? = nil
        if parts.first!.starts(with: ":") {
            prefix = String(parts.first!).subString(from: 1)
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
    
    private init(raw: String, prefix: String?, command: Command?, target: String?, parameters: [String]?) {
        self.raw = raw
        self.prefix = prefix
        self.command = command
        self.parameters = parameters ?? []
    }
}
