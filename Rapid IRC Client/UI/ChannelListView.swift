//
//  ChannelListView.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/28/20.
//

import SwiftUI
import CombineRex
import SwiftRex

struct ChannelListView: View {
    
    @ObservedObject var viewModel: ObservableViewModel<ChannelListViewModel.ViewAction, ChannelListViewModel.ViewState>
    
    @State var connection = 0 {
        didSet {
            print("SET \(connection)")
        }
    }

    var body: some View {
        VStack {
            makeList()
        }
    }

    private func makeList() -> some View {
        var model = viewModel.state.connections.map { conn in
            return ListItem(
                id: conn.getServerChannel()!.id,
                name: conn.name,
                channelName: Connection.serverChannel,
                active: true,
                connection: conn,
                type: .server,
                children: conn.channels
                    .map { chan in
                        return ListItem(
                            id: chan.id,
                            name: chan.name,
                            channelName: chan.name,
                            active: chan.state == .joined,
                            connection: conn,
                            type: .channel,
                            children: nil)
                    })
        }
        
        // workaround for when the list is initially empty. if we do not explicitly set a node with a child,
        // the list will never show children after the fact.
        if model.count == 0 {
            model = [
                ListItem(id: "", name: "", channelName: "empty", active: false, connection: nil, type: .server, children: [
                    ListItem(id: "", name: "", channelName: "empty", active: false, connection: nil, type: .server, children: nil)
                ])
            ]
        }
        
        return GeometryReader { geo in
            List(model, children: \.children) { row in
                // determine an appropriate style depending on the state of the item
                let color =  viewModel.state.currentChannel?.id == row.id ? Color.primary : Color.secondary
                let fontStyle = row.active ? Font.body.bold() : Font.body.italic()
                
                HStack {
                    // do not display server channels in the list directly as children
                    if !(row.type == .channel && row.name == "_") {
                        Button(action: {
                            if let channel = row.connection!.channels.first(where: { $0.id == row.id }) {
                                self.viewModel.dispatch(.setChannel(channel))
                            }
                        }) {
                            Text(row.name)
                                .font(fontStyle)
                                .foregroundColor(color)
                        }.buttonStyle(BorderlessButtonStyle())
                        
                        Spacer()
                        
                        Button(action: {
                            
                        }) {
                            Image(systemName: "xmark")
                        }.buttonStyle(BorderlessButtonStyle())
                    }
                }
            }.frame(width: geo.size.width)
        }
    }
}

enum ChannelListViewModel {
    
    static func viewModel<S: StoreType>(from store: S) -> ObservableViewModel<ViewAction, ViewState> where S.ActionType == AppAction, S.StateType == AppState {
        store.projection(
            action: transform(viewAction:),
            state: transform(appState:)
        ).asObservableViewModel(initialState: .empty)
    }

    struct ViewState: Equatable {
        static func == (lhs: ChannelListViewModel.ViewState, rhs: ChannelListViewModel.ViewState) -> Bool {
            return false
        }
        
        let connections: [Connection]
        let currentChannel: IRCChannel?
        
        static var empty: ViewState {
            .init(connections: [], currentChannel: nil)
        }
    }

    enum ViewAction {
        case setChannel(IRCChannel)
    }
    
    private static func transform(viewAction: ViewAction) -> AppAction? {
        switch viewAction {
        case .setChannel:
            let channel = viewAction.setChannel!
            return .ui(.changeChannel(channel))
        }
    }
    
    private static func transform(appState: AppState) -> ViewState {
        ViewState(
            connections: appState.network.connections,
            currentChannel: appState.ui.currentChannel)
    }
}

extension ChannelListViewModel.ViewAction {
    public var setChannel: IRCChannel? {
        get {
            guard case let .setChannel(value) = self else { return nil }
            return value
        }
        set {
            guard case .setChannel = self, let value = newValue else { return }
            self = .setChannel(value)
        }
    }
}

extension ChannelListView {
    enum ListItemType {
        case server
        case channel
    }
    
    struct ListItem: Identifiable {
        var id: String
        var name: String
        var channelName: String
        var active: Bool
        var connection: Connection?
        var type: ListItemType
        var children: [ListItem]?
    }
}

//struct ChannelListView_Previews: PreviewProvider {
//    static var previews: some View {
//        ChannelListView()
//    }
//}
