//
//  InviteUserPopover.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 2/15/21.
//

import Introspect
import SwiftUI

// MARK: - View

/// A popover that prompts for a channel name for inviting new users.
struct InviteUserPopover: View {
    
    var mode: Mode
    var onInvite: (_ inviteTarget: String) -> Void
    @State private var inviteTarget: String = ""
    
    var body: some View {
        let leadingText: Text
        let placeholder: String
        
        // adjust the leading text to indicate what type of invitation is intended
        switch mode {
        case .inviteToChannel(let channelName):
            leadingText = Text("Invite another user to ") + Text(channelName).bold() + Text(".")
            placeholder = "(nick)"
        case .inviteUser(let nick):
            leadingText = Text("Invite ") + Text(nick).bold() + Text(" to a channel.")
            placeholder = "(channel)"
        }
        
        return VStack(alignment: .leading) {
            leadingText
            
            TextField(placeholder, text: $inviteTarget)
                .introspectTextField { $0.becomeFirstResponder() }
            
            HStack {
                Spacer()
                
                Button("Invite") {
                    onInvite(inviteTarget)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(inviteTarget.isEmptyOrWhitespace)
            }
            .frame(maxWidth: .infinity)
            
        }
        .padding()
        .frame(maxWidth: 300)
    }
}

// MARK: - View extensions
extension InviteUserPopover {
    
    enum Mode {
        case inviteToChannel(_ channelName: String)
        case inviteUser(_ nick: String)
    }
}

// MARK: - Preview
struct InviteUserPopover_Previews: PreviewProvider {
    
    static var previews: some View {
        InviteUserPopover(mode: .inviteUser("mike")) { _ in }
    }
}
