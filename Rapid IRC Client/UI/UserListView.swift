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
    
    var body: some View {
        List {
            ForEach(viewModel.state.groups, id: \.category) { group in
                Section(header: Text(group.category.info.label).font(.headline)) {
                    OutlineGroup(group.users, id: \.nick, children: \.children) { user in
                        Text(user.nick)
                            .font(.subheadline)
                    }
                }
            }
        }.listStyle(InsetListStyle())
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
        let groups: [UserGroup]
        
        static var empty: ViewState {
            .init(groups: [])
        }
    }

    enum ViewAction {
        
    }
    
    private static func transform(viewAction: ViewAction) -> AppAction? {
        return nil
    }
    
    private static func transform(appState: AppState) -> ViewState {
        guard let users = appState.ui.currentChannel?.users else {
            return ViewState.empty
        }
        
        // categorize users based on their access levels
        var groups = Dictionary<UserGroup.Category, [User]>()
        users.forEach { user in
            switch user.privilege {
            case .owner, .admin, .fullOperator, .halfOperator:
                groups[.operators, default: []].append(user)
            case .voiced:
                groups[.voiced, default: []].append(user)
            case .none:
                groups[.users, default: []].append(user)
            }
        }
        
        return ViewState(groups: groups.map { key, value in
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
