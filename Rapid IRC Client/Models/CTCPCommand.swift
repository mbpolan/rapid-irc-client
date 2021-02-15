//
//  CTCPCommand.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 1/22/21.
//

/// Enumeration of supported client-to-client protocol (CTCP) commands.
enum CTCPCommand {
    case action
    case version
}

// MARK: - CTCPCommand helper functions
extension CTCPCommand {
    
    /// Parses a CTCP command from an IRC message.
    ///
    /// - Parameter name: The IRC string.
    /// - Returns: A CTCPCommand, or nil if none were matched.
    static func fromString(name: String) -> CTCPCommand? {
        switch name.lowercased() {
        case "action":
            return .action
        case "version":
            return .version
        default:
            return nil
        }
    }
}
