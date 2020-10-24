//
//  Dialogs.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/24/20.
//

import Combine
import SwiftUI

struct ConnectDialog: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var server = ""
    @State private var port = ""
    
    var body: some View {
        VStack {
            HStack {
                Text("Server")
                TextField("", text: $server)
            }
            HStack {
                Text("Port")
                TextField("", text: $port)
//                onReceive(Just(port)) { newValue in
//                    let filtered = newValue.filter { "0123456789".contains($0)
//                    }
//
//                    if filtered != newValue {
//                        self.port = filtered
//                    }
//                }
            }
            HStack {
                Spacer()
                Button("OK") {
                    NotificationCenter.default.post(
                        name: .doConnectToServer,
                        object: ServerInfo(server: self.server, port: UInt32(self.port) ?? 0))
                    
                    self.presentationMode.wrappedValue.dismiss()
                }
                Button("Cancel") {
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .padding()
    }
}

struct ConnectDialog_Previews: PreviewProvider {
    static var previews: some View {
        ConnectDialog()
    }
}
