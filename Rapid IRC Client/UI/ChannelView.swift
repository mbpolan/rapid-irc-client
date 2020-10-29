//
//  ChannelView.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/23/20.
//

import SwiftUI

struct ChannelView: View {

    @EnvironmentObject var store: ConnectionsStore
    @State var line = ""

    var body: some View {
        let binding = Binding(
            get: { self.line },
            set: {
                self.line = $0
                print($0)
            })

        let connection = store.connections.first { conn in conn.id == store.currentConnection }
        let messageView = connection != nil ? MessageView(connection: connection!) : nil

        print("refreshing")

        return VStack {
            messageView
            HStack {
                TextField("", text: binding)
                Button("Send") {
                    NotificationCenter.default.post(
                        name: .sendMessage,
                        object: Message(connection: connection!, message: line))
                    
                    line = ""
                }
            }
        }
    }
}

struct ChannelView_Previews: PreviewProvider {
    static var previews: some View {
        ChannelView()
    }
}
