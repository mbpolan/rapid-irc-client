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

    @State private var nick = UserDefaults.standard.string(forKey: AppSettings.preferredNick.rawValue) ?? ""
    @State private var realName = UserDefaults.standard.string(forKey: AppSettings.realName.rawValue) ?? ""
    @State private var server = "localhost"
    @State private var port = "6667"

    var body: some View {
        VStack {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(maximum: 100)),
                    GridItem(.flexible()),
                ]) {
                
                Text("Nick")
                TextField("", text: $nick)
                
                Text("Real Name")
                TextField("", text: $realName)
                
                Text("Server")
                TextField("", text: $server)
                
                Text("Port")
                TextField("", text: $port)
            }
            
            HStack {
                Spacer()
                
                Button("Connect") {
                    self.shown = false
                    
                    onClose(Result(
                        accepted: true,
                        server: ServerInfo(
                            nick: nick,
                            realName: realName,
                            host: server,
                            port: Int(port) ?? -1)))
                }
                
                Button("Cancel") {
                    self.shown = false
                    onClose(Result(accepted: false))
                }
            }
        }
        .padding()
    }
}

extension ConnectDialog {
    struct Result {
        var accepted: Bool
        var server: ServerInfo?
    }
}

struct ConnectDialog_Previews: PreviewProvider {
    static var previews: some View {
        let shown = Binding<Bool>(
            get: { true },
            set: { _ in })
        
        ConnectDialog(
            shown: shown,
            onClose: { _ in })
    }
}
