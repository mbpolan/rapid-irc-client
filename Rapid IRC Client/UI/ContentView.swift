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
            ActiveChannelView()
        }.sheet(isPresented: $connectDialogShown, content: {
            ConnectDialog(shown: $connectDialogShown, onClose: handleConnectToServer)
        }).onReceive(onConnectToServer) { event in
            connectDialogShown = true
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func handleConnectToServer(result: ConnectDialog.Result) {
        print(result.accepted)
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
