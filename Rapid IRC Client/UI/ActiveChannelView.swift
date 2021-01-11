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
                    Button("OK") {
                        submit()
                    }
                }.layoutPriority(1)
            }.layoutPriority(2)
            
            // display a list of users on the right side
//            if channel != nil && channel!.name != Connection.serverChannel {
//                List(sortUsers(channel!.users)) { item in
//                    Text(item.name)
//                }.layoutPriority(1)
//            }
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
//        let channel = store.state.ui.currentChannel == nil ? nil : store.state.connections.channelUuids[store.state.ui.currentChannel!]
//        
//        if channel != nil {
//            store.dispatch(action: MessageSentAction(
//                            connection: channel!.connection.client,
//                            message: input,
//                            channel: channel!.id))
//        }
//        
//        input = ""
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
//
//struct ActiveChannelView_Previews: PreviewProvider {
//    static var previews: some View {
//        let store = Store(
//            reducer: { state, action in
//                return state
//            },
//            state: AppState(
//                connections: ConnectionsState(
//                    connections: [],
//                    channelUuids: [:]),
//                ui: UIState(
//                    currentChannel: "123")))
//
//        let channel = IRCChannel(
//            connection: Connection(
//                name: "mike",
//                client: ServerConnection(
//                    server: ServerInfo(
//                        nick: "mike",
//                        host: "localhost",
//                        port: 6667),
//                    store: store)),
//            name: "mike",
//            state: .joined)
//
//        channel.topic = "some topic message for this channel"
//
//        channel.users.insert(User(
//                                name: "mike",
//                                privilege: nil))
//
//        channel.users.insert(User(
//                                name: "piotr",
//                                privilege: .voiced))
//
//        channel.users.insert(User(
//                                name: "jase",
//                                privilege: .fullOperator))
//
//        store.state.connections.channelUuids["123"] = channel
//
//        return ActiveChannelView()
//            .environmentObject(store)
//    }
//}
