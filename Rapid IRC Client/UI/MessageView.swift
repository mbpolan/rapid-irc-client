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
            HStack {
                VStack(alignment: .leading) {
                    makeText()
                }
                Spacer()
            }
        }
    }
    
    private func makeText() -> some View {
        if store.state.ui.currentChannel == nil {
            return Text("")
        }
        
        var text = Text("")
        
        let channel = store.state.connections.channelUuids[store.state.ui.currentChannel ?? ""]
        if channel == nil {
            print("ERROR: no channel with UUID \(String(describing: store.state.ui.currentChannel))")
        } else {
            for message in channel!.messages {
                text = text + Text("\(message.text)\n")
            }
        }
        
        return text.font(.system(size: 14, design: .monospaced))
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        MessageView()
    }
}
