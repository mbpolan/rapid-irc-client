//
//  KickUserPopover.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 2/15/21.
//

import Introspect
import SwiftUI

// MARK: - View

/// A popover that prompts for a reason before kicking a user.
struct KickUserPopover: View {
    
    var onKick: (_ reason: String?) -> Void
    @State private var kickReason: String = ""
    
    var body: some View {
        VStack(alignment: .trailing) {
            TextField("(reason)", text: $kickReason)
                .introspectTextField { $0.becomeFirstResponder() }
            
            HStack {
                Spacer()
                
                Button("Kick") {
                    onKick(kickReason.isEmptyOrWhitespace ? .none : kickReason)
                }
                .keyboardShortcut(.defaultAction)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .frame(minWidth: 300)
    }
}

// MARK: - Preview
struct KickUserPopover_Previews: PreviewProvider {
    
    static var previews: some View {
        KickUserPopover { _ in }
    }
}
