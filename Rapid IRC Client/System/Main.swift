//
//  Main.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/23/20.
//

import SwiftUI

@main
struct Main: App {
    
    init() {
        UserDefaults.standard.register(defaults: [
            AppSettings.timestampsInChat.rawValue: true,
            AppSettings.preferredNick.rawValue: "guest",
            AppSettings.realName.rawValue: "Rapid User"
        ])
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: ContentViewModel.viewModel(from: Store.instance))
        }.commands {
            AppCommands()
        }
        
        Settings {
            SettingsView()
        }
    }
}

struct AppCommands: Commands {
    
    @CommandsBuilder var body: some Commands {
        // replace the new window command with a connect command
        CommandGroup(replacing: .newItem) {
            Button(action: {
                NotificationCenter.default.post(name: .connectToServer, object: nil)
            }) {
                Text("Quick Connect")
            }.keyboardShortcut("C", modifiers: [.control, .shift])
        }
    }
}

enum AppSettings: String {
    case timestampsInChat = "timestampsInChat"
    case showJoinAndPartEvents = "showJoinAndPartEvents"
    case realName = "realName"
    case preferredNick = "preferredNick1"
    case username = "username"
}

extension Notification.Name {
    static let connectToServer = Notification.Name("connect_to_server")
}
