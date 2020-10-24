//
//  ChannelView.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/23/20.
//

import SwiftUI

struct ChannelView: View {
    @State private var line = ""
    
    
    var body: some View {
        let binding = Binding(
            get: { self.line },
            set: {
                self.line = $0
                print($0)
            })
        
        return VStack(alignment: .center, spacing: nil, content: {
            ScrollView {
                Text("sample")
            }
            TextField("", text: binding)
        })
    }
}

struct ChannelView_Previews: PreviewProvider {
    static var previews: some View {
        ChannelView()
    }
}
