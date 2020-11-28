//
//  ContentView.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/23/20.
//

import SwiftUI
import Combine

struct ContentView: View {

    @EnvironmentObject private var store: Store
    @State private var connectDialogShown = false

    private var onConnectToServer = NotificationCenter.default.publisher(for: .connectToServer)

    var body: some View {
        HSplitView {
            ChannelListView()
                .layoutPriority(1)
            ActiveChannelView()
                .layoutPriority(2)
        }.sheet(isPresented: $connectDialogShown, content: {
            ConnectDialog(shown: $connectDialogShown, onClose: handleConnectToServer)
        }).onReceive(onConnectToServer) { event in
            connectDialogShown = true
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func handleConnectToServer(result: ConnectDialog.Result) {
        if !result.accepted {
            return
        }
        
        store.dispatch(action: ConnectAction(server: result.server!))
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
