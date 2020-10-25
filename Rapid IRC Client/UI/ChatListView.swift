//
//  ChannelListView.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/23/20.
//

import SwiftUI

struct ChatListView: View {
    
    @EnvironmentObject var store: ConnectionsStore
    
    var body: some View {
        List {
            ForEach(store.connections, id: \.id) { item in
                Text(item.info.name)
            }
        }
    }
}

struct ChannelListView_Previews: PreviewProvider {
    static var previews: some View {
        ChatListView()
    }
}
