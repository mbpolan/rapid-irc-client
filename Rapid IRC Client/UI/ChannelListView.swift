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
    @State private var activePopover: ActivePopover?
    @State private var popoverChannel: IRCChannel?
    
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
        
        return HStack {
            // show an icon to indicate a secure connection
            if server.connection?.client.server.secure == true {
                Image(systemName: "lock.fill")
                    .help("This connection is secure")
            }
            
            Text(server.name)
        }
        .font(fontStyle)
        .contextMenu {
            if server.active {
                Button("Disconnect") {
                    guard let connection = server.connection else { return }
                    self.viewModel.dispatch(.disconnect(connection))
                }
            } else {
                Button("Connect") {
                    guard let connection = server.connection else { return }
                    self.viewModel.dispatch(.reconnect(connection))
                }
            }
            
            Divider()
            
            Button("Become Operator") {
                guard let connection = server.connection else { return }
                self.viewModel.dispatch(.requestOperator(connection))
            }
            
            Divider()
            
            Button("Close") {
                guard let connection = server.connection else { return }
                self.viewModel.dispatch(.closeServer(connection))
            }
        }
    }
    
    private func makeChannelItem(_ channel: ChannelListViewModel.ListItem) -> some View {
        // determine an appropriate style depending on the state of the item
        let color = viewModel.state.currentChannel?.id == channel.id ? Color.primary : Color.secondary
        
        let fontStyle: Font = channel.connection?.channels.first(where: { $0.id == channel.id })?.state == .joined
            ? .subheadline
            : Font.subheadline.italic()
        
        let popoverBinding = Binding<ActivePopover?>(
            get: {
                if let popoverChannel = self.popoverChannel,
                   popoverChannel.name == channel.name,
                   popoverChannel.connection === channel.connection {
                    return self.activePopover
                }
                
                return nil
            },
            set: { value in
                if value == .none {
                    self.popoverChannel = .none
                }
                
                self.activePopover = value
            })
        
        return HStack {
            makeChannelIcon(channel)
            
            // button containing the channel name
            Button(action: {
                if let target = channel.connection?.channels.first(where: { $0.id == channel.id }) {
                    self.viewModel.dispatch(.setChannel(target))
                }
            }, label: {
                Text(channel.type == .server ? "Server" : channel.name)
                    .foregroundColor(color)
                    .font(fontStyle)
            })
            .buttonStyle(BorderlessButtonStyle())
            
            Spacer()
            
            // button for closing the channel, only shown if the user hovers the containing view and the channel is not
            // the default server channel itself
            if self.hoveredChannel == channel.id && channel.type != .server {
                Button(action: {
                    if let target = channel.connection?.channels.first(where: { $0.id == channel.id }) {
                        self.viewModel.dispatch(.closeChannel(target))
                    }
                }, label: {
                    Image(systemName: "xmark")
                })
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .frame(maxWidth: .infinity)
        .contextMenu {
            if channel.type != .server {
                // show an item for inviting a user to this channel
                Button("Invite User") {
                    if let target = channel.connection?.channels.first(where: { $0.id == channel.id }) {
                        self.activePopover = .invite
                        self.popoverChannel = target
                    }
                }
                
                Divider()
                
                // show an item for changing channel topic
                Button("Change Topic") {
                    if let target = channel.connection?.channels.first(where: { $0.id == channel.id }) {
                        self.viewModel.dispatch(.showChannelTopicEditor(target))
                    }
                }
                
                // show an item for changing channel mode
                Button("Set Properties") {
                    if let target = channel.connection?.channels.first(where: { $0.id == channel.id }) {
                        self.viewModel.dispatch(.showChannelProperties(target))
                    }
                }
            }
        }
        .popover(item: popoverBinding) { item in
            switch item {
            case .invite:
                InviteUserPopover(
                    mode: .inviteToChannel(self.popoverChannel?.name ?? ""),
                    onInvite: handleInviteToChannel)
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
    
    private func handleInviteToChannel(_ nick: String) {
        self.activePopover = .none
        self.popoverChannel = .none
        
        guard let popoverChannel = self.popoverChannel else { return }
        
        self.viewModel.dispatch(.inviteUser(
                                    channel: popoverChannel,
                                    inviteNick: nick))
    }
}

// MARK: - View extensions
extension ChannelListView {
    
    enum ActivePopover: Identifiable {
        case invite
        
        var id: Int {
            hashValue
        }
    }
}

// MARK: - ViewModel
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
        case showChannelTopicEditor(IRCChannel)
        case inviteUser(channel: IRCChannel, inviteNick: String)
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
        
        case .showChannelTopicEditor(let channel):
            return .ui(
                .showChannelTopicSheet(
                    connection: channel.connection,
                    channelName: channel.name))
        
        case .inviteUser(let channel, let inviteNick):
            return .network(
                .inviteUserToChannel(
                    connection: channel.connection,
                    nick: inviteNick,
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

// MARK: - ViewModel extensions
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

// MARK: - Preview
struct ChannelListView_Previews: PreviewProvider {
    static var previews: some View {
        let store = Store()
        
        ChannelListView(viewModel: ChannelListViewModel.viewModel(from: store))
    }
}
