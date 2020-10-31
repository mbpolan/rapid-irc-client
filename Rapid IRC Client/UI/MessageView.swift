//
//  MessageView.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/28/20.
//

import SwiftUI

struct MessageView: View {
    
    @EnvironmentObject var store: Store
    
    var body: some View {
        ScrollView {
            makeText()
        }
    }
    
    private func makeText() -> some View {
        if store.state.connections.current == -1 {
            print("no connection")
            return Text("")
        }
        
        let connection = store.state.connections.connections[store.state.connections.current]
        var text = Text("")
        
        for message in connection.messages {
            text = text + Text(message)
        }
        
        return text
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        MessageView()
    }
}
