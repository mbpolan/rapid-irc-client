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
    @State private var username = UserDefaults.standard.string(forKey: AppSettings.username.rawValue) ?? ""
    @State private var password = ""
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
                
                Text("Password")
                SecureField("", text: $password)
            }
            
            HStack {
                Spacer()
                
                Button("Connect") {
                    self.shown = false
                    
                    // default to the system username if not provided
                    let effectiveUsername = username.isEmptyOrWhitespace ? NSUserName() : username
                    
                    onClose(Result(
                        accepted: true,
                        server: ServerInfo(
                            nick: nick.trimmingCharacters(in: .whitespaces),
                            realName: realName.trimmingCharacters(in: .whitespaces),
                            username: effectiveUsername.trimmingCharacters(in: .whitespaces),
                            host: server.trimmingCharacters(in: .whitespaces),
                            port: Int(port) ?? -1,
                            password: password)))
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
