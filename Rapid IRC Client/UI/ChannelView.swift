//
//  ChannelView.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/23/20.
//

import SwiftUI

struct ChannelView: View {
    
    @EnvironmentObject var store: ConnectionsStore
    @State private var line = ""
    @State private var flag: Bool = false
    @State private var messageViews = [UUID: MessageView]()
    
    var body: some View {
        let binding = Binding(
            get: { self.line },
            set: {
                self.line = $0
                print($0)
            })
        
        var messageView: MessageView?
        if store.currentConnection != nil {
            let connection = store.connections.first { conn in conn.id == store.currentConnection }!
            messageView = self.messageViews[store.currentConnection!]
            
            if messageView == nil {
                print("added new view")
                messageView = MessageView(connection: connection)
                
                // FIXME: update during state change
                messageViews[store.currentConnection!] = messageView
            }
        }
        
        print("refreshing")
        
        return VStack(alignment: .leading, spacing: nil, content: {
            ScrollView {
                VStack {
                    messageView
                }
            }
            HStack {
                TextField("", text: binding)
                Button("OK") {
                    
                }
            }
        })
    }
}

struct ChannelView_Previews: PreviewProvider {
    static var previews: some View {
        ChannelView()
    }
}
