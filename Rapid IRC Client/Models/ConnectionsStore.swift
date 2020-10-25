//
//  ConnectionsState.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/24/20.
//

import Combine
import SwiftUI

final class ConnectionsStore: ObservableObject {
    
    @Published var connections: [ServerConnection] = []
    @Published var currentConnection: UUID?
}
