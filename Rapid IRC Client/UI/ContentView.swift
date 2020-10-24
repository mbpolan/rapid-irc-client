//
//  ContentView.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/23/20.
//

import SwiftUI

struct ContentView: View {
    
    @State private var connectToServerOpen = true
    
    private let connectToServer = NotificationCenter
        .default
        .publisher(for: .connectToServer)
    
    private let doConnectToServer = NotificationCenter
        .default
        .publisher(for: .doConnectToServer)
    
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
    }
    
    private func connect(info: ServerInfo) {
        
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
