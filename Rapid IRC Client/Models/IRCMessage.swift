//
//  IRCMessage.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/31/20.
//

import SwiftUI

/// An IRC message received from a server.
///
/// This struct describes the entirety of a message sent by an IRC server to an IRC client.
/// The data included encapsulates the message prefix, the command, the receiver of a command, and
/// zero or more parameters to satisfy the command.
///
/// See the RFC for more information: https://tools.ietf.org/html/rfc1459#section-2.3.1
struct IRCMessage {
    
    var raw: String
    var prefix: Prefix?
    var command: Command?
    var target: String?
    var parameters: [String] = []
    var timestamp: Date
    
    /// Parses a raw IRC message and extracts the various components from it.
    ///
    /// - Parameter message: The raw message.
    init(from message: String) {
        var parts = message.components(separatedBy: " ")
        
        // no-op
        if parts.isEmpty {
            self.raw = message
            self.timestamp = Date()
            return
        }
        
        // prefix is optional, but if it exists, it's always lead by a colon
        var prefix: Prefix?
        if parts.first!.starts(with: ":") {
            prefix = Prefix(String(parts.first!).subString(from: 1))
            parts.removeFirst()
        }
        
        // command is either a text string or a three digit numeric
        let rawCommand = String(parts.first!).lowercased()
        let command = rawCommand.isNumber ? Command.fromCode(code: rawCommand) : Command.fromString(name: rawCommand)
        
        parts.removeFirst()
        
        // extract the parameters
        var parameters = parts.map { String($0) }
        
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

// MARK: - IRCMessage structs
extension IRCMessage {
    
    /// The prefix part of an IRC message.
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
        
        /// Returns an IRC message prefix with the given subject.
        ///
        /// - Parameter subject: The new subject.
        /// - Returns: The current prefix with the newly provided subject.
        func withSubject(_ subject: String) -> IRCMessage.Prefix {
            return IRCMessage.Prefix(
                raw: self.raw.replacingOccurrences(of: self.subject, with: subject),
                subject: subject,
                user: self.user,
                host: self.host)
        }
    }
}

// MARK: - IRCMessage.Prefix helper functions
extension IRCMessage.Prefix {
    
    /// Parses a raw IRC message and extracts the prefix.
    ///
    /// - Parameter raw: The raw message.
    init(_ raw: String) {
        self.raw = raw
        
        // check for presence of ! separator
        if let exIndex = raw.range(of: "!") {
            self.subject = String(raw[..<exIndex.lowerBound])
            let network = raw[exIndex.upperBound...]
            
            // check for presence of @ separator
            if let atIndex = network.range(of: "@") {
                self.user = String(network[..<atIndex.lowerBound])
                self.host = String(network[atIndex.upperBound...])
            } else {
                self.user = String(network)
                self.host = nil
            }
        } else {
            self.subject = raw
            self.user = nil
            self.host = nil
        }
    }
    
}
