//
//  ChannelListView.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/28/20.
//

import SwiftUI

struct ChannelListView: View {
    
    @EnvironmentObject var store: Store
    
    var body: some View {
        ScrollView {
            makeList()
        }.padding()
    }
    
    private func makeList() -> some View {
        print(store.state.connections.connections.count)
        return VStack {
            ForEach(store.state.connections.connections, id: \.name) { item in
                Text(item.name)
            }
        }
    }
}

struct ChannelListView_Previews: PreviewProvider {
    static var previews: some View {
        ChannelListView()
    }
}
