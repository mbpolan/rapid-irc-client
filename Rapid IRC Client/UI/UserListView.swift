//
//  UserListView.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 1/17/21.
//

import CombineRex
import SwiftRex
import SwiftUI

struct UserListView: View {
    
    @ObservedObject var viewModel: ObservableViewModel<UserListViewModel.ViewAction, UserListViewModel.ViewState>
    @State var hoveredNick: String?
    @State var kickReasonNick: String?
    @State var kickReason: String = ""
    
    var body: some View {
        List {
            ForEach(viewModel.state.groups, id: \.category) { group in
                Section(header: Text(group.category.info.label).font(.headline)) {
                    OutlineGroup(group.users, id: \.nick, children: \.children) { user in
                        makeUserItem(user)
                    }
                }
            }
        }
        .listStyle(InsetListStyle())
    }
    
    func makeUserItem(_ user: UserListViewModel.UserEntry) -> some View {
        let userInfoBinding = Binding<Bool>(
            get: { hoveredNick == user.nick },
            set: { hoveredNick = $0 ? hoveredNick : nil}
        )
        
        let kickReasonBinding = Binding<Bool>(
            get: { kickReasonNick == user.nick },
            set: { kickReasonNick = $0 ? kickReasonNick : nil}
        )
        
        return Text(user.nick)
            .font(.subheadline)
            .onHover { hovered in
                self.hoveredNick = hovered ? user.nick : nil
            }
            .contextMenu {
                ForEach(makeContextMenu(user), id: \.label) { entry in
                    if let label = entry.label {
                        Button(action: entry.action) {
                            Text(label)
                        }
                    } else {
                        Divider()
                    }
                }
            }
            .popover(isPresented: userInfoBinding, arrowEdge: .trailing) {
                let popoverGrid = [
                    GridItem(.fixed(70), spacing: 5),
                    GridItem(.fixed(100), spacing: 5)
                ]
                
                let cells = [
                    "Nick",
                    user.nick,
                    "Privilege",
                    user.privilege
                ]
                
                LazyVGrid(
                    columns: popoverGrid,
                    alignment: .leading,
                    spacing: 5,
                    pinnedViews: []) {
                    ForEach(cells, id: \.self) { cell in
                        Text(cell)
                    }
                }.padding()
            }
            .popover(isPresented: kickReasonBinding, arrowEdge: .leading) {
                VStack(alignment: .trailing) {
                    TextField("(reason)", text: $kickReason)
                        .frame(minWidth: 300)
                    
                    HStack(alignment: .lastTextBaseline) {
                        Button("Kick") {
                            guard let currentChannel = self.viewModel.state.currentChannel,
                                  let user = currentChannel.users.first(where: { $0.nick == kickReasonNick }) else { return }
                            
                            self.viewModel.dispatch(.kickUser(
                                                        channel: currentChannel,
                                                        user: user,
                                                        reason: kickReason))
                            
                            kickReason = ""
                            kickReasonNick = ""
                        }
                    }
                }
                .padding()
            }
    }
    
    private func makeContextMenu(_ entry: UserListViewModel.UserEntry) -> [(label: String?, action: () -> Void)] {
        var entries: [(String?, () -> Void)] = []
        
        // don't allow private messaging or kicking ourselves
        if !entry.identity {
            entries.append((label: "Private Message", action: {
                guard let currentChannel = self.viewModel.state.currentChannel else { return }
                
                self.viewModel.dispatch(.openPrivateMessage(
                                            channel: currentChannel,
                                            user: entry.user))
            }))
            
            entries.append((label: nil, action: {}))
            
            entries.append((label: "Kick", action: {
                kickReasonNick = entry.nick
            }))
        }
            
        // promote or revoke operator status
        if entry.user.privileges.contains(.fullOperator) {
            entries.append((label: "Revoke Operator", action: {
                guard let currentChannel = self.viewModel.state.currentChannel else { return }
                
                self.viewModel.dispatch(.takeOperator(
                                            channel: currentChannel,
                                            user: entry.user))
            }))
        } else {
            entries.append((label: "Make Operator", action: {
                guard let currentChannel = self.viewModel.state.currentChannel else { return }
                
                self.viewModel.dispatch(.giveOperator(
                                            channel: currentChannel,
                                            user: entry.user))
            }))
        }
        
        // promote or revoke half operator status
        if entry.user.privileges.contains(.halfOperator) {
            entries.append((label: "Revoke Half-Operator", action: {
                guard let currentChannel = self.viewModel.state.currentChannel else { return }
                
                self.viewModel.dispatch(.takeHalfOperator(
                                            channel: currentChannel,
                                            user: entry.user))
            }))
        } else {
            entries.append((label: "Make Half-Operator", action: {
                guard let currentChannel = self.viewModel.state.currentChannel else { return }
                
                self.viewModel.dispatch(.giveHalfOperator(
                                            channel: currentChannel,
                                            user: entry.user))
            }))
        }
        
        // promote or revoke voice status
        if entry.user.privileges.contains(.voiced) {
            entries.append((label: "Revoke Voice", action: {
                guard let currentChannel = self.viewModel.state.currentChannel else { return }
                
                self.viewModel.dispatch(.takeVoice(
                                            channel: currentChannel,
                                            user: entry.user))
            }))
        } else {
            entries.append((label: "Make Voice", action: {
                guard let currentChannel = self.viewModel.state.currentChannel else { return }
                
                self.viewModel.dispatch(.giveVoice(
                                            channel: currentChannel,
                                            user: entry.user))
            }))
        }
        
        return entries
    }
}

struct UserListViewModel {
    
    static func viewModel<S: StoreType>(from store: S) -> ObservableViewModel<ViewAction, ViewState> where S.ActionType == AppAction, S.StateType == AppState {
        store.projection(
            action: transform(viewAction:),
            state: transform(appState:)
        ).asObservableViewModel(initialState: .empty)
    }
    
    struct ViewState: Equatable {
        
        static func == (lhs: ViewState, rhs: ViewState) -> Bool {
            // compare only the last user list update timestamps to avoid comparing a large list
            return lhs.lastUserListUpdate == rhs.lastUserListUpdate
        }
        
        let currentChannel: IRCChannel?
        let lastUserListUpdate: Date
        let groups: [UserGroup]
        
        static var empty: ViewState {
            .init(
                currentChannel: nil,
                lastUserListUpdate: Date(),
                groups: [])
        }
    }
    
    enum ViewAction {
        case openPrivateMessage(channel: IRCChannel, user: User)
        case giveOperator(channel: IRCChannel, user: User)
        case takeOperator(channel: IRCChannel, user: User)
        case giveHalfOperator(channel: IRCChannel, user: User)
        case takeHalfOperator(channel: IRCChannel, user: User)
        case giveVoice(channel: IRCChannel, user: User)
        case takeVoice(channel: IRCChannel, user: User)
        case kickUser(channel: IRCChannel, user: User, reason: String?)
    }
    
    private static func transform(viewAction: ViewAction) -> AppAction? {
        switch viewAction {
        case .openPrivateMessage(let channel, let user):
            return .ui(
                .openPrivateMessage(
                    connection: channel.connection,
                    nick: user.nick))
            
        case .giveOperator(let channel, let user):
            return .network(
                .setUserMode(
                    connection: channel.connection,
                    channelName: channel.name,
                    nick: user.nick,
                    mode: User.ChannelPrivilege.fullOperator.given))
            
        case .takeOperator(channel: let channel, user: let user):
            return .network(
                .setUserMode(
                    connection: channel.connection,
                    channelName: channel.name,
                    nick: user.nick,
                    mode: User.ChannelPrivilege.fullOperator.taken))
            
        case .giveHalfOperator(channel: let channel, user: let user):
            return .network(
                .setUserMode(
                    connection: channel.connection,
                    channelName: channel.name,
                    nick: user.nick,
                    mode: User.ChannelPrivilege.halfOperator.given))
            
        case .takeHalfOperator(channel: let channel, user: let user):
            return .network(
                .setUserMode(
                    connection: channel.connection,
                    channelName: channel.name,
                    nick: user.nick,
                    mode: User.ChannelPrivilege.halfOperator.taken))
            
        case .giveVoice(channel: let channel, user: let user):
            return .network(
                .setUserMode(
                    connection: channel.connection,
                    channelName: channel.name,
                    nick: user.nick,
                    mode: User.ChannelPrivilege.voiced.given))
            
        case .takeVoice(channel: let channel, user: let user):
            return .network(
                .setUserMode(
                    connection: channel.connection,
                    channelName: channel.name,
                    nick: user.nick,
                    mode: User.ChannelPrivilege.voiced.taken))
        
        case .kickUser(let channel, let user, let reason):
            return .network(
                .kickUserFromChannel(
                    connection: channel.connection,
                    channelName: channel.name,
                    nick: user.nick,
                    reason: reason))
        }
    }
    
    private static func transform(appState: AppState) -> ViewState {
        guard let currentChannel = appState.ui.currentChannel else {
            return ViewState.empty
        }
        
        // categorize users based on their access levels
        var groups = [UserGroup.Category: [User]]()
        currentChannel.users.forEach { user in
            switch user.highestPrivilege() {
            case .founder,
                 .protected,
                 .fullOperator,
                 .halfOperator:
                groups[.operators, default: []].append(user)
                
            case .voiced:
                groups[.voiced, default: []].append(user)
                
            default:
                groups[.users, default: []].append(user)
            }
        }
        
        return ViewState(
            currentChannel: currentChannel,
            lastUserListUpdate: currentChannel.lastUserListUpdate,
            groups: groups.map { key, value in
                UserGroup(
                    category: key,
                    users: value.map { user in
                        UserEntry(
                            // is this user entry us?
                            identity: user.nick == currentChannel.connection.identifier?.subject,
                            nick: user.nick,
                            user: user,
                            children: [])
                    }.sorted { $0.nick < $1.nick })
            }.sorted { $0.category.info.order < $1.category.info.order })
    }
}

extension UserListViewModel {
    
    struct UserGroup: Equatable {
        let category: Category
        let users: [UserEntry]
        
        static func == (lhs: UserGroup, rhs: UserGroup) -> Bool {
            return lhs.category == rhs.category && lhs.users == rhs.users
        }
    }
    
    struct UserEntry: Equatable {
        let identity: Bool
        let nick: String
        let user: User
        let children: [UserEntry]?
        
        static func == (lhs: UserEntry, rhs: UserEntry) -> Bool {
            return lhs.nick == rhs.nick
        }
        
        var privilege: String {
            switch user.highestPrivilege() {
            case .founder:
                return "Founder"
            case .protected:
                return "Protected"
            case .fullOperator:
                return "Operator"
            case .halfOperator:
                return "Half Operator"
            case .voiced:
                return "Voice"
            default:
                return "None"
            }
        }
    }
}

extension UserListViewModel.UserGroup {
    
    enum Category {
        case operators
        case voiced
        case users
        
        var info: (label: String, order: Int) {
            switch self {
            case .operators:
                return ("Operators", 0)
            case .voiced:
                return ("Voiced", 1)
            case .users:
                return ("Users", 2)
            }
        }
    }
}
