//
//  ContentView.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/23/20.
//

import SwiftUI
import Combine
import CombineRex
import SwiftRex

// MARK: - View
struct ContentView: View {
    
    @ObservedObject var viewModel: ObservableViewModel<ContentViewModel.ViewAction, ContentViewModel.ViewState>
    
    private let onConnectToServer = NotificationCenter.default.publisher(for: .connectToServer)
    
    var body: some View {
        let sheetBinding: Binding<ContentViewModel.ActiveSheet?> = Binding(
            get: {
                return viewModel.state.activeSheet
            },
            set: { value in
            }
        )
        
        HSplitView {
            ChannelListView(viewModel: ChannelListViewModel.viewModel(from: Store.instance))
                .layoutPriority(1)
            ActiveChannelView(viewModel: ActiveChannelViewModel.viewModel(from: Store.instance))
                .layoutPriority(2)
        }
        .sheet(item: sheetBinding) { sheet in
            switch sheet {
            case .connectToServer:
                QuickConnectSheet(onClose: handleConnectToServer)
            case .requestOperator:
                OperatorLoginSheet(onClose: handleRequestOperator)
            case .channelProperties:
                ChannelPropertiesSheet(
                    initial: self.viewModel.state.pendingChannelAction?.mode ?? .default,
                    onCommit: handleChannelProperties)
            }
        }
        .onReceive(onConnectToServer) { event in
            self.viewModel.dispatch(.showConnectSheet)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func handleConnectToServer(result: QuickConnectSheet.Result) {
        guard let server = result.server, result.accepted else {
            self.viewModel.dispatch(.closeConnectSheet)
            return
        }
        
        self.viewModel.dispatch(.connectToServer(server: server))
    }
    
    private func handleRequestOperator(result: OperatorLoginSheet.Result) {
        guard let credentials = result.credentials, result.accepted else {
            self.viewModel.dispatch(.closeOperatorLoginSheet)
            return
        }
        
        self.viewModel.dispatch(.sendOperatorLogin(
                                    username: credentials.username,
                                    password: credentials.password))
    }
    
    private func handleChannelProperties(result: ChannelPropertiesSheet.Result) {
        guard let modeChange = result.modeChange, result.accepted else {
            self.viewModel.dispatch(.closeChannelPropertiesSheet)
            return
        }
        
        self.viewModel.dispatch(.sendChannelMode(mode: modeChange))
    }
}

// MARK: - ViewModel
enum ContentViewModel {
    static func viewModel<S: StoreType>(from store: S) -> ObservableViewModel<ViewAction, ViewState> where S.ActionType == AppAction, S.StateType == AppState {
        store.projection(
            action: transform(viewAction:),
            state: transform(appState:)
        ).asObservableViewModel(initialState: .empty)
    }
    
    struct ViewState: Equatable {
        var activeSheet: ActiveSheet?
        var pendingChannelAction: IRCChannel?
        
        static var empty: ViewState {
            .init(
                activeSheet: nil,
                pendingChannelAction: nil)
        }
    }
    
    enum ViewAction {
        case showConnectSheet
        case connectToServer(server: ServerInfo)
        case closeConnectSheet
        case sendOperatorLogin(username: String, password: String)
        case closeOperatorLoginSheet
        case sendChannelMode(mode: ChannelModeChange)
        case closeChannelPropertiesSheet
    }
    
    private static func transform(viewAction: ViewAction) -> AppAction? {
        switch viewAction {
        case .showConnectSheet:
            return .ui(
                .toggleConnectSheet(
                    shown: true))
            
        case .connectToServer(let server):
            return .ui(
                .connectToServer(serverInfo: server))
            
        case .closeConnectSheet:
            return .ui(
                .toggleConnectSheet(
                    shown: false))
            
        case .sendOperatorLogin(let username, let password):
            return .ui(
                .sendOperatorLogin(
                    username: username,
                    password: password))
            
        case .closeOperatorLoginSheet:
            return .ui(.hideOperatorSheet)
        
        case .sendChannelMode(let mode):
            return .ui(.sendChannelModeChange(modeChange: mode))
        
        case .closeChannelPropertiesSheet:
            return .ui(.hideChannelPropertiesSheet)
        }
    }
    
    private static func transform(appState: AppState) -> ViewState {
        var activeSheet: ActiveSheet? = nil
        var pendingChannelAction: IRCChannel? = nil
        
        if appState.ui.connectSheetShown {
            activeSheet = .connectToServer
        } else if appState.ui.requestOperatorSheetShown {
            activeSheet = .requestOperator
        } else if appState.ui.channelPropertiesSheetShown {
            activeSheet = .channelProperties
            pendingChannelAction = appState.ui.pendingChannelPropertiesChannel
        }
        
        return ViewState(
            activeSheet: activeSheet,
            pendingChannelAction: pendingChannelAction)
    }
}

extension ContentViewModel {
    
    enum ActiveSheet: Identifiable {
        case connectToServer
        case requestOperator
        case channelProperties
        
        var id: Int {
            hashValue
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            viewModel: ContentViewModel.viewModel(from: Store()))
    }
}
