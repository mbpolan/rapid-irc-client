//
//  MessageView.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/28/20.
//

import CombineRex
import SwiftRex
import SwiftUI

struct MessageView: View {
    
    @ObservedObject var viewModel: ObservableViewModel<MessageViewModel.ViewAction, MessageViewModel.ViewState>
    
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
        if viewModel.state.currentChannel == nil {
            return Text("")
        }

        var text = Text("")

        if let channel = viewModel.state.currentChannel {
            for message in channel.messages {
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

enum MessageViewModel {
    
    static func viewModel<S: StoreType>(from store: S) -> ObservableViewModel<ViewAction, ViewState> where S.ActionType == AppAction, S.StateType == AppState {
        store.projection(
            action: transform(viewAction:),
            state: transform(appState:)
        ).asObservableViewModel(initialState: .empty)
    }

    struct ViewState: Equatable {
        static func == (lhs: MessageViewModel.ViewState, rhs: MessageViewModel.ViewState) -> Bool {
            return lhs.currentChannel?.id == rhs.currentChannel?.id
        }
        
        let currentChannel: IRCChannel?
        
        static var empty: ViewState {
            .init(currentChannel: nil)
        }
    }

    enum ViewAction {
    }
    
    private static func transform(viewAction: ViewAction) -> AppAction? {
        return nil
    }
    
    private static func transform(appState: AppState) -> ViewState {
        ViewState(
            currentChannel: appState.ui.currentChannel)
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        let store = Store()
        
        let channel = IRCChannel(
            connection: Connection(
                name: "mike",
                serverInfo: ServerInfo(
                    nick: "mike",
                    host: "localhost",
                    port: 6667),
                store: store),
            name: "mike",
            state: .joined)

        channel.messages.append(contentsOf: [
            ChannelMessage(sender: "jase", text: "hey gyus", variant: .privateMessage),
            ChannelMessage(sender: "mike", text: "a somewhat long message to text this situation", variant: .privateMessage),
            ChannelMessage(text: "jun has joined #mike", variant: .userJoined),
            ChannelMessage(text: "piotr has left #mike", variant: .userParted),
        ])
        
        let viewModel = MessageViewModel.viewModel(from: store)
        viewModel.state = MessageViewModel.ViewState(currentChannel: channel)

        return MessageView(viewModel: viewModel)
    }
}
