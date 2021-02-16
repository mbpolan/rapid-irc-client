//
//  InviteUserPopover.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 2/15/21.
//

import SwiftUI

// MARK: - View

/// A popover that prompts for a channel name for inviting new users.
struct InviteUserPopover: View {
    
    var onInvite: (_ channelName: String) -> Void
    @State private var inviteChannel: String = ""
    
    var body: some View {
        VStack(alignment: .trailing) {
            TextField("(channel)", text: $inviteChannel)
                .frame(minWidth: 300)
            
            HStack(alignment: .lastTextBaseline) {
                Button("Invite") {
                    onInvite(inviteChannel)
                }
                .disabled(inviteChannel.isEmptyOrWhitespace)
            }
        }
        .padding()
    }
}

// MARK: - Preview
// swiftlint:disable type_name
struct InviteUserPopover_Preview: PreviewProvider {
    
    static var previews: some View {
        InviteUserPopover { _ in }
    }
}
