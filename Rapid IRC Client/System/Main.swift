//
//  Main.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/23/20.
//

import SwiftUI

@main
struct Main: App {
    
    @Environment(\.scenePhase) private var scenePhase: ScenePhase
    private let coordinator: Coordinator
    
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
        }
        .commands {
            AppCommands()
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
    
    @CommandsBuilder var body: some Commands {
        // replace the new window command with a connect command
        CommandGroup(replacing: .newItem) {
            Button("Quick Connect") {
                NotificationCenter.default.post(name: .connectToServer, object: nil)
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
}

enum SSLVerificationMode: Int, Identifiable, CaseIterable {
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
    
    func stringOrDefault(_ key: AppSettings) -> String {
        return string(forKey: key.rawValue) ?? ""
    }
}

extension Notification.Name {
    static let connectToServer = Notification.Name("connect_to_server")
    
    static let debugSimulateSleep = Notification.Name("debug_simulate_sleep")
    static let debugSimulateWake = Notification.Name("debug_simulate_wake")
}
