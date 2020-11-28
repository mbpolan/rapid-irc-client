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
            ScrollView {
                makeList()
            }.padding()
        }
    }

    private func makeList() -> some View {
//        let model = store.state.connections.connections.map { conn in
//            return ListItem(
//                name: conn.name,
//                type: .server,
//                children: conn.channels.map { chan in
//                    return ListItem(
//                        name: chan.name,
//                        type: .channel,
//                        children: nil)
//                })
//        }
//
//        return List(model, children: \.children) { row in
//            Text(row.name)
//        }
        var channels: [IRCChannel]
        var current: Connection? = nil
        if (store.state.connections.current == -1) {
            channels = []
        } else {
            current = store.state.connections.connections[store.state.connections.current]
            channels = current!.channels
        }

        return VStack {
            ForEach(channels, id: \.name) { item in
                Button(item.name) {
                    store.dispatch(action: SetChannelAction(connection: current!, channel: item.name))
                }.buttonStyle(BorderlessButtonStyle())
            }
        }
    }
}

extension ChannelListView {
    enum ListItemType {
        case server
        case channel
    }
    
    struct ListItem: Identifiable {
        var id: String {
            return name
        }
        
        var name: String
        var type: ListItemType
        var children: [ListItem]?
    }
}

struct ChannelListView_Previews: PreviewProvider {
    static var previews: some View {
        ChannelListView()
    }
}
