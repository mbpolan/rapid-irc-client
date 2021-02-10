//
//  ChannelModeChange.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 2/4/21.
//

struct ChannelModeChange {
    
    var bansAdded: Set<String> = Set()
    var bansRemoved: Set<String> = Set()
    var exceptionsAdded: Set<String> = Set()
    var exceptionsRemoved: Set<String> = Set()
    var inviteExceptionsAdded: Set<String> = Set()
    var inviteExceptionsRemoved: Set<String> = Set()
    var privilegesAdded: Dictionary<User.ChannelPrivilege, [String]> = [:]
    var privilegesRemoved: Dictionary<User.ChannelPrivilege, [String]> = [:]
    var clientLimit: UnaryMode<Int>? = nil
    var inviteOnly: Bool? = nil
    var key: UnaryMode<String>? = nil
    var moderated: Bool? = nil
    var protectedTopic: Bool? = nil
    var secret: Bool? = nil
    var noExternalMessages: Bool? = nil
    
    init(from modeString: String, modeArgs: [String]) {
        var args = modeArgs
        var adding: Bool? = nil
        
        modeString.forEach { ch in
            switch ch {
            // following mode flags are added
            case "+":
                adding = true
                
            // following mode flags are removed
            case "-":
                adding = false
                
            // add or remove banned client masks
            case "b":
                if let adding = adding,
                   let mask = args.first {
                    
                    _ = adding ? bansAdded.insert(mask) : bansRemoved.insert(mask)
                    args = Array(args.dropFirst())
                }
                
            // add or remove ban-exempt client masks
            case "e":
                if let adding = adding,
                   let mask = args.first {
                    
                    _ = adding ? exceptionsAdded.insert(mask) : exceptionsRemoved.insert(mask)
                    args = Array(args.dropFirst())
                }
                
            // set or remove a channel key
            case "k":
                if let adding = adding,
                   let keyValue = args.first {
                    
                    key = UnaryMode(added: adding, parameter: keyValue)
                    args = Array(args.dropFirst())
                }
                
            // set or remove a channel client limit
            case "l":
                if let adding = adding,
                   let keyValue = args.first {
                    
                    clientLimit = UnaryMode(added: adding, parameter: Int(keyValue))
                    args = Array(args.dropFirst())
                }
                
            // set or remove invite only mode
            case "i":
                if let adding = adding {
                    inviteOnly = adding
                }
                
            // add or remove invite-exempt client masks
            case "I":
                if let adding = adding,
                   let mask = args.first {
                    
                    _ = adding ? inviteExceptionsAdded.insert(mask) : inviteExceptionsRemoved.insert(mask)
                    args = Array(args.dropFirst())
                }
                
            // set or remove moderated mode
            case "m":
                if let adding = adding {
                    moderated = adding
                }
                
            // set or remove no external messages mode
            case "n":
                if let adding = adding {
                    noExternalMessages = adding
                }
                
            // set or remove secret mode
            case "s":
                if let adding = adding {
                    secret = adding
                }
                
            // set or remove protected topic mode
            case "t":
                if let adding = adding {
                    protectedTopic = adding
                }
                
            // set or revoke operator status
            case "o":
                if let adding = adding,
                   let nick = args.first {
                    adding
                        ? privilegesAdded[User.ChannelPrivilege.fullOperator, default: []].append(nick)
                        : privilegesRemoved[User.ChannelPrivilege.fullOperator, default: []].append(nick)
                }
                
            // set or revoke half operator status
            case "h":
                if let adding = adding,
                   let nick = args.first {
                    adding
                        ? privilegesAdded[User.ChannelPrivilege.halfOperator, default: []].append(nick)
                        : privilegesRemoved[User.ChannelPrivilege.halfOperator, default: []].append(nick)
                }
                
            // set or revoke voiced status
            case "v":
                if let adding = adding,
                   let nick = args.first {
                    adding
                        ? privilegesAdded[User.ChannelPrivilege.voiced, default: []].append(nick)
                        : privilegesRemoved[User.ChannelPrivilege.voiced, default: []].append(nick)
                }
                
            default:
                print("Ignoring unknown mode string character: \(ch)")
            }
        }
    }
}

extension ChannelModeChange {
    
    struct UnaryMode<T> {
        let added: Bool
        let parameter: T?
        
        func preferIfAdded(_ defaultValue: T?) -> T? {
            guard let parameter = parameter else { return defaultValue }
            return added ? parameter : defaultValue
        }
    }
}
