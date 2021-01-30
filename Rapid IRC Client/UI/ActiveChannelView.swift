//
//  ActiveChannelView.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/28/20.
//

import CombineRex
import SwiftRex
import SwiftUI

struct ActiveChannelView: View {
    
    @ObservedObject var viewModel: ObservableViewModel<ActiveChannelViewModel.ViewAction, ActiveChannelViewModel.ViewState>
    @State private var input: String = ""
    @State private var history: [String] = []
    @State private var historyIndex = -1
    
    var body: some View {
        HSplitView {
            // display messages and channel activity on the left side
            VStack {
                if let channelTopic = viewModel.state.topic {
                    FormattedText(channelTopic)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        .border(SeparatorShapeStyle(), width: 1)
                        .layoutPriority(1)
                }
                
                MessageView(viewModel: MessageViewModel.viewModel(from: Store.instance))
                    .layoutPriority(2)
                
                Divider()
                
                HStack(alignment: .center) {
                    CommandTextField(
                        text: $input,
                        onPreviousHistory: setPreviousHistory,
                        onNextHistory: setNextHistory,
                        onCommit: submit)
                    
                    Spacer()
                    
                    Button(action: submit) {
                        Image(systemName: "paperplane.fill")
                    }
                }
                .padding(3)
                .layoutPriority(1)
            }.layoutPriority(2)
            
            // display a list of users on the right side, unless we are currently in the server channel
            if viewModel.state.showUserList {
                UserListView(viewModel: UserListViewModel.viewModel(from: Store.instance))
                    .layoutPriority(1)
            }
        }
    }
    
    private func sortUsers(_ users: Set<User>) -> [User] {
        return users.sorted(by: { (a, b) -> Bool in
            let aOrdinal = a.privilege?.ordinal() ?? 0
            let bOrdinal = b.privilege?.ordinal() ?? 0
            
            return aOrdinal > bOrdinal
        })
    }
    
    private func setPreviousHistory() {
        // if there is text in our previous history, push it to the text field
        if historyIndex < history.count - 1 {
            let previous = historyIndex + 1
            
            historyIndex += 1
            input = history[previous]
        }
    }
    
    private func setNextHistory() {
        if historyIndex > 0 {
            // if there is text in our recent history, push it to the text field
            let next = historyIndex - 1
            
            historyIndex -= 1
            input = history[next]
        } else {
            // the user has reached the beginning of history; reset the text field and history index
            input = ""
            historyIndex = -1
        }
    }
    
    private func submit() {
        if let channel = viewModel.state.currentChannel, !input.isEmpty {
            viewModel.dispatch(.sendMessage(channel, input))
            
            // push the current text to our history and reset the history index
            history.insert(input, at: 0)
            historyIndex = -1
            input = ""
        }
    }
}

enum ActiveChannelViewModel {
    
    static func viewModel<S: StoreType>(from store: S) -> ObservableViewModel<ViewAction, ViewState> where S.ActionType == AppAction, S.StateType == AppState {
        store.projection(
            action: transform(viewAction:),
            state: transform(appState:)
        ).asObservableViewModel(initialState: .empty)
    }
    
    struct ViewState: Equatable {
        let topic: String?
        let currentChannel: IRCChannel?
        let showUserList: Bool
        
        static var empty: ViewState {
            .init(
                topic: nil,
                currentChannel: nil,
                showUserList: false)
        }
    }
    
    enum ViewAction {
        case sendMessage(IRCChannel, String)
    }
    
    private static func transform(viewAction: ViewAction) -> AppAction? {
        switch viewAction {
        case .sendMessage(let channel, let message):
            return .network(
                .messageSent(
                    channel: channel,
                    rawMessage: message))
        }
    }
    
    private static func transform(appState: AppState) -> ViewState {
        let currentChannel = appState.ui.currentChannel
        
        return ViewState(
            topic: currentChannel?.topic,
            currentChannel: currentChannel,
            showUserList: currentChannel?.descriptor == .multiUser)
    }
}

struct ActiveChannelView_Previews: PreviewProvider {
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
            descriptor: .multiUser,
            state: .joined)
        
        channel.topic = "some topic message for this channel"
        
        channel.users.insert(User(
                                name: "mike",
                                privilege: nil))
        
        channel.users.insert(User(
                                name: "piotr",
                                privilege: .voiced))
        
        channel.users.insert(User(
                                name: "jase",
                                privilege: .fullOperator))
        
        let viewModel = ActiveChannelViewModel.viewModel(from: store)
        viewModel.state = ActiveChannelViewModel.ViewState(
            topic: "some topic",
            currentChannel: channel,
            showUserList: true)
        
        return ActiveChannelView(viewModel: viewModel)
    }
}
