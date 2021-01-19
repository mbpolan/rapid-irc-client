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
    
    private let dateFormatter = { () -> DateFormatter in
        let format = DateFormatter()
        format.dateFormat = "HH:mm:ss"
        return format
    }()
    
    var body: some View {
        ScrollView {
            ScrollViewReader { scroll in
                LazyVStack(alignment: .leading) {
                    ForEach(viewModel.state.currentChannel?.messages ?? [], id: \.timestamp) { message in
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            if viewModel.state.showTimestamps {
                                Text("[\(dateFormatter.string(from: message.timestamp))] ")
                                    .foregroundColor(.secondary)
                                    .frame(alignment: .leading)
                            }
                            
                            makeMessage(message)
                                .frame(alignment: .leading)
                        }
                    }
                }
                .font(.system(size: 14, design: .monospaced))
                .onChange(of: viewModel.state) { _ in
                    guard let lastTimestamp = viewModel.state.currentChannel?.messages.last?.timestamp else { return }
                    scroll.scrollTo(lastTimestamp)
                }
            }
        }
    }
    
    private func makeMessage(_ message: ChannelMessage) -> Text {
        let text: Text
        let content = message.text
        
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
        case .userParted,
             .userQuit:
            text = Text(content)
                .foregroundColor(.yellow)
        case .error:
            text = Text(content)
                .foregroundColor(.red)
        case .channelTopicEvent:
            text = Text(content)
                .foregroundColor(.blue)
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
            // FIXME
            //            return lhs.currentChannel?.id == rhs.currentChannel?.id
            return false
        }
        
        let currentChannel: IRCChannel?
        let lastId: Date
        let showTimestamps: Bool
        
        static var empty: ViewState {
            .init(
                currentChannel: nil,
                lastId: Date(),
                showTimestamps: true)
        }
    }
    
    enum ViewAction {
    }
    
    private static func transform(viewAction: ViewAction) -> AppAction? {
        return nil
    }
    
    private static func transform(appState: AppState) -> ViewState {
        ViewState(
            currentChannel: appState.ui.currentChannel,
            lastId: appState.ui.currentChannel?.messages.last?.timestamp ?? Date(),
            showTimestamps: appState.ui.showTimestampsInChat)
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
                    realName: "Rapid User",
                    username: "user",
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
        
        return MessageView(viewModel: .mock(
                            state: .init(
                                currentChannel: channel,
                                lastId: Date(),
                                showTimestamps: true)))
    }
}
