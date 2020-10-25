//
//  Connection.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/24/20.
//

import Combine
import SwiftUI
import NIO

class ServerConnection: ObservableObject, Identifiable {

    let id = UUID()
    var info: ServerInfo
    var channel: Channel?
    @Published var serverChannel: IRCChannel

    private var cancellables = [AnyCancellable]()

    init(info: ServerInfo, serverChannel: IRCChannel) {
        self.info = info
        self.serverChannel = serverChannel

        cancellables.append(self.serverChannel.objectWillChange.sink { _ in self.objectWillChange.send() })
    }
}
