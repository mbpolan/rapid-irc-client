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
    
    private func makeSectionText(_ server: ChannelListViewModel.ListItem) -> some View {
        let fontStyle: Font = server.active
            ? .headline
            : Font.headline.italic()
        
        return Text(server.name)
            .font(fontStyle)
            .contextMenu {
                if server.active {
                    Button(action: {
                        guard let connection = server.connection else { return }
                        self.viewModel.dispatch(.disconnect(connection))
                    }) {
                        Text("Disconnect")
                    }
                } else {
                    Button(action: {
                        guard let connection = server.connection else { return }
                        self.viewModel.dispatch(.reconnect(connection))
                    }) {
                        Text("Connect")
                    }
                }
            }
    }
    
    private func makeList() -> some View {
        GeometryReader { geo in
            List {
                ForEach(viewModel.state.list, id: \.id) { server in
                    // header contains the server name
                    Section(header: makeSectionText(server)) {
                        // list each channel under this server as a group
                        OutlineGroup(server.children ?? [], id: \.id, children: \.children) { channel in
                            makeChannelItem(channel)
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
    
    private func makeChannelItem(_ channel: ChannelListViewModel.ListItem) -> some View {
        // determine an appropriate style depending on the state of the item
        let color = viewModel.state.currentChannel?.id == channel.id ? Color.primary : Color.secondary
        
        let fontStyle: Font = channel.connection?.channels.first(where: { $0.id == channel.id })?.state == .joined
            ? .subheadline
            : Font.subheadline.italic()
        
        return HStack {
            makeChannelIcon(channel)
            
            // button containing the channel name
            Button(action: {
                if let target = channel.connection?.channels.first(where: { $0.id == channel.id }) {
                    self.viewModel.dispatch(.setChannel(target))
                }
            }) {
                Text(channel.name == Connection.serverChannel ? "Server" : channel.name)
                    .foregroundColor(color)
                    .font(fontStyle)
            }.buttonStyle(BorderlessButtonStyle())
            
            Spacer()
            
            // button for closing the channel, only shown if the user hovers the containing view and the channel is not
            // the default server channel itself
            if self.hoveredChannel == channel.id && channel.name != Connection.serverChannel {
                Button(action: {
                    if let target = channel.connection?.channels.first(where: { $0.id == channel.id }) {
                        self.viewModel.dispatch(.closeChannel(target))
                    }
                }) {
                    Image(systemName: "xmark")
                }.buttonStyle(BorderlessButtonStyle())
            }
        }.frame(maxWidth: .infinity)
    }
    
    private func makeChannelIcon(_ channel: ChannelListViewModel.ListItem) -> some View {
        var image: AnyView
        
        if channel.name == Connection.serverChannel {
            if channel.mentioned {
                image = AnyView(Image(systemName: "bolt.horizontal.circle.fill")
                    .foregroundColor(.red))
            } else if channel.newMessages {
                image = AnyView(Image(systemName: "bolt.horizontal.circle.fill"))
            } else {
                image = AnyView(Image(systemName: "bolt.horizontal.circle"))
            }
        } else {
            if channel.mentioned {
                image = AnyView(Image(systemName: "exclamationmark.bubble.fill")
                    .foregroundColor(.red))
            } else if channel.newMessages {
                image = AnyView(Image(systemName: "bubble.left.fill"))
            } else {
                image = AnyView(Image(systemName: "bubble.left"))
            }
        }
        
        return image
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
        case closeChannel(IRCChannel)
        case reconnect(Connection)
        case disconnect(Connection)
    }
    
    private static func transform(viewAction: ViewAction) -> AppAction? {
        switch viewAction {
        case .setChannel(let channel):
            return .ui(
                .changeChannel(
                    connection: channel.connection,
                    channelName: channel.name))
            
        case .closeChannel(let channel):
            return .ui(
                .closeChannel(
                    connection: channel.connection,
                    channelName: channel.name))
            
        case .reconnect(let connection):
            return .network(.reconnect(connection: connection))
            
        case .disconnect(let connection):
            return .network(.disconnect(connection: connection))
        }
    }
    
    private static func transform(appState: AppState) -> ViewState {
        ViewState(
            list: appState.network.connections.map { conn in
                return ListItem(
                    id: conn.getServerChannel()!.id,
                    name: conn.name,
                    channelName: Connection.serverChannel,
                    mentioned: false,
                    newMessages: false,
                    active: conn.state == .connected,
                    connection: conn,
                    type: .server,
                    children: conn.channels
                        .map { chan in
                            return ListItem(
                                id: chan.id,
                                name: chan.name,
                                channelName: chan.name,
                                mentioned: chan.notifications.contains(.mention),
                                newMessages: chan.notifications.contains(.newMessages),
                                active: chan.state == .joined,
                                connection: conn,
                                type: .channel,
                                children: nil)
                        })
            },
            currentChannel: appState.ui.currentChannel)
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
        var mentioned: Bool
        var newMessages: Bool
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
