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
        HSplitView {
            ChannelListView(viewModel: ChannelListViewModel.viewModel(from: Store.instance))
                .layoutPriority(1)
            ActiveChannelView(viewModel: ActiveChannelViewModel.viewModel(from: Store.instance))
                .layoutPriority(2)
        }.sheet(isPresented: self.$viewModel.state.connectSheetShown, content: {
            ConnectDialog(shown: self.$viewModel.state.connectSheetShown, onClose: handleConnectToServer)
        }).onReceive(onConnectToServer) { event in
            self.viewModel.dispatch(.showConnectSheet)
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func handleConnectToServer(result: ConnectDialog.Result) {
        guard let server = result.server, result.accepted else {
            self.viewModel.dispatch(.closeConnectSheet)
            return
        }
        
        self.viewModel.dispatch(.connectToServer(server: server))
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
        var connectSheetShown: Bool
        
        static var empty: ViewState {
            .init(connectSheetShown: false)
        }
    }

    enum ViewAction {
        case showConnectSheet
        case connectToServer(server: ServerInfo)
        case closeConnectSheet
    }
    
    private static func transform(viewAction: ViewAction) -> AppAction? {
        switch viewAction {
        case .showConnectSheet:
            return .ui(.toggleConnectSheet(true))
        case .connectToServer(let server):
            return .network(.connect(server))
        case .closeConnectSheet:
            return .ui(.toggleConnectSheet(false))
        }
    }
    
    private static func transform(appState: AppState) -> ViewState {
        ViewState(connectSheetShown: appState.ui.connectSheetShown)
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            viewModel: ContentViewModel.viewModel(from: Store()))
    }
}
