//
//  ChannelListView.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/28/20.
//

import SwiftUI

struct ChannelListView: View {

    @EnvironmentObject var store: Store
    @State var connection = 0 {
        didSet {
            print("SET \(connection)")
        }
    }

    var body: some View {
        VStack {
            Picker(selection: $connection, label: Text("")) {
                ForEach(0..<store.state.connections.connections.count, id: \.self) {
                    Text(store.state.connections.connections[$0].name)
                        .tag($0)
                }
            }
            ScrollView {
                makeList()
            }.padding()
        }
    }

    private func makeList() -> some View {
        var channels: [IRCChannel]
        var current: Connection? = nil
        if (store.state.connections.current == -1) {
            channels = []
        } else {
            current = store.state.connections.connections[store.state.connections.current]
            channels = current!.channels
        }
        
        print(store.state.connections.current)
        
        return VStack {
            ForEach(channels, id: \.name) { item in
                Button(item.name) {
                    store.dispatch(action: SetChannelAction(connection: current!, channel: item.name))
                }.buttonStyle(BorderlessButtonStyle())
            }
        }
    }
}

struct ChannelListView_Previews: PreviewProvider {
    static var previews: some View {
        ChannelListView()
    }
}
