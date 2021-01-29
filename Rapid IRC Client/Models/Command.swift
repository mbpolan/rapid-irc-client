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
    case pong
    case privateMessage
    case notice
    case welcome
    case yourHost
    case created
    case myInfo
    case iSupport
    case statsLinkInfo
    case statsCommands
    case statsCLine
    case statsNLine
    case statsILine
    case statsKLine
    case statsYLine
    case endOfStats
    case userModeIs
    case statsLLine
    case statsUptime
    case statsOLine
    case statsLine
    case nick
    case listUsers
    case listOpsOnline
    case listUnknownConnections
    case listUserChannels
    case listUserMe
    case adminMe
    case adminLocation1
    case adminLocation2
    case adminEmail
    case tryAgain
    case localUsers
    case globalUsers
    case userIsAway
    case whoIsUser
    case whoIsServer
    case whoIsIdle
    case endOfWhoIs
    case endOfWhoIsChannels
    case channelListStart
    case channelList
    case channelListEnd
    case channelModes
    case channelCreationTime
    case topicReply
    case topicChanged
    case topicSetByWhen
    case version
    case nameReply
    case endOfNames
    case info
    case motd
    case endOfInfo
    case serverMotd
    case endMotd
    case youreOperator
    case time
    case mode
    case quit
    
    case error
    case errorGeneral
    case errorNoOrigin
    case errorNickInUse
    case errorNeedMoreParams
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
        case "211":
            return .statsLinkInfo
        case "212":
            return .statsCommands
        case "213":
            return .statsCLine
        case "214":
            return .statsNLine
        case "215":
            return .statsILine
        case "216":
            return .statsKLine
        case "218":
            return statsYLine
        case "219":
            return .endOfStats
        case "221":
            return .userModeIs
        case "241":
            return .statsLLine
        case "242":
            return .statsUptime
        case"243":
            return .statsOLine
        case "250":
            return .statsLine
        case "251":
            return .listUsers
        case "252":
            return .listOpsOnline
        case "253":
            return .listUnknownConnections
        case "254":
            return .listUserChannels
        case "255":
            return .listUserMe
        case "256":
            return .adminMe
        case "257":
            return .adminLocation1
        case "258":
            return .adminLocation2
        case "259":
            return .adminEmail
        case "263":
            return .tryAgain
        case "265":
            return .localUsers
        case "266":
            return .globalUsers
        case "301":
            return .userIsAway
        case "311":
            return .whoIsUser
        case "312":
            return .whoIsServer
        case "317":
            return .whoIsIdle
        case "318":
            return .endOfWhoIs
        case "319":
            return .endOfWhoIsChannels
        case "321":
            return .channelListStart
        case "322":
            return .channelList
        case "323":
            return .channelListEnd
        case "324":
            return .channelModes
        case "329":
            return .channelCreationTime
        case "332":
            return .topicReply
        case "333":
            return .topicSetByWhen
        case "351":
            return .version
        case "353":
            return .nameReply
        case "366":
            return .endOfNames
        case "371":
            return .info
        case "372":
            return .motd
        case "374":
            return .endOfInfo
        case "375":
            return .serverMotd
        case "376":
            return .endMotd
        case "381":
            return .youreOperator
        case "391":
            return .time
        case "409":
            return .errorNoOrigin
        case "433":
            return .errorNickInUse
        case "461":
            return .errorNeedMoreParams
        default:
            // is this an error message that we don't specifically handle?
            if let numeric = Int(code), numeric >= 400, numeric <= 599 {
                return .errorGeneral
            }
            
            return nil
        }
    }

    static func fromString(name: String) -> Command? {
        switch name.lowercased() {
        case "join":
            return .join
        case "part":
            return .part
        case "ping":
            return .ping
        case "pong":
            return .pong
        case "privmsg":
            return .privateMessage
        case "notice":
            return .notice
        case "topic":
            return .topicChanged
        case "mode":
            return .mode
        case "quit":
            return .quit
        case "nick":
            return .nick
        case "error":
            return .error
        default:
            return nil
        }
    }
}
