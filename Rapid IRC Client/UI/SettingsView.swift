//
//  SettingsView.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 1/17/21.
//

import SwiftUI

// MARK: - View

/// A view that presents user-configurable preferences.
struct SettingsView: View {
    
    @State private var selectedTab = Tabs.general
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(Tabs.general)
            
            SecuritySettingsView()
                .tabItem {
                    Label("Security", systemImage: "key")
                }
                .tag(Tabs.security)
        }
    }
}

// MARK: - Extensions
extension SettingsView {
    private enum Tabs: Hashable {
        case general
        case security
    }
}

// MARK: - Previews
struct SettingsView_Previews: PreviewProvider {
    
    static var previews: some View {
        SettingsView()
    }
}
