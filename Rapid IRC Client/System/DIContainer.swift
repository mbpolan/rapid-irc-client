//
//  DIContainer.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/24/20.
//

import Combine
import Swinject

class DIContainer: ObservableObject {
    
    var container: Container?
    
    init() {
        container = nil
    }
    
    init(container: Container) {
        self.container = container
    }
}
