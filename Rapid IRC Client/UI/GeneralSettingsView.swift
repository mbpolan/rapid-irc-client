//
//  GeneralSettingsView.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 1/17/21.
//

import SwiftUI

struct GeneralSettingsView: View {
    
    @AppStorage(AppSettings.timestampsInChat.rawValue) private var showTimestamps: Bool = true
    @AppStorage(AppSettings.showJoinAndPartEvents.rawValue) private var showJoinAndPartEvents: Bool = true
    @AppStorage(AppSettings.realName.rawValue) private var realName: String = ""
    @AppStorage(AppSettings.preferredNick.rawValue) private var preferredNick1: String = ""
    @AppStorage(AppSettings.username.rawValue) private var username: String = ""
    
    private let profileColumns: [GridItem] = [
        GridItem(.flexible(maximum: 100)),
        GridItem(.flexible(maximum: 150))
    ]
    
    var body: some View {
        let showTimestampsBinding = Binding<Bool>(
            get: { showTimestamps },
            set: { shown in
                showTimestamps = shown
                Store.instance.dispatch(.ui(.toggleChatTimestamps(shown: shown)))
            })
        
        let showJoinAndPartEventsBinding = Binding<Bool>(
            get: { showJoinAndPartEvents },
            set: { shown in
                showJoinAndPartEvents = shown
                Store.instance.dispatch(.ui(.toggleJoinPartEvents(shown: shown)))
            })
        
        Form {
            Section(header: Text("User Profile").font(.headline)) {
                LazyVGrid(
                    columns: profileColumns,
                    alignment: .leading) {
                    Text("Real Name")
                    TextField("", text: $realName)
                    
                    Text("Preferred Nick")
                    TextField("", text: $preferredNick1)
                    
                    Text("Username")
                    TextField("(autodetect)", text: $username)
                }
            }
            
            Section(header: Text("Chat").font(.headline)) {
                Toggle("Show timestamps in chat", isOn: showTimestampsBinding)
                Toggle("Show users joining and leaving", isOn: showJoinAndPartEventsBinding)
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
