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
    var parameters: [String] = []
    
    static func parse(_ message: String) -> IRCMessage {
        var parts = message.split(separator: " ")
        
        // no-op
        if parts.isEmpty {
            return IRCMessage(raw: message)
        }
        
        // prefix is optional, but if it exists, it's always lead by a colon
        var prefix: String? = nil
        if parts.first == ":" {
            prefix = String(parts.first!).subString(from: 1)
            parts.removeFirst()
        }
        
        // command is either a text string or a three digit numeric
        let command = Command(rawValue: String(parts.first!))
//        if let numericCommand = Int(command) {
//            // TODO
//        }
        
        parts.removeFirst()
        
        return IRCMessage(
            raw: message,
            prefix: prefix,
            command: command,
            parameters: parts.map{ String($0) })
    }
    
    private init(raw: String) {
        self.raw = raw
        self.parameters = []
    }
    
    private init(raw: String, prefix: String?, command: Command?, parameters: [String]?) {
        self.raw = raw
        self.prefix = prefix
        self.command = command
        self.parameters = parameters ?? []
    }
}
