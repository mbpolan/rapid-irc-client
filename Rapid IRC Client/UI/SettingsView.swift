//
//  SettingsView.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 1/17/21.
//

import SwiftUI

struct SettingsView: View {
    
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(Tabs.general)
            
//            ServerSettingsView()
//                .tabItem {
//                    Label("Servers", systemImage: "network")
//                }
//                .tag(Tabs.servers)
        }
    }
}

extension SettingsView {
    private enum Tabs: Hashable {
        case general
        case servers
    }
}

struct SettingsView_Previews: PreviewProvider {
    
    static var previews: some View {
        SettingsView()
    }
}
