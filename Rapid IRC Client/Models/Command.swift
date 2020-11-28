//
//  Commands.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/31/20.
//

enum Command {
    case join
    case part
    case ping
    case welcome
    case yourHost
    case created
    case myInfo
    case iSupport
    case statsLine
    case listUsers
    case listUserChannels
    case listUserMe
    case localUsers
    case globalUsers
    case nameReply
    case endOfNames
    case motd
    case serverMotd
    case endMotd
    
    case errorNoOrigin
}

extension Command {
    static func fromCode(code: String) -> Command? {
        switch code {
        case "001":
            return .welcome
        case "002":
            return .yourHost
        case "003":
            return .created
        case "004":
            return .myInfo
        case "005":
            return .iSupport
        case "250":
            return .statsLine
        case "251":
            return .listUsers
        case "254":
            return .listUserChannels
        case "255":
            return .listUserMe
        case "265":
            return .localUsers
        case "266":
            return .globalUsers
        case "353":
            return .nameReply
        case "366":
            return .endOfNames
        case "372":
            return .motd
        case "375":
            return .serverMotd
        case "376":
            return .endMotd
        case "409":
            return .errorNoOrigin
        default:
            return nil
        }
    }

    static func fromString(name: String) -> Command? {
        switch name.lowercased() {
        case "join":
            return .join
        case "ping":
            return .ping
        default:
            return nil
        }
    }
}
