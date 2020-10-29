//
//  Dialogs.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/24/20.
//

import Combine
import SwiftUI

struct ConnectDialog: View {

    @Binding var shown: Bool
    var onClose: (Result) -> Void

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
            }
            HStack {
                Spacer()
                Button("OK") {
                    print("OK")
                    self.shown = false
                    onClose(Result(
                        accepted: true,
                        server: ServerInfo(
                            nick: nick,
                            host: server,
                            port: Int(port) ?? -1)))
                }
                Button("Cancel") {
                    self.shown = false
                    onClose(Result(accepted: false))
                }
            }
        }.padding()
    }
}

extension ConnectDialog {
    struct Result {
        var accepted: Bool
        var server: ServerInfo?
    }
}

//struct ConnectDialog_Previews: PreviewProvider {
//    static var previews: some View {
//
//        var result = ConnectDialog.Result(
//            shown: false,
//            server: ServerInfo(
//                nick: "",
//                host: "",
//                port: -1))
//
//        return ConnectDialog(result: $result)
//    }
//}
