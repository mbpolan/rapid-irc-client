//
//  QuickConnectSheet.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/24/20.
//

import Combine
import Introspect
import SwiftUI

// MARK: - View

/// Sheet that presents fields for providing server connection information.
struct QuickConnectSheet: View {
    
    var onClose: (Result) -> Void
    
    @State private var nick = UserDefaults.standard.string(forKey: AppSettings.preferredNick.rawValue) ?? ""
    @State private var realName = UserDefaults.standard.string(forKey: AppSettings.realName.rawValue) ?? ""
    @State private var username = UserDefaults.standard.string(forKey: AppSettings.username.rawValue) ?? ""
    @State private var password = ""
    @State private var server = "localhost"
    @State private var port = "6667"
    
    var body: some View {
        VStack(alignment: .leading) {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(maximum: 100)),
                    GridItem(.flexible())
                ]) {
                
                Text("Nick")
                TextField("", text: $nick)
                    .introspectTextField { $0.becomeFirstResponder() }
                
                Text("Real Name")
                TextField("", text: $realName)
                
                Text("Server")
                TextField("", text: $server)
                
                Text("Port")
                TextField("", text: $port)
                
                Text("Password")
                SecureField("", text: $password)
            }
            
            Divider()
            
            HStack {
                Spacer()
                
                Button("Cancel") {
                    onClose(Result(accepted: false))
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Connect") {
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
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
    }
}

// MARK: - View extensions
extension QuickConnectSheet {
    
    /// Represents the results of the user dismissing the sheet.
    struct Result {
        var accepted: Bool
        var server: ServerInfo?
    }
}

// MARK: - Preview
struct ConnectDialog_Previews: PreviewProvider {
    static var previews: some View {
        QuickConnectSheet(
            onClose: { _ in })
    }
}
