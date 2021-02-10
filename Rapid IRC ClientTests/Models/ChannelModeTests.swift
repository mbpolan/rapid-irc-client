//
//  ChannelModeTests.swift
//  Rapid IRC ClientTests
//
//  Created by Mike Polan on 2/9/21.
//

import XCTest
@testable import Rapid_IRC_Client

class ChannelModeTests: XCTestCase {
    
    func testApplyBansAdded() {
        // given a mode change that adds a ban
        let change = ChannelModeChange(from: "+b", modeArgs: ["mike"])
        
        let mode: ChannelMode = .default
        
        // when the change is applied
        let result = mode.apply(change)
        
        // then the new mode contains the newly added ban
        XCTAssertEqual(result.bans.count, 1)
        XCTAssertTrue(result.bans.contains("mike"))
    }
    
    func testApplyBansRemoved() {
        // given a mode change that removes a ban
        let change = ChannelModeChange(from: "-b", modeArgs: ["mike"])
        
        let mode: ChannelMode = ChannelMode(
            bans: Set(["mike", "piotr"]),
            exceptions: Set(),
            inviteExceptions: Set(),
            clientLimit: nil,
            inviteOnly: false,
            key: nil,
            moderated: false,
            protectedTopic: false,
            secret: false,
            noExternalMessages: false)
        
        // when the change is applied
        let result = mode.apply(change)
        
        // then the new mode does not contain the removed ban
        XCTAssertEqual(result.bans.count, 1)
        XCTAssertTrue(result.bans.contains("piotr"))
    }
    
    func testApplyExceptionsAdded() {
        // given a mode change that adds a ban exception
        let change = ChannelModeChange(from: "+e", modeArgs: ["mike"])
        
        let mode: ChannelMode = .default
        
        // when the change is applied
        let result = mode.apply(change)
        
        // then the new mode contains the newly added ban
        XCTAssertEqual(result.exceptions.count, 1)
        XCTAssertTrue(result.exceptions.contains("mike"))
    }
    
    func testApplyExceptionsRemoved() {
        // given a mode change that removes a ban exception
        let change = ChannelModeChange(from: "-e", modeArgs: ["mike"])
        
        let mode: ChannelMode = ChannelMode(
            bans: Set(),
            exceptions: Set(["mike", "piotr"]),
            inviteExceptions: Set(),
            clientLimit: nil,
            inviteOnly: false,
            key: nil,
            moderated: false,
            protectedTopic: false,
            secret: false,
            noExternalMessages: false)
        
        // when the change is applied
        let result = mode.apply(change)
        
        // then the new mode does not contain the removed exception
        XCTAssertEqual(result.exceptions.count, 1)
        XCTAssertTrue(result.exceptions.contains("piotr"))
    }
    
    func testApplyInviteExceptionsAdded() {
        // given a mode change that adds an invite exception
        let change = ChannelModeChange(from: "+I", modeArgs: ["mike"])
        
        let mode: ChannelMode = .default
        
        // when the change is applied
        let result = mode.apply(change)
        
        // then the new mode contains the newly added ban
        XCTAssertEqual(result.inviteExceptions.count, 1)
        XCTAssertTrue(result.inviteExceptions.contains("mike"))
    }
    
    func testApplyInviteExceptionsRemoved() {
        // given a mode change that removes an invite exception
        let change = ChannelModeChange(from: "-I", modeArgs: ["mike"])
        
        let mode: ChannelMode = ChannelMode(
            bans: Set(),
            exceptions: Set(),
            inviteExceptions: Set(["mike", "piotr"]),
            clientLimit: nil,
            inviteOnly: false,
            key: nil,
            moderated: false,
            protectedTopic: false,
            secret: false,
            noExternalMessages: false)
        
        // when the change is applied
        let result = mode.apply(change)
        
        // then the new mode does not contain the removed invite exception
        XCTAssertEqual(result.inviteExceptions.count, 1)
        XCTAssertTrue(result.inviteExceptions.contains("piotr"))
    }
    
    func testApplyClientLimitSet() {
        // given a mode change that sets a client limit
        let change = ChannelModeChange(from: "+l", modeArgs: ["5"])
        
        let mode: ChannelMode = ChannelMode(
            bans: Set(),
            exceptions: Set(),
            inviteExceptions: Set(),
            clientLimit: nil,
            inviteOnly: false,
            key: nil,
            moderated: false,
            protectedTopic: false,
            secret: false,
            noExternalMessages: false)
        
        // when the change is applied
        let result = mode.apply(change)
        
        // then the new mode contains a client limit
        XCTAssertEqual(result.clientLimit, 5)
    }
    
    func testApplyClientLimitChanged() {
        // given a mode change that sets a new client limit
        let change = ChannelModeChange(from: "+l", modeArgs: ["10"])
        
        let mode: ChannelMode = ChannelMode(
            bans: Set(),
            exceptions: Set(),
            inviteExceptions: Set(),
            clientLimit: 5,
            inviteOnly: false,
            key: nil,
            moderated: false,
            protectedTopic: false,
            secret: false,
            noExternalMessages: false)
        
        // when the change is applied
        let result = mode.apply(change)
        
        // then the new mode contains the new client limit
        XCTAssertEqual(result.clientLimit, 10)
    }
    
    func testApplyClientLimitRemoved() {
        // given a mode change that removes a new client limit
        let change = ChannelModeChange(from: "-l", modeArgs: ["10"])
        
        let mode: ChannelMode = ChannelMode(
            bans: Set(),
            exceptions: Set(),
            inviteExceptions: Set(),
            clientLimit: 10,
            inviteOnly: false,
            key: nil,
            moderated: false,
            protectedTopic: false,
            secret: false,
            noExternalMessages: false)
        
        // when the change is applied
        let result = mode.apply(change)
        
        // then the new mode does not contains the client limit
        XCTAssertNil(result.clientLimit)
    }
    
    func testApplyInviteOnlySet() {
        // given a mode change that sets the channel to invitations only
        let change = ChannelModeChange(from: "+i", modeArgs: [])
        
        let mode: ChannelMode = ChannelMode(
            bans: Set(),
            exceptions: Set(),
            inviteExceptions: Set(),
            clientLimit: nil,
            inviteOnly: false,
            key: nil,
            moderated: false,
            protectedTopic: false,
            secret: false,
            noExternalMessages: false)
        
        // when the change is applied
        let result = mode.apply(change)
        
        // then the new mode contains invitations only
        XCTAssertTrue(result.inviteOnly)
    }
    
    func testApplyInviteOnlyUnchanged() {
        // given a mode change that does not change a previously set invitation only mode
        let change = ChannelModeChange(from: "+X", modeArgs: [])
        
        let mode: ChannelMode = ChannelMode(
            bans: Set(),
            exceptions: Set(),
            inviteExceptions: Set(),
            clientLimit: nil,
            inviteOnly: true,
            key: nil,
            moderated: false,
            protectedTopic: false,
            secret: false,
            noExternalMessages: false)
        
        // when the change is applied
        let result = mode.apply(change)
        
        // then the new mode retains invitations only
        XCTAssertTrue(result.inviteOnly)
    }
    
    func testApplyInviteOnlyRemoved() {
        // given a mode change that removes invitation only mode
        let change = ChannelModeChange(from: "-i", modeArgs: [])
        
        let mode: ChannelMode = ChannelMode(
            bans: Set(),
            exceptions: Set(),
            inviteExceptions: Set(),
            clientLimit: nil,
            inviteOnly: true,
            key: nil,
            moderated: false,
            protectedTopic: false,
            secret: false,
            noExternalMessages: false)
        
        // when the change is applied
        let result = mode.apply(change)
        
        // then the new mode does not have invitation only mode
        XCTAssertFalse(result.inviteOnly)
    }
}
