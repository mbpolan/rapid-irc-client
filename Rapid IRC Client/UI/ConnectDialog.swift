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
    
    @State private var nick = "mike"
    @State private var server = "localhost"
    @State private var port = "6667"
    
    var body: some View {
        VStack {
            HStack {
                Text("Nick")
                TextField("", text: $nick)
            }
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
                    print("OK")
                    NotificationCenter.default.post(
                        name: .doConnectToServer,
                        object: ServerInfo(
                            nick: self.nick,
                            name: self.server,
                            server: self.server,
                            port: Int(self.port) ?? 0))
                    
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
