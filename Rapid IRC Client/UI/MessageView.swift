//
//  MessageView.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/28/20.
//

import SwiftUI

struct MessageView: View {
    
    @EnvironmentObject var store: Store
    
    var body: some View {
        ScrollView {
            HStack {
                VStack(alignment: .leading) {
                    makeText()
                }
                Spacer()
            }
        }
    }
    
    private func makeText() -> some View {
        if store.state.ui.currentChannel == nil {
            print("no connection")
            return Text("")
        }
        
        var text = Text("")
        
        for message in store.state.ui.currentChannel!.messages {
            text = text + Text("\(message)\n")
        }
        
        return text
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        MessageView()
    }
}
