//
//  ChannelTopicSheet.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 2/15/21.
//

import SwiftUI

// MARK: - View

/// Sheet for editing a channel topic.
struct ChannelTopicSheet: View {
    
    private var initialTopic: String
    private var onClose: (_ result: Result) -> Void
    @State private var topic: String
    @State private var formDirty: Bool
    
    /// Initializes the sheet with an initial value.
    ///
    /// - Parameter topic: The initial channel topic
    /// - Parameter onClose: Closure to invoke when the sheet is dismissed.
    init(topic: String, onClose: @escaping(_ result: Result) -> Void) {
        self.initialTopic = topic
        self.onClose = onClose
        self._topic = .init(initialValue: topic)
        self._formDirty = .init(initialValue: false)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            TextField("(topic)", text: makeBinding(\.topic))
            
            Divider()
            
            HStack(alignment: .bottom) {
                Spacer()
                
                Button("Cancel") {
                    onClose(Result(accepted: false, topic: nil))
                }
                .keyboardShortcut(.cancelAction)
                
                Button("OK") {
                    onClose(Result(accepted: true, topic: topic))
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!formDirty)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
    }
    
    // returns a binding that updates the form status on change to a state property
    private func makeBinding<T>(_ key: ReferenceWritableKeyPath<ChannelTopicSheet, T>) -> Binding<T> {
        return Binding<T>(
            get: { self[keyPath: key] },
            set: { value in
                self[keyPath: key] = value
                self.updateFormDirty()
            })
    }
    
    private func updateFormDirty() {
        self.formDirty = initialTopic != topic
    }
}

// MARK: - ChannelTopicSheet extensions
extension ChannelTopicSheet {
    
    /// Represents the results of the user dismissing the sheet.
    struct Result {
        let accepted: Bool
        let topic: String?
    }
}

// MARK: - Preview
struct ChannelTopicSheet_Previews: PreviewProvider {
    static var previews: some View {
        ChannelTopicSheet(topic: "", onClose: { _ in })
    }
}
