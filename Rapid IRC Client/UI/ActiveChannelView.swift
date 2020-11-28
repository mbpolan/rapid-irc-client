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
            if store.state.ui.currentChannel != nil && store.state.ui.currentChannel?.name != Connection.serverChannel {
                List(store.state.ui.currentChannel!.users) { item in
                    Text(item.name)
                }.layoutPriority(1)
            }
        }
    }
    
    private func submit() {
        store.dispatch(action: MessageSentAction(message: input))
        input = ""
    }
}

struct ActiveChannelView_Previews: PreviewProvider {
    static var previews: some View {
        ActiveChannelView()
    }
}
