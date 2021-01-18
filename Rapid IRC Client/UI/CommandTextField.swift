//
//  CommandTextField.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 1/18/21.
//

import AppKit
import Carbon.HIToolbox.Events
import SwiftUI

// specialized text field that allows inputting text messages and commands, and provides
// handlers for requesting history navigation
struct CommandTextField: NSViewRepresentable {
    
    @Binding var text: String
    var onPreviousHistory: () -> Void
    var onNextHistory: () -> Void
    var onCommit: () -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NativeCommandTextField {
        let view = NativeCommandTextField()
        view.parent = self
        view.isEditable = true
        view.focusRingType = .default
        view.delegate = context.coordinator
        view.font = NSFont.preferredFont(forTextStyle: .body)
        view.textColor = NSColor.labelColor
        
        return view
    }
    
    func updateNSView(_ nsView: NativeCommandTextField, context: Context) {
        nsView.string = text
    }
    
    func onTextEditingFinished() {
        onCommit()
    }
}

extension CommandTextField {
    
    class Coordinator: NSObject, NSTextViewDelegate {
        
        private var parent: CommandTextField
        
        init(_ parent: CommandTextField) {
            self.parent = parent
        }
        
        func textDidBeginEditing(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            self.parent.text = textView.string
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            self.parent.text = textView.string
        }
        
        func textDidEndEditing(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            self.parent.text = textView.string
        }
    }
}

final class NativeCommandTextField: NSTextView {
    
    var parent: CommandTextField? = nil
    
    override func keyDown(with event: NSEvent) {
        // handle key events, looking specifically for up/down arrow keys and
        // the return key itself
        switch Int(event.keyCode) {
        case kVK_UpArrow:
            parent?.onPreviousHistory()
        case kVK_DownArrow:
            parent?.onNextHistory()
        case kVK_Return:
            parent?.onTextEditingFinished()
        default:
            super.keyDown(with: event)
        }
    }
}
