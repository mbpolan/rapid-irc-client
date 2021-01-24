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
        let binding = Binding<Bool>(
            get: { hoveredNick == user.nick },
            set: { hoveredNick = $0 ? hoveredNick : nil}
        )
        
        return Text(user.nick)
            .font(.subheadline)
            .onHover { hovered in
                self.hoveredNick = hovered ? user.nick : nil
            }
            .contextMenu {
                Button(action: {
                    guard let currentChannel = self.viewModel.state.currentChannel else { return }
                    
                    self.viewModel.dispatch(.openPrivateMessage(
                                                channel: currentChannel,
                                                user: user.user))
                }) {
                    Text("Private Message")
                }
            }
            .popover(isPresented: binding, arrowEdge: .trailing) {
                let popoverGrid = [
                    GridItem(.fixed(70), spacing: 5),
                    GridItem(.fixed(100), spacing: 5),
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
    }
    
    private static func transform(viewAction: ViewAction) -> AppAction? {
        switch viewAction {
        case .openPrivateMessage(let channel, let user):
            return .ui(
                .openPrivateMessage(
                    connection: channel.connection,
                    nick: user.name))
        }
    }
    
    private static func transform(appState: AppState) -> ViewState {
        guard let currentChannel = appState.ui.currentChannel else {
            return ViewState.empty
        }
        
        // categorize users based on their access levels
        var groups = Dictionary<UserGroup.Category, [User]>()
        currentChannel.users.forEach { user in
            switch user.privilege {
            case .owner, .admin, .fullOperator, .halfOperator:
                groups[.operators, default: []].append(user)
            case .voiced:
                groups[.voiced, default: []].append(user)
            case .none:
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
                        nick: user.name,
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
        
        static func ==(lhs: UserGroup, rhs: UserGroup) -> Bool {
            return lhs.category == rhs.category && lhs.users == rhs.users
        }
    }
    
    struct UserEntry: Equatable {
        let nick: String
        let user: User
        let children: [UserEntry]?
        
        static func ==(lhs: UserEntry, rhs: UserEntry) -> Bool {
            return lhs.nick == rhs.nick
        }
        
        var privilege: String {
            switch user.privilege {
            case .owner:
                return "Owner"
            case .admin:
                return "Administrator"
            case .fullOperator:
                return "Operator"
            case .halfOperator:
                return "Half Operator"
            case .voiced:
                return "Voice"
            case .none:
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
