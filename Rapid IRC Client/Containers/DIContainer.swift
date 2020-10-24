//
//  DIContainer.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/24/20.
//

import SwiftUI
import Combine

struct DIContainer: EnvironmentKey {
    
    let services: Services
    
    static var defaultValue: Self { Self.default }
    
    private static let `default` = DIContainer(services: Services.stub)
    
    init(services: DIContainer.Services) {
        self.services = services
    }
}
