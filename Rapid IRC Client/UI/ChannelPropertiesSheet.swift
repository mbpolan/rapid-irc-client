//
//  ChannelPropertiesSheet.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 2/12/21.
//

import SwiftUI

struct ChannelPropertiesSheet: View {
    
    private var initial: ChannelMode
    private var onClose: (_ result: Result) -> Void
    @State private var clientLimit: Bool = false
    @State private var clientLimitValue: String = ""
    @State private var inviteOnly: Bool = false
    @State private var key: Bool = false
    @State private var keyValue: String = ""
    @State private var moderated: Bool = false
    @State private var secret: Bool = false
    @State private var protected: Bool = false
    @State private var noExternalMessages: Bool = false
    @State private var formDirty: Bool = false
    
    init(initial: ChannelMode?,
         onCommit: @escaping(_ result: Result) -> Void) {
        
        self.initial = initial ?? .default
        self.onClose = onCommit
        self.clientLimit = initial?.clientLimit != nil
        self.clientLimitValue = String(initial?.clientLimit ?? 0)
        self.inviteOnly = initial?.inviteOnly ?? false
        self.key = initial?.key != nil
        self.keyValue = initial?.key ?? ""
        self.moderated = initial?.moderated ?? false
        self.secret = initial?.secret ?? false
        self.protected = initial?.protectedTopic ?? false
        self.noExternalMessages = initial?.noExternalMessages ?? false
    }
    
    var body: some View {
        Form {
            Section(header: Text("Common").font(.headline)) {
                Toggle(isOn: makeBinding(\.inviteOnly)) {
                    Text("Users must be invited before they can join")
                }
                
                Toggle(isOn: makeBinding(\.moderated)) {
                    Text("Only privileged users can send messages")
                }
                
                Toggle(isOn: makeBinding(\.protected)) {
                    Text("Only privileged users can change topic")
                }
                
                Toggle(isOn: makeBinding(\.secret)) {
                    Text("Hide channel from public lists")
                }
                
                Toggle(isOn: makeBinding(\.noExternalMessages)) {
                    Text("Users must be in the channel to send messages")
                }
            }
            
            Section(header: Text("Advanced").font(.headline)) {
                Toggle(isOn: makeBinding(\.key)) {
                    Text("Protect channel with a password")
                }
                
                SecureField("(password)", text: makeBinding(\.keyValue))
                    .disabled(!key)
                
                Toggle(isOn: makeBinding(\.clientLimit)) {
                    Text("Limit the amount of users who can join")
                }
                
                TextField("(limit)", text: makeBinding(\.clientLimitValue))
            }
            
            Divider()
            
            HStack(alignment: .lastTextBaseline) {
                Spacer()
                
                Button(action: {
                    onClose(Result(
                                accepted: false,
                                modeChange: nil))
                }) {
                    Text("Cancel")
                }
                .keyboardShortcut(.cancelAction)
                
                Button(action: {
                    // compute the current mode change, and compare it with the initial channel mode to
                    // come up with a delta
                    let currentModeChange = getModeChange()
                    let initialModeChange = initial.toModeChange()
                    let modeChange = initialModeChange.delta(with: currentModeChange)
                    
                    onClose(Result(
                                accepted: true,
                                modeChange: modeChange))
                }) {
                    Text("OK")
                }
                .disabled(!formDirty)
                .keyboardShortcut(.defaultAction)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
    }
    
    // returns a binding that updates the form status on change to a state property
    private func makeBinding<T>(_ key: ReferenceWritableKeyPath<ChannelPropertiesSheet, T>) -> Binding<T> {
        return Binding<T>(
            get: { self[keyPath: key] },
            set: { value in
                self[keyPath: key] = value
                self.updateFormDirty()
            })
    }
    
    private func getModeChange() -> ChannelModeChange {
        ChannelModeChange(
            bansAdded: Set(),
            bansRemoved: Set(),
            exceptionsAdded: Set(),
            exceptionsRemoved: Set(),
            inviteExceptionsAdded: Set(),
            inviteExceptionsRemoved: Set(),
            privilegesAdded: [:],
            privilegesRemoved: [:],
            clientLimit: ChannelModeChange.UnaryMode(added: self.clientLimit, parameter: Int(self.clientLimitValue)),
            inviteOnly: self.inviteOnly,
            key: ChannelModeChange.UnaryMode(added: self.key, parameter: self.keyValue),
            moderated: self.moderated,
            protectedTopic: self.protected,
            secret: self.secret,
            noExternalMessages: self.noExternalMessages)
    }
    
    private func updateFormDirty() {
        // compute the current mode changes, compare them against the initial mode
        let change = getModeChange()
        let newMode = initial.apply(change)
        
        formDirty = newMode != initial
    }
}

extension ChannelPropertiesSheet {
    
    struct Result {
        var accepted: Bool
        var modeChange: ChannelModeChange?
    }
}

struct ChannelPropertiesSheet_Previews: PreviewProvider {
    
    static var previews: some View {
        ChannelPropertiesSheet(
            initial: .default,
            onCommit: { _ in })
    }
}
