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
                id: conn.getServerChannel()!.id,
                name: conn.name,
                channelName: Connection.serverChannel,
                active: true,
                connection: conn,
                type: .server,
                children: conn.channels
                    .map { chan in
                        return ListItem(
                            id: chan.id,
                            name: chan.name,
                            channelName: chan.name,
                            active: chan.state == .joined,
                            connection: conn,
                            type: .channel,
                            children: nil)
                    })
        }
        
        // workaround for when the list is initially empty. if we do not explicitly set a node with a child,
        // the list will never show children after the fact.
        if model.count == 0 {
            model = [
                ListItem(id: "", name: "", channelName: "empty", active: false, connection: nil, type: .server, children: [
                    ListItem(id: "", name: "", channelName: "empty", active: false, connection: nil, type: .server, children: nil)
                ])
            ]
        }
        
        return GeometryReader { geo in
            List(model, children: \.children) { row in
                // determine an appropriate style depending on the state of the item
                let color =  store.state.ui.currentChannel == row.id ? Color.primary : Color.secondary
                let fontStyle = row.active ? Font.body.bold() : Font.body.italic()
                
                HStack {
                    // do not display server channels in the list directly as children
                    if !(row.type == .channel && row.name == "_") {
                        Button(action: {
                            store.dispatch(action: SetChannelAction(connection: row.connection!, channel: row.id))
                        }) {
                            Text(row.name)
                                .font(fontStyle)
                                .foregroundColor(color)
                        }.buttonStyle(BorderlessButtonStyle())
                        
                        Spacer()
                        
                        Button(action: {
                            
                        }) {
                            Image(systemName: "xmark")
                        }.buttonStyle(BorderlessButtonStyle())
                    }
                }
            }.frame(width: geo.size.width)
        }
    }
}

extension ChannelListView {
    enum ListItemType {
        case server
        case channel
    }
    
    struct ListItem: Identifiable {
        var id: String
        var name: String
        var channelName: String
        var active: Bool
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
