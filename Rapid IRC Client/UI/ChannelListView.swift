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
            makeList()
        }
    }
    
    struct Test: Identifiable {
        var id: String {
            return name
        }
        var name: String
        var children: [Test]?
    }

    private func makeList() -> some View {
        var model = store.state.connections.connections.map { conn in
            return ListItem(
                name: conn.name,
                channelName: Connection.serverChannel,
                connection: conn,
                type: .server,
                children: conn.channels
                    .map { chan in
                        return ListItem(
                            name: chan.name,
                            channelName: chan.name,
                            connection: conn,
                            type: .channel,
                            children: nil)
                    })
        }
        
        // workaround for when the list is initially empty. if we do not explicitly set a node with a child,
        // the list will never show children after the fact.
        if model.count == 0 {
            model = [
                ListItem(name: "", channelName: "empty", connection: nil, type: .server, children: [
                    ListItem(name: "", channelName: "empty", connection: nil, type: .server, children: nil)
                ])
            ]
        }

        return List(model, children: \.children) { row in
            VStack {
                // do not display server channels in the list directly as children
                if !(row.type == .channel && row.name == "_") {
                    Button(row.name) {
                        store.dispatch(action: SetChannelAction(connection: row.connection!, channel: row.channelName))
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
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
        var channelName: String;
        var connection: Connection?
        var type: ListItemType
        var children: [ListItem]?
    }
}

struct ChannelListView_Previews: PreviewProvider {
    static var previews: some View {
        ChannelListView()
    }
}
