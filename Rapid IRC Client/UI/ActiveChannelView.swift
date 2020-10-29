//
//  ActiveChannelView.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/28/20.
//

import SwiftUI

struct ActiveChannelView: View {
    
    @EnvironmentObject var store: Store
    @State private var input: String = ""
    
    var body: some View {
        return VStack {
            MessageView()
            HStack {
                TextField("", text: $input)
                Spacer()
                Button("OK") {
                    
                }
            }
        }
    }
}

struct ActiveChannelView_Previews: PreviewProvider {
    static var previews: some View {
        ActiveChannelView()
    }
}
