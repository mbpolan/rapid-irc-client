//
//  ContentView.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/23/20.
//

import Swinject
import SwiftUI

struct ContentView: View {
    
    @State private var connectToServerOpen = false
    
    private let connectionsStore: ConnectionsStore
    private let container: Container
    
    // listener for the connect to server event
    private let connectToServer = NotificationCenter
        .default
        .publisher(for: .connectToServer)
        .receive(on: RunLoop.main)
    
    // listener for the server connection initiation event
    private let doConnectToServer = NotificationCenter
        .default
        .publisher(for: .doConnectToServer)
        .receive(on: RunLoop.main)
    
    init(connectionsStore: ConnectionsStore, container: Container) {
        self.connectionsStore = connectionsStore
        self.container = container
    }
    
    var body: some View {
        HSplitView /*@START_MENU_TOKEN@*/{
            ChatListView()
            ChannelView()
        }/*@END_MENU_TOKEN@*/
        .onReceive(connectToServer) { _ in
            self.connectToServerOpen = true
        }
        .onReceive(doConnectToServer) { info in
            self.connect(info: info.object! as! ServerInfo)
        }
        .sheet(isPresented: $connectToServerOpen) {
            ConnectDialog()
        }
        .environmentObject(self.connectionsStore)
    }
    
    private func connect(info: ServerInfo) {
        let service = self.container.resolve(ConnectionService.self)!
        service.addConnection(info: info)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(connectionsStore: ConnectionsStore(), container: Container())
    }
}
