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
    
    // non-changing id for channel list when we have at least one connection
    private let listUuid = UUID()
    
    @ObservedObject var viewModel: ObservableViewModel<ChannelListViewModel.ViewAction, ChannelListViewModel.ViewState>
    @State private var hoveredChannel: UUID?
    
    var body: some View {
        VStack {
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
                }
                // randomize the list id when empty to force a view refresh. this is needed since swiftui sometimes
                // tends to not redraw an empty list when the last server connection has been closed.
                .id(viewModel.state.list.isEmpty ? UUID() : listUuid)
                .listStyle(SidebarListStyle())
                .frame(width: geo.size.width)
            }
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
                
                Divider()
                
                Button(action: {
                    guard let connection = server.connection else { return }
                    self.viewModel.dispatch(.requestOperator(connection))
                }) {
                    Text("Become Operator")
                }
                
                Divider()
                
                Button(action: {
                    guard let connection = server.connection else { return }
                    self.viewModel.dispatch(.closeServer(connection))
                }) {
                    Text("Close")
                }
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
                Text(channel.type == .server ? "Server" : channel.name)
                    .foregroundColor(color)
                    .font(fontStyle)
            }
            .buttonStyle(BorderlessButtonStyle())
            
            Spacer()
            
            // button for closing the channel, only shown if the user hovers the containing view and the channel is not
            // the default server channel itself
            if self.hoveredChannel == channel.id && channel.type != .server {
                Button(action: {
                    if let target = channel.connection?.channels.first(where: { $0.id == channel.id }) {
                        self.viewModel.dispatch(.closeChannel(target))
                    }
                }) {
                    Image(systemName: "xmark")
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .frame(maxWidth: .infinity)
        .contextMenu {
            if channel.type != .server {
                // show an item for changing channel mode
                Button(action: {
                    if let target = channel.connection?.channels.first(where: { $0.id == channel.id }) {
                        self.viewModel.dispatch(.showChannelProperties(target))
                    }
                }) {
                    Text("Set Properties")
                }
            }
        }
    }
    
    private func makeChannelIcon(_ channel: ChannelListViewModel.ListItem) -> some View {
        var image: AnyView
        
        switch channel.type {
        case .root:
            image = AnyView(EmptyView())
        case .server:
            if channel.mentioned {
                image = AnyView(Image(systemName: "bolt.horizontal.circle.fill")
                                    .foregroundColor(.red))
            } else if channel.newMessages {
                image = AnyView(Image(systemName: "bolt.horizontal.circle.fill"))
            } else {
                image = AnyView(Image(systemName: "bolt.horizontal.circle"))
            }
        case .channel:
            if channel.mentioned {
                image = AnyView(Image(systemName: "bubble.left.and.bubble.right.fill")
                                    .foregroundColor(.red))
            } else if channel.newMessages {
                image = AnyView(Image(systemName: "bubble.left.and.bubble.right.fill"))
            } else {
                image = AnyView(Image(systemName: "bubble.left.and.bubble.right"))
            }
        case .privateMessage:
            if channel.newMessages {
                image = AnyView(Image(systemName: "person.fill")
                                    .foregroundColor(.red))
            } else {
                image = AnyView(Image(systemName: "person"))
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
        case closeServer(Connection)
        case setChannel(IRCChannel)
        case closeChannel(IRCChannel)
        case reconnect(Connection)
        case disconnect(Connection)
        case requestOperator(Connection)
        case showChannelProperties(IRCChannel)
    }
    
    private static func transform(viewAction: ViewAction) -> AppAction? {
        switch viewAction {
        case .closeServer(let connection):
            return .ui(
                .closeServer(
                    connection: connection))
        case .setChannel(let channel):
            return .ui(
                .changeChannel(
                    connection: channel.connection,
                    channelName: channel.name))
            
        case .closeChannel(let channel):
            return .ui(
                .closeChannel(
                    connection: channel.connection,
                    channelName: channel.name,
                    descriptor: channel.descriptor))
            
        case .reconnect(let connection):
            return .network(.reconnect(connection: connection))
            
        case .disconnect(let connection):
            return .network(.disconnect(connection: connection))
        
        case .requestOperator(let connection):
            return .ui(.showOperatorSheet(connection: connection))
        
        case .showChannelProperties(let channel):
            return .ui(
                .showChannelPropertiesSheet(
                    connection: channel.connection,
                    channelName: channel.name))
        }
    }
    
    private static func transform(appState: AppState) -> ViewState {
        ViewState(
            list: appState.network.connections.map { conn in
                return ListItem(
                    id: conn.id,
                    name: conn.name,
                    channelName: Connection.serverChannel,
                    mentioned: false,
                    newMessages: false,
                    active: conn.state == .connected,
                    connection: conn,
                    type: .root,
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
                                type: chan.descriptor == .multiUser
                                    ? .channel
                                    : chan.descriptor == .user
                                    ? .privateMessage
                                    : .server,
                                children: nil)
                        })
            },
            currentChannel: appState.ui.currentChannel)
    }
}

extension ChannelListViewModel {
    enum ListItemType {
        case root
        case server
        case channel
        case privateMessage
    }
    
    struct ListItem: Identifiable {
        var id: UUID
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
