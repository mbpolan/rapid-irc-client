//
//  Main.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/23/20.
//

import SwiftUI

@main
struct Main: App {
    
    private let coordinator: Coordinator
    private let onSavedServersChanged = NotificationCenter.default.publisher(for: .savedServersChanged)
    
    @Environment(\.scenePhase) private var scenePhase: ScenePhase
    @State private var servers: [SavedServerInfo] = UserDefaults.standard.savedServerInfo()
    
    init() {
        self.coordinator = Coordinator()
        
        UserDefaults.standard.register(defaults: [
            AppSettings.timestampsInChat.rawValue: true,
            AppSettings.preferredNick.rawValue: "guest",
            AppSettings.realName.rawValue: "Rapid User"
        ])
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: ContentViewModel.viewModel(from: Store.instance))
                .onReceive(onSavedServersChanged) { _ in
                    servers = UserDefaults.standard.savedServerInfo()
                }
        }
        .windowToolbarStyle(UnifiedCompactWindowToolbarStyle())
        .commands {
            AppCommands(servers: $servers)
        }
        
        Settings {
            SettingsView()
        }
    }
}

extension Main {
    
    class Coordinator {
        
        init() {
            NSWorkspace.shared.notificationCenter.addObserver(
                self,
                selector: #selector(handleWillSleepNotification(note:)),
                name: NSWorkspace.willSleepNotification,
                object: nil)
            
            NSWorkspace.shared.notificationCenter.addObserver(
                self,
                selector: #selector(handleWakeNotification(note:)),
                name: NSWorkspace.didWakeNotification,
                object: nil)
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleWillSleepNotification(note:)),
                name: .debugSimulateSleep,
                object: nil)
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleWakeNotification(note:)),
                name: .debugSimulateWake,
                object: nil)
        }
        
        @objc private func handleWillSleepNotification(note: NSNotification) {
            let group = DispatchGroup()
            group.enter()
            
            // save the current snapshot of our connections, then forcefully disconnect from all servers
            Store.instance.dispatch(.snapshot(.save {
                Store.instance.dispatch(.network(.disconnectAllForSleep {
                    group.leave()
                }))
            }))
            
            group.wait()
        }
        
        @objc private func handleWakeNotification(note: NSNotification) {
            // restore the previously saved application state
            Store.instance.dispatch(.snapshot(.restore))
        }
    }
}

struct AppCommands: Commands {
    
    @Binding var servers: [SavedServerInfo]
    
    @CommandsBuilder var body: some Commands {
        // replace the new command with a submenu of saved servers
        CommandGroup(replacing: .newItem) {
            Menu("Connect To...") {
                ForEach(servers, id: \.id) { server in
                    Button(server.label) {
                        NotificationCenter.default.post(name: .connectToServer, object: server)
                    }
                }
            }
        }
        
        // replace the save command with a connect command
        CommandGroup(replacing: .saveItem) {
            Button("Quick Connect") {
                NotificationCenter.default.post(name: .quickConnect, object: nil)
            }.keyboardShortcut("C", modifiers: [.control, .shift])
        }
        
        CommandMenu("Debug") {
            Button("Simulate Sleep") {
                NotificationCenter.default.post(name: .debugSimulateSleep, object: nil)
            }
            
            Button("Simulate Wake") {
                NotificationCenter.default.post(name: .debugSimulateWake, object: nil)
            }
        }
    }
}

enum AppSettings: String {
    case timestampsInChat = "timestampsInChat"
    case showJoinAndPartEvents = "showJoinAndPartEvents"
    case realName = "realName"
    case preferredNick = "preferredNick1"
    case username = "username"
    case sslVerificationMode = "sslVerificationMode"
    case savedServers = "savedServers"
}

enum SSLVerificationMode: Int, Identifiable, CaseIterable, Codable {
    case full
    case ignoreHostnames
    case disabled
    
    var id: Int {
        rawValue
    }
}

extension UserDefaults {
    
    func sslVerificationModeOrDefault() -> SSLVerificationMode {
        if let mode = SSLVerificationMode(rawValue: integer(forKey: AppSettings.sslVerificationMode.rawValue)) {
            return mode
        }
        
        return .full
    }
    
    func savedServerInfo() -> [SavedServerInfo] {
        // if an existing user preference exists, deserialize it as a json string
        if let savedData = UserDefaults.standard.data(forKey: AppSettings.savedServers.rawValue),
           let data = try? JSONDecoder().decode([SavedServerInfo].self, from: savedData) {
            return data
        }
        
        return []
    }
    
    func setSavedServerInfo(_ servers: [SavedServerInfo]) {
        // serialize the list of servers as a json string and save it to user defaults
        if let rawData = try? JSONEncoder().encode(servers) {
            UserDefaults.standard.set(rawData,
                                      forKey: AppSettings.savedServers.rawValue)
        }
    }
    
    func stringOrDefault(_ key: AppSettings) -> String {
        return string(forKey: key.rawValue) ?? ""
    }
}

extension Notification.Name {
    static let connectToServer = Notification.Name("connect_to_server")
    static let quickConnect = Notification.Name("quick_connect")
    
    static let savedServersChanged = Notification.Name("saved_servers_changed")
    
    static let debugSimulateSleep = Notification.Name("debug_simulate_sleep")
    static let debugSimulateWake = Notification.Name("debug_simulate_wake")
}
