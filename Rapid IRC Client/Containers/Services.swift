//
//  Services.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/24/20.
//

import Foundation

extension DIContainer {
    struct Services {
        
        let connectionService: ConnectionService
        
        static var stub: Self {
            .init(connectionService: StubConnectionService())
        }
        
        init(connectionService: ConnectionService) {
            self.connectionService = connectionService
        }
    }
}
