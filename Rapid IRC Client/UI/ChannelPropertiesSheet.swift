//
//  ChannelPropertiesSheet.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 2/12/21.
//

import SwiftUI

// MARK: - View

/// Sheet that presents a set of channel mode properties that can be modified.
struct ChannelPropertiesSheet: View {
    
    private var initial: ChannelMode
    private var onClose: (_ result: Result) -> Void
    @State private var clientLimit: Bool
    @State private var clientLimitValue: String
    @State private var inviteOnly: Bool
    @State private var key: Bool
    @State private var keyValue: String
    @State private var moderated: Bool
    @State private var secret: Bool
    @State private var protected: Bool
    @State private var noExternalMessages: Bool
    @State private var formDirty: Bool = false
    
    /// Initializes a sheet with the given initial set of properties.
    ///
    /// - Parameter initial: The initial channel mode.
    /// - Parameter onCommit: Closure to invoke when the sheet is closed.
    init(initial: ChannelMode,
         onCommit: @escaping(_ result: Result) -> Void) {
        
        self.initial = initial
        self.onClose = onCommit
        
        // initialize state properties based on the initial channel mode
        self._clientLimit = .init(initialValue: initial.clientLimit != nil)
        self._clientLimitValue = .init(initialValue: String(initial.clientLimit ?? 0))
        self._inviteOnly = .init(initialValue: initial.inviteOnly)
        self._key = .init(initialValue: initial.key != nil)
        self._keyValue = .init(initialValue: initial.key ?? "")
        self._moderated = .init(initialValue: initial.moderated)
        self._secret = .init(initialValue: initial.secret)
        self._protected = .init(initialValue: initial.protectedTopic)
        self._noExternalMessages = .init(initialValue: initial.noExternalMessages)
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
                    .disabled(!clientLimit)
            }
            
            Divider()
            
            HStack(alignment: .lastTextBaseline) {
                Spacer()
                
                Button("Cancel") {
                    onClose(Result(
                                accepted: false,
                                modeChange: nil))
                }
                .keyboardShortcut(.cancelAction)
                
                Button("OK") {
                    // compute the current mode change, and compare it with the initial channel mode to
                    // come up with a delta
                    let currentModeChange = getModeChange()
                    let initialModeChange = initial.toModeChange()
                    let modeChange = initialModeChange.delta(with: currentModeChange)
                    
                    onClose(Result(
                                accepted: true,
                                modeChange: modeChange))
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
            clientLimit: ChannelModeChange.UnaryMode(
                added: self.clientLimit,
                parameter: self.clientLimit ? Int(self.clientLimitValue) : self.initial.clientLimit),
            inviteOnly: self.inviteOnly,
            key: ChannelModeChange.UnaryMode(
                added: self.key,
                parameter: self.key ? self.keyValue : self.initial.key),
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

// MARK: - View extensions
extension ChannelPropertiesSheet {
    
    /// Represents the results of the user dismissing the sheet.
    struct Result {
        var accepted: Bool
        var modeChange: ChannelModeChange?
    }
}

// MARK: - Preview
struct ChannelPropertiesSheet_Previews: PreviewProvider {
    
    static var previews: some View {
        var initial = ChannelMode.default
        initial.moderated = true
        
        return ChannelPropertiesSheet(
            initial: initial,
            onCommit: { _ in })
    }
}
