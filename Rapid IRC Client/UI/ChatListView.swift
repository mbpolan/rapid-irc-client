//
//  ChannelListView.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/23/20.
//

import SwiftUI

struct ChatListView: View {
    var items = ["Mike", "Jase"]
    
    var body: some View {
        List(items, id: \.self) { item in
            Text(item)
        }
    }
}

struct ChannelListView_Previews: PreviewProvider {
    static var previews: some View {
        ChatListView()
    }
}
