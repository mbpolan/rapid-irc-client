//
//  MessageView.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/25/20.
//

import SwiftUI

struct MessageView: View {
    
    @ObservedObject var connection: ServerConnection
    
    var body: some View {
        var messages = Text("")
        for message in connection.serverChannel.messages {
            messages = messages + Text(message)
        }
        
        return ScrollView {
            messages
        }
    }
}
