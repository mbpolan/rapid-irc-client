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
    @State private var hoveredChannel: String?
    
    var body: some View {
        VStack {
            makeList()
        }
    }
    
    private func makeList() -> some View {
        GeometryReader { geo in
            List {
                ForEach(viewModel.state.list, id: \.id) { server in
                    // header contains the server name
                    Section(header: Text(server.name).font(.headline)) {
                        // list each channel under this server as a group
                        OutlineGroup(server.children ?? [], id: \.id, children: \.children) { channel in
                            // determine an appropriate style depending on the state of the item
                            let color =  viewModel.state.currentChannel?.id == channel.id ? Color.primary : Color.secondary
                            
                            HStack {
                                // button containing the channel name
                                Button(action: {
                                    if let target = channel.connection?.channels.first(where: { $0.id == channel.id }) {
                                        self.viewModel.dispatch(.setChannel(target))
                                    }
                                }) {
                                    Text(channel.name == Connection.serverChannel ? "Server" : channel.name)
                                        .foregroundColor(color)
                                        .font(.subheadline)
                                }.buttonStyle(BorderlessButtonStyle())
                                
                                Spacer()
                                
                                // button for closing the channel, only shown if the user hovers the containing view
                                if self.hoveredChannel == channel.id {
                                    Button(action: {
                                        
                                    }) {
                                        Image(systemName: "xmark")
                                    }.buttonStyle(BorderlessButtonStyle())
                                }
                            }.frame(maxWidth: .infinity)
                            .onHover { hovering in
                                // keep track of which channel the user has hovered over
                                if hovering {
                                    self.hoveredChannel = channel.id
                                } else {
                                    self.hoveredChannel = nil
                                }
                            }
                        }
                    }
                }
            }.listStyle(SidebarListStyle())
            .frame(width: geo.size.width)
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
        
        let list: [ListItem]
        let currentChannel: IRCChannel?
        
        static var empty: ViewState {
            .init(list: [], currentChannel: nil)
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
            list: appState.network.connections.map { conn in
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
            },
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

extension ChannelListViewModel {
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

struct ChannelListView_Previews: PreviewProvider {
    static var previews: some View {
        let store = Store()
        
        ChannelListView(viewModel: ChannelListViewModel.viewModel(from: store))
    }
}
