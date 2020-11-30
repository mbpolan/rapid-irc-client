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
        GeometryReader { geo in
            ScrollView {
                HStack {
                    VStack(alignment: .leading) {
                        makeText()
                    }
                    .frame(width: geo.size.width, alignment: .topLeading)
                    .padding(EdgeInsets(
                                top: 0,
                                leading: 5.0,
                                bottom: 0,
                                trailing: -10.0))
                    
                    Spacer()
                }
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
                text = text + makeMessage(message)
            }
        }
        
        return text.font(.system(size: 14, design: .monospaced))
    }
    
    private func makeMessage(_ message: ChannelMessage) -> Text {
        let text: Text
        let content = "\(message.text)\n"
        
        switch message.variant {
        case .privateMessage:
            if let sender = message.sender {
                text = Text("<\(sender)>") + Text(" \(content)")
            } else {
                text = Text(content)
            }
        case .userJoined:
            text = Text(content)
                .foregroundColor(.green)
        case .userParted:
            text = Text(content)
                .foregroundColor(.yellow)
        case .error:
            text = Text(content)
                .foregroundColor(.red)
        case .other:
            text = Text(content)
        }
        
        return text
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        let store = Store(
            reducer: { state, action in
                return state
            },
            state: AppState(
                connections: ConnectionsState(
                    connections: [],
                    channelUuids: [:]),
                ui: UIState(
                    currentChannel: "123")))
        
        let channel = IRCChannel(
            connection: Connection(
                name: "mike",
                client: ServerConnection(
                    server: ServerInfo(
                        nick: "mike",
                        host: "localhost",
                        port: 6667),
                    store: store)),
            name: "mike",
            state: .joined)
        
        channel.messages.append(contentsOf: [
            ChannelMessage(sender: "jase", text: "hey gyus", variant: .privateMessage),
            ChannelMessage(sender: "mike", text: "a somewhat long message to text this situation", variant: .privateMessage),
            ChannelMessage(text: "jun has joined #mike", variant: .userJoined),
            ChannelMessage(text: "piotr has left #mike", variant: .userParted),
        ])
        
        store.state.connections.channelUuids["123"] = channel
        
        return MessageView()
            .environmentObject(store)
    }
}
