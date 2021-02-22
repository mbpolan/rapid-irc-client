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
    
    @State private var nick = UserDefaults.standard.stringOrDefault(AppSettings.preferredNick)
    @State private var realName = UserDefaults.standard.stringOrDefault(AppSettings.realName)
    @State private var username = UserDefaults.standard.stringOrDefault(AppSettings.username)
    @State private var password = ""
    @State private var server = "localhost"
    @State private var port = "6667"
    @State private var secure = false
    
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
                SecureField("(optional)", text: $password)
            }
            
            Toggle(isOn: $secure) {
                Text("Secure connection using encrytion")
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
                    let sslVerificationMode = UserDefaults.standard.sslVerificationModeOrDefault()
                    
                    onClose(Result(
                                accepted: true,
                                server: ServerInfo(
                                    secure: secure,
                                    sslVerificationMode: sslVerificationMode,
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
