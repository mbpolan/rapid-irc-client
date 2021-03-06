//
//  ChannelModeChange.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 2/4/21.
//

/// Describes a change to a channel mode.
///
/// This struct breaks down the individual mode flags and the changes to be applied on
/// a channel mode.
struct ChannelModeChange {
    
    var bansAdded: Set<String> = Set()
    var bansRemoved: Set<String> = Set()
    var exceptionsAdded: Set<String> = Set()
    var exceptionsRemoved: Set<String> = Set()
    var inviteExceptionsAdded: Set<String> = Set()
    var inviteExceptionsRemoved: Set<String> = Set()
    var privilegesAdded: [User.ChannelPrivilege: [String]] = [:]
    var privilegesRemoved: [User.ChannelPrivilege: [String]] = [:]
    var clientLimit: UnaryMode<Int>?
    var inviteOnly: Bool?
    var key: UnaryMode<String>?
    var moderated: Bool?
    var protectedTopic: Bool?
    var secret: Bool?
    var noExternalMessages: Bool?
}

// MARK: - ChannelModeChange extension
extension ChannelModeChange {
    
    /// Initializes a mode change by parsing an IRC MODE command mode string.
    ///
    /// - Parameter modeString: The raw mode string.
    /// - Parameter modeArgs: List of arguments for each flag that requires ones.
    init(from modeString: String, modeArgs: [String]) {
        var args = modeArgs
        var adding: Bool?
        
        modeString.forEach { char in
            let flag = ModeFlag(rawValue: char)
            
            switch flag {
            // add or remove banned client masks
            case .ban:
                if let adding = adding,
                   let mask = args.first {
                    
                    _ = adding ? bansAdded.insert(mask) : bansRemoved.insert(mask)
                    args = Array(args.dropFirst())
                }
                
            // add or remove ban-exempt client masks
            case .exception:
                if let adding = adding,
                   let mask = args.first {
                    
                    _ = adding ? exceptionsAdded.insert(mask) : exceptionsRemoved.insert(mask)
                    args = Array(args.dropFirst())
                }
                
            // set or remove a channel key
            case .key:
                if let adding = adding,
                   let keyValue = args.first {
                    
                    key = UnaryMode(added: adding, parameter: keyValue)
                    args = Array(args.dropFirst())
                }
                
            // set or remove a channel client limit
            case .clientLimit:
                if let adding = adding,
                   let keyValue = args.first {
                    
                    clientLimit = UnaryMode(added: adding, parameter: Int(keyValue))
                    args = Array(args.dropFirst())
                }
                
            // set or remove invite only mode
            case .inviteOnly:
                if let adding = adding {
                    inviteOnly = adding
                }
                
            // add or remove invite-exempt client masks
            case .inviteException:
                if let adding = adding,
                   let mask = args.first {
                    
                    _ = adding ? inviteExceptionsAdded.insert(mask) : inviteExceptionsRemoved.insert(mask)
                    args = Array(args.dropFirst())
                }
                
            // set or remove moderated mode
            case .moderated:
                if let adding = adding {
                    moderated = adding
                }
                
            // set or remove no external messages mode
            case .noExternalMessages:
                if let adding = adding {
                    noExternalMessages = adding
                }
                
            // set or remove secret mode
            case .secret:
                if let adding = adding {
                    secret = adding
                }
                
            // set or remove protected topic mode
            case .protectedTopic:
                if let adding = adding {
                    protectedTopic = adding
                }
                
            // set or revoke operator status
            case .operator:
                if let adding = adding,
                   let nick = args.first {
                    adding
                        ? privilegesAdded[User.ChannelPrivilege.fullOperator, default: []].append(nick)
                        : privilegesRemoved[User.ChannelPrivilege.fullOperator, default: []].append(nick)
                }
                
            // set or revoke half operator status
            case .halfOperator:
                if let adding = adding,
                   let nick = args.first {
                    adding
                        ? privilegesAdded[User.ChannelPrivilege.halfOperator, default: []].append(nick)
                        : privilegesRemoved[User.ChannelPrivilege.halfOperator, default: []].append(nick)
                }
                
            // set or revoke voiced status
            case .voice:
                if let adding = adding,
                   let nick = args.first {
                    adding
                        ? privilegesAdded[User.ChannelPrivilege.voiced, default: []].append(nick)
                        : privilegesRemoved[User.ChannelPrivilege.voiced, default: []].append(nick)
                }
                
            default:
                // is this an action operator instead?
                let action = ModeFlagAction(rawValue: char)
                switch action {
                // following mode flags are added
                case .add:
                    adding = true
                    
                // following mode flags are removed
                case .remove:
                    adding = false
                    
                default:
                    print("Ignoring unknown mode string character: \(char)")
                }
            }
        }
    }
    
    /// Computes a delta between two channel mode changes.
    ///
    /// This method will determine what mode flag changes are required to transition from the current
    /// mode change to the given `other`.
    ///
    /// - Parameter other: The other mode change to compare against.
    /// - Returns: A mode change that describes the transition.
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
    
    /// Converts the mode change into an actionable IRC MODE command mode string.
    ///
    /// A returned mode string that adds the invite only and protected topic flags, while removing
    /// the moderated and secret flags will look like this:
    /// ```
    /// +int-ms
    /// ```
    ///
    /// If the change requires arguments, such as adding a client limit, then the returned mode string
    /// will include the leading colon as necessary:
    /// ```
    /// +l :5
    /// ```
    ///
    /// - Returns: A formatted IRC MODE command mode string.
    func toModeString() -> String {
        var added: [ModeFlag] = []
        var addedParams: [String] = []
        var removed: [ModeFlag] = []
        var removedParams: [String] = []
        
        if !bansAdded.isEmpty {
            added.append(.ban)
            addedParams.append(contentsOf: bansAdded)
        }
        
        if !bansRemoved.isEmpty {
            removed.append(.ban)
            removedParams.append(contentsOf: bansRemoved)
        }
        
        if !exceptionsAdded.isEmpty {
            added.append(.exception)
            addedParams.append(contentsOf: exceptionsAdded)
        }
        
        if !exceptionsRemoved.isEmpty {
            removed.append(.exception)
            removedParams.append(contentsOf: exceptionsRemoved)
        }
        
        if !inviteExceptionsAdded.isEmpty {
            added.append(.inviteException)
            addedParams.append(contentsOf: inviteExceptionsAdded)
        }
        
        if !inviteExceptionsRemoved.isEmpty {
            removed.append(.inviteException)
            removedParams.append(contentsOf: inviteExceptionsRemoved)
        }
        
        if let clientLimit = clientLimit,
           let clientLimitParameter = clientLimit.parameter {
            if clientLimit.added {
                added.append(.clientLimit)
                addedParams.append(String(clientLimitParameter))
            } else {
                // do not include the parameter on removal of this mode
                removed.append(.clientLimit)
            }
        }
        
        if let key = key,
           let keyParameter = key.parameter {
            if key.added {
                added.append(.key)
                addedParams.append(keyParameter)
            } else {
                removed.append(.key)
                removedParams.append(keyParameter)
            }
        }
        
        if let inviteOnly = inviteOnly {
            inviteOnly
                ? added.append(.inviteOnly)
                : removed.append(.inviteOnly)
        }
        
        if let moderated = moderated {
            moderated
                ? added.append(.moderated)
                : removed.append(.moderated)
        }
        
        if let noExternalMessages = noExternalMessages {
            noExternalMessages
                ? added.append(.noExternalMessages)
                : removed.append(.noExternalMessages)
        }
        
        if let protectedTopic = protectedTopic {
            protectedTopic
                ? added.append(.protectedTopic)
                : removed.append(.protectedTopic)
        }
        
        if let secret = secret {
            secret
                ? added.append(.secret)
                : removed.append(.secret)
        }
        
        var modeString = ""
        
        // build the flag list for all added modes
        if !added.isEmpty {
            let addedModes = added.map { String($0.rawValue) }.joined()
            modeString = "+\(addedModes)"
        }
        
        // build the flag list for all removed modes
        if !removed.isEmpty {
            let removedModes = "-\(removed.map { String($0.rawValue) }.joined())"
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

// MARK: - ChannelModeChange structs
extension ChannelModeChange {
    
    /// Describes a channel mode that can be enabled or disabled with a parameter.
    struct UnaryMode<T>: Equatable where T: Equatable {
        let added: Bool
        let parameter: T?
    }
}
