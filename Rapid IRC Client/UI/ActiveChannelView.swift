//
//  ActiveChannelView.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/28/20.
//

import SwiftUI

struct ActiveChannelView: View {

    @EnvironmentObject var store: Store
    @State private var input: String = ""

    var body: some View {
        let channel = store.state.ui.currentChannel == nil ? nil : store.state.connections.channelUuids[store.state.ui.currentChannel!]
        
        HSplitView {
            // display messages and channel activity on the left side
            VStack {
                MessageView()
                HStack {
                    TextField("", text: $input, onCommit: {
                        submit()
                    })
                    Spacer()
                    Button("OK") {
                        submit()
                    }
                }
            }.layoutPriority(2)
            
            // display a list of users on the right side
            
            if channel != nil && channel!.name != Connection.serverChannel {
                List(channel!.users) { item in
                    Text(item.name)
                }.layoutPriority(1)
            }
        }
    }
    
    private func submit() {
        let channel = store.state.ui.currentChannel == nil ? nil : store.state.connections.channelUuids[store.state.ui.currentChannel!]
        
        if channel != nil {
            store.dispatch(action: MessageSentAction(
                            connection: channel!.connection.client,
                            message: input,
                            channel: channel!.id))
        }
        
        input = ""
    }
}

struct ActiveChannelView_Previews: PreviewProvider {
    static var previews: some View {
        ActiveChannelView()
    }
}
