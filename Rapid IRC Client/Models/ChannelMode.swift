//
//  ChannelMode.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 2/9/21.
//

import Foundation

struct ChannelMode: Equatable {
    
    var bans: Set<String>
    var exceptions: Set<String>
    var inviteExceptions: Set<String>
    var clientLimit: Int?
    var inviteOnly: Bool
    var key: String?
    var moderated: Bool
    var protectedTopic: Bool
    var secret: Bool
    var noExternalMessages: Bool
    
    static var `default`: ChannelMode {
        return ChannelMode(
            bans: [],
            exceptions: [],
            inviteExceptions: [],
            clientLimit: nil,
            inviteOnly: false,
            key: nil,
            moderated: false,
            protectedTopic: false,
            secret: false,
            noExternalMessages: false)
    }
    
    func toModeChange() -> ChannelModeChange {
        return ChannelModeChange(
            bansAdded: bans,
            bansRemoved: Set(),
            exceptionsAdded: exceptions,
            exceptionsRemoved: Set(),
            inviteExceptionsAdded: inviteExceptions,
            inviteExceptionsRemoved: Set(),
            privilegesAdded: [:],
            privilegesRemoved: [:],
            clientLimit: ChannelModeChange.UnaryMode(added: clientLimit != nil, parameter: clientLimit),
            inviteOnly: inviteOnly,
            key: ChannelModeChange.UnaryMode(added: key != nil, parameter: key),
            moderated: moderated,
            protectedTopic: protectedTopic,
            secret: secret,
            noExternalMessages: noExternalMessages)
    }
    
    func apply(_ change: ChannelModeChange) -> ChannelMode {
        var clientLimit: Int? = self.clientLimit
        if let deltaClientLimit = change.clientLimit {
            clientLimit = deltaClientLimit.added ? deltaClientLimit.parameter : nil
        }
        
        var key: String? = self.key
        if let deltaKey = change.key {
            key = deltaKey.added ? deltaKey.parameter : nil
        }
        
        return ChannelMode(
            bans: (self.bans.subtracting(change.bansRemoved)).union(change.bansAdded),
            exceptions: (self.exceptions.subtracting(change.exceptionsRemoved)).union(change.exceptionsAdded),
            inviteExceptions: (self.inviteExceptions.subtracting(change.inviteExceptionsRemoved)).union(change.inviteExceptionsAdded),
            clientLimit: clientLimit,
            inviteOnly: change.inviteOnly ?? self.inviteOnly,
            key: key,
            moderated: change.moderated ?? self.moderated,
            protectedTopic: change.protectedTopic ?? self.protectedTopic,
            secret: change.secret ?? self.secret,
            noExternalMessages: change.noExternalMessages ?? self.noExternalMessages)
    }
}
