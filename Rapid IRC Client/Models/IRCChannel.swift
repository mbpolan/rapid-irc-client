//
//  Mesages.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/25/20.
//

import Combine
import SwiftUI

class IRCChannel: ObservableObject, Identifiable {
    
    let id = UUID()
    @Published var messages: [String] = []
    
    func addMessage(_ message: String) {
        messages.append(message)
        objectWillChange.send()
    }
}
