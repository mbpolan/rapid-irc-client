//
//  ServersSettingsView.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 1/17/21.
//

import SwiftUI

// MARK: - View

/// View for displaying user preferences related to saved IRC servers.
struct ServerSettingsView: View {
    
    @AppStorage(AppSettings.savedServers.rawValue) private var servers: SavedServerInfoList = SavedServerInfoList()
    @State private var selection: Bool = false
    @State private var selectedServer: SavedServerInfo = .empty
    
    var body: some View {
        let selectedServerBinding = Binding<SavedServerInfo?>(
            get: { self.selectedServer },
            set: { value in
                self.selection = value != nil
                self.selectedServer = value ?? .empty
            }
        )
        
        return HStack {
            ServerListView(servers: $servers, selectedServer: selectedServerBinding)
                .border(Color(red: 0.3, green: 0.3, blue: 0.3, opacity: 1.0), width: 1)
                .frame(minWidth: 150, maxWidth: 150, minHeight: 320)
                .padding(.trailing, 5)
                .fixedSize()
            
            HStack {
                if selection {
                    ServerRowView(server: selectedServer)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Text("No server selected")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .border(Color(red: 0.3, green: 0.3, blue: 0.3, opacity: 1.0))
        }
        .padding()
        .frame(width: 600, height: 350, alignment: .top)
    }
}

// MARK: - ServerListView

/// View for displaying and manipulating a list of servers.
struct ServerListView: View {
    
    @Binding var servers: [SavedServerInfo]
    @Binding var selectedServer: SavedServerInfo?
    
    var body: some View {
        VStack(alignment: .leading) {
            ScrollView {
                ForEach(servers, id: \.id) { server in
                    HStack {
                        Text(server.label)
                            .foregroundColor(server.id == selectedServer?.id ? .white : .primary)
                            .padding(.leading, 5)
                        
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .frame(maxWidth: .infinity, minHeight: 25)
                    .background(server.id == selectedServer?.id ? Color.accentColor : Color.clear)
                    .onTapGesture {
                        self.selectedServer = server
                    }
                }
            }

            HStack(alignment: .center) {
                Button(action: handleAddServer) {
                    Image(systemName: "plus")
                }
                .buttonStyle(BorderlessButtonStyle())

                Button(action: handleRemoveServer) {
                    Image(systemName: "minus")
                }
                .buttonStyle(BorderlessButtonStyle())
                .disabled(selectedServer == nil)

                Spacer()
            }
            .padding(5)
        }
    }
    
    private func handleAddServer() {
        servers.append(SavedServerInfo(
                        id: UUID(),
                        label: "New Server",
                        secure: false,
                        sslVerificationMode: .disabled,
                        nick: "Guest",
                        realName: "Rapid IRC User",
                        username: "",
                        host: "irc.example.com",
                        port: "6667",
                        password: ""))
    }

    private func handleRemoveServer() {
        if let selectedServer = selectedServer,
           let idx = servers.firstIndex(where: { $0.id == selectedServer.id }) {
            servers.remove(at: idx)
        }
    }
}

// MARK: - ServerRowView

/// View for displaying editing controls for a server.
struct ServerRowView: View {
    
    @ObservedObject var server: SavedServerInfo
    
    private let columns = [
        GridItem(.fixed(100)),
        GridItem(.fixed(200))
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            LazyVGrid(columns: columns, alignment: .leading) {
                Group {
                    Text("Label")
                    TextField("", text: $server.label)
                }
                
                Group {
                    Text("Host")
                    TextField("(hostname)", text: $server.host)
                    
                    Text("Port")
                    TextField("(port)", text: $server.port)
                }
                
                Group {
                    Text("Nick")
                    TextField("(nick)", text: $server.nick)
                    
                    Text("Real Name")
                    TextField("(real name)", text: $server.realName)
                }
                
                Group {
                    Text("Username")
                    TextField("(autodetect)", text: $server.username)
                    
                    Text("Password")
                    TextField("(optional)", text: $server.password)
                }
            }
            
            Toggle(isOn: $server.secure) {
                Text("Secure connection using encrytion")
            }
            
            Picker(selection: $server.sslVerificationMode, label: Text("Verify SSL Certificates")) {
                ForEach(SSLVerificationMode.allCases, id: \.self) { mode in
                    switch mode {
                    case .full:
                        Text("Full Verification")
                    case .ignoreHostnames:
                        Text("Ignore Hostnames")
                    case .disabled:
                        Text("No Verification")
                    }
                }
            }
            .scaledToFit()
        }
        .padding()
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Model

/// Model that represents a recorded IRC server.
class SavedServerInfo: Identifiable, ObservableObject, Codable {
    
    enum CodingKeys: CodingKey {
        case id
        case label
        case secure
        case sslVerificationMode
        case nick
        case realName
        case username
        case host
        case port
        case password
    }
    
    let id: UUID
    @Published var label: String
    @Published var secure: Bool
    @Published var sslVerificationMode: SSLVerificationMode
    @Published var nick: String
    @Published var realName: String
    @Published var username: String
    @Published var host: String
    @Published var port: String
    @Published var password: String
    
    init(id: UUID,
         label: String,
         secure: Bool,
         sslVerificationMode: SSLVerificationMode,
         nick: String,
         realName: String,
         username: String,
         host: String,
         port: String,
         password: String) {
        
        self.id = id
        self.label = label
        self.secure = secure
        self.sslVerificationMode = sslVerificationMode
        self.nick = nick
        self.realName = realName
        self.username = username
        self.host = host
        self.port = port
        self.password = password
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.label = try container.decode(String.self, forKey: .label)
        self.secure = try container.decode(Bool.self, forKey: .secure)
        self.sslVerificationMode = try container.decode(SSLVerificationMode.self, forKey: .sslVerificationMode)
        self.nick = try container.decode(String.self, forKey: .nick)
        self.realName = try container.decode(String.self, forKey: .realName)
        self.username = try container.decode(String.self, forKey: .username)
        self.host = try container.decode(String.self, forKey: .host)
        self.port = try container.decode(String.self, forKey: .port)
        self.password = try container.decode(String.self, forKey: .password)
    }
    
    static var empty: SavedServerInfo {
        SavedServerInfo(
            id: UUID(),
            label: "",
            secure: false,
            sslVerificationMode: .disabled,
            nick: "",
            realName: "",
            username: "",
            host: "",
            port: "",
            password: "")
    }
    
    static func == (lhs: SavedServerInfo, rhs: SavedServerInfo) -> Bool {
        return lhs.id == rhs.id &&
            lhs.label == rhs.label &&
            lhs.secure == rhs.secure &&
            lhs.sslVerificationMode == rhs.sslVerificationMode &&
            lhs.nick == rhs.nick &&
            lhs.realName == rhs.realName &&
            lhs.username == rhs.username &&
            lhs.host == rhs.host &&
            lhs.port == rhs.port &&
            lhs.password == rhs.password
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(label, forKey: .label)
        try container.encode(secure, forKey: .secure)
        try container.encode(sslVerificationMode, forKey: .sslVerificationMode)
        try container.encode(nick, forKey: .nick)
        try container.encode(realName, forKey: .realName)
        try container.encode(username, forKey: .username)
        try container.encode(host, forKey: .host)
        try container.encode(port, forKey: .port)
        try container.encode(password, forKey: .password)
    }
}

typealias SavedServerInfoList = [SavedServerInfo]

extension SavedServerInfoList: RawRepresentable {
    public init?(rawValue: String) {
            guard let data = rawValue.data(using: .utf8),
                let result = try? JSONDecoder().decode(SavedServerInfoList.self, from: data) else {
                return nil
            }
        
            self = result
        }

        public var rawValue: String {
            guard let data = try? JSONEncoder().encode(self),
                let result = String(data: data, encoding: .utf8) else {
                return "[]"
            }
            
            return result
        }
}

// MARK: - Preview
struct ServerSettingsView_Previews: PreviewProvider {
    
    static var previews: some View {
        ServerSettingsView()
    }
}
