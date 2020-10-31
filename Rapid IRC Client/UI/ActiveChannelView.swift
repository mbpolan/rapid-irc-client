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
                TextField("", text: $input, onCommit: {
                    submit()
                })
                Spacer()
                Button("OK") {
                    submit()
                }
            }
        }
    }
    
    private func submit() {
        store.dispatch(action: MessageSentAction(message: input))
        input = ""
    }
}

struct ActiveChannelView_Previews: PreviewProvider {
    static var previews: some View {
        ActiveChannelView()
    }
}
