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
    
    var body: some View {
        HSplitView {
            // display messages and channel activity on the left side
            VStack {
                if let topic = viewModel.state.currentChannel?.topic {
                    Text(topic)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        .border(SeparatorShapeStyle(), width: 1)
                        .layoutPriority(1)
                }
                
                MessageView(viewModel: MessageViewModel.viewModel(from: Store.instance))
                    .layoutPriority(2)
                
                HStack {
                    TextField("", text: $input, onCommit: {
                        submit()
                    })
                    Spacer()
                    Button("Send") {
                        submit()
                    }
                }.layoutPriority(1)
            }.layoutPriority(2)
            
            // display a list of users on the right side
            if viewModel.state.showUserList {
                List(sortUsers(viewModel.state.users)) { item in
                    Text(item.name)
                }.layoutPriority(1)
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
    
    private func submit() {
        if let channel = viewModel.state.currentChannel {
            viewModel.dispatch(.sendMessage(channel, input))
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
        let currentChannel: IRCChannel?
        let showUserList: Bool
        let users: Set<User>
        
        static var empty: ViewState {
            .init(
                currentChannel: nil,
                showUserList: false,
                users: [])
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
            currentChannel: currentChannel,
            showUserList: currentChannel != nil && currentChannel?.name != Connection.serverChannel,
            users: currentChannel?.users ?? Set())
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
                    host: "localhost",
                    port: 6667),
                store: store),
            name: "mike",
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
            currentChannel: channel,
            showUserList: true,
            users: channel.users)

        return ActiveChannelView(viewModel: viewModel)
    }
}
