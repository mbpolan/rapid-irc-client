//
//  Main.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/23/20.
//

import SwiftUI

@main
struct Main: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: ContentViewModel.viewModel(from: Store.instance))
        }.commands {
            AppCommands()
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
                Text("Connect")
            }.keyboardShortcut("C", modifiers: [.option])
        }
    }
}

extension Notification.Name {
    static let connectToServer = Notification.Name("connect_to_server")
}
