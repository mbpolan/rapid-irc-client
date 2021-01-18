//
//  GeneralSettingsView.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 1/17/21.
//

import SwiftUI

struct GeneralSettingsView: View {
    
    @AppStorage(AppSettings.timestampsInChat.rawValue) private var storedShowTimestamps: Bool = true
    @AppStorage(AppSettings.realName.rawValue) private var storedRealName: String = ""
    @AppStorage(AppSettings.preferredNick.rawValue) private var storedPreferredNick1: String = ""
    
    private let profileColumns: [GridItem] = [
        GridItem(.flexible(maximum: 100)),
        GridItem(.flexible(maximum: 150))
    ]
    
    var body: some View {
        let showTimestamps = Binding<Bool>(
            get: { storedShowTimestamps },
            set: { shown in
                storedShowTimestamps = shown
                Store.instance.dispatch(.ui(.toggleChatTimestamps(shown: shown)))
            })
        
        Form {
            Section(header: Text("User Profile").font(.headline)) {
                LazyVGrid(
                    columns: profileColumns,
                    alignment: .leading) {
                    Text("Real Name")
                    TextField("", text: $storedRealName)
                    
                    Text("Preferred Nick")
                    TextField("", text: $storedPreferredNick1)
                }
            }
            
            Section(header: Text("Chat").font(.headline)) {
                Toggle("Show timestamps in chat", isOn: showTimestamps)
            }
        }
        .padding(20)
        .frame(width: 350, height: 200)
    }
}

struct GeneralSettings_Previews: PreviewProvider {
    
    static var previews: some View {
        GeneralSettingsView()
    }
}
