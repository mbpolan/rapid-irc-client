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
}

extension ChannelModeChange {
    
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
    
    func delta(with other: ChannelModeChange) -> ChannelModeChange {
        return ChannelModeChange(
            bansAdded: self.bansAdded != other.bansAdded ? other.bansAdded : Set(),
            bansRemoved: self.bansRemoved != other.bansRemoved ? other.bansRemoved : Set(),
            exceptionsAdded: self.exceptionsAdded != other.exceptionsAdded ? other.exceptionsAdded : Set(),
            exceptionsRemoved: self.exceptionsRemoved != other.exceptionsRemoved ? other.exceptionsRemoved : Set(),
            inviteExceptionsAdded: self.inviteExceptionsAdded != other.inviteExceptionsAdded ? other.inviteExceptionsAdded : Set(),
            inviteExceptionsRemoved: self.inviteExceptionsRemoved != other.inviteExceptionsRemoved ? other.inviteExceptionsRemoved : Set(),
            privilegesAdded: [:],
            privilegesRemoved: [:],
            clientLimit: self.clientLimit != other.clientLimit ? other.clientLimit : nil,
            inviteOnly: self.inviteOnly != other.inviteOnly ? other.inviteOnly : nil,
            key: self.key != other.key ? other.key : nil,
            moderated: self.moderated != other.moderated ? other.moderated : nil,
            protectedTopic: self.protectedTopic != other.protectedTopic ? other.protectedTopic : nil,
            secret: self.secret != other.secret ? other.secret : nil,
            noExternalMessages: self.noExternalMessages != other.noExternalMessages ? other.noExternalMessages : nil)
    }
    
    func toModeString() -> String {
        var added: [String] = []
        var addedParams: [String] = []
        var removed: [String] = []
        var removedParams: [String] = []
        
        if !bansAdded.isEmpty {
            added.append("b")
            addedParams.append(contentsOf: bansAdded)
        }
        
        if !bansRemoved.isEmpty {
            removed.append("b")
            removedParams.append(contentsOf: bansRemoved)
        }
        
        if !exceptionsAdded.isEmpty {
            added.append("e")
            addedParams.append(contentsOf: exceptionsAdded)
        }
        
        if !exceptionsRemoved.isEmpty {
            removed.append("e")
            removed.append(contentsOf: exceptionsRemoved)
        }
        
        if !inviteExceptionsAdded.isEmpty {
            added.append("I")
            addedParams.append(contentsOf: inviteExceptionsAdded)
        }
        
        if !inviteExceptionsRemoved.isEmpty {
            removed.append("I")
            removed.append(contentsOf: inviteExceptionsRemoved)
        }
        
        if let clientLimit = clientLimit,
           let clientLimitParameter = clientLimit.parameter {
            if clientLimit.added {
                added.append("l")
                addedParams.append(String(clientLimitParameter))
            } else {
                removed.append("l")
                removedParams.append(String(clientLimitParameter))
            }
        }
        
        if let key = key,
           let keyParameter = key.parameter {
            if key.added {
                added.append("k")
                addedParams.append(keyParameter)
            } else {
                removed.append("k")
                removedParams.append(keyParameter)
            }
        }
        
        if let inviteOnly = inviteOnly {
            inviteOnly ? added.append("i") : removed.append("i")
        }
        
        if let moderated = moderated {
            moderated ? added.append("m") : removed.append("m")
        }
        
        if let noExternalMessages = noExternalMessages {
            noExternalMessages ? added.append("n") : removed.append("n")
        }
        
        if let protectedTopic = protectedTopic {
            protectedTopic ? added.append("t") : removed.append("t")
        }
        
        if let secret = secret {
            secret ? added.append("s") : removed.append("s")
        }
        
        var modeString = ""
        
        // build the flag list for all added modes
        if !added.isEmpty {
            modeString = "+\(added.joined())"
        }
        
        // build the flag list for all removed modes
        if !removed.isEmpty {
            let removedModes = "-\(removed.joined())"
            modeString = modeString.isEmpty ? removedModes : "\(modeString)\(removedModes)"
        }
        
        // append parameters, with those that correspond to added modes first
        let allParameters = addedParams + removedParams
        if !allParameters.isEmpty {
            modeString = "\(modeString) :\(allParameters.joined(separator: ","))"
        }
        
        return modeString
    }
}

extension ChannelModeChange {
    
    struct UnaryMode<T>: Equatable where T: Equatable {
        let added: Bool
        let parameter: T?
        
        func preferIfAdded(_ defaultValue: T?) -> T? {
            guard let parameter = parameter else { return defaultValue }
            return added ? parameter : defaultValue
        }
    }
}
