//
//  CTCPCommand.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 1/22/21.
//

enum CTCPCommand {
    case action
    case version
}

extension CTCPCommand {
    
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
