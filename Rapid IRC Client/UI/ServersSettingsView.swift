//
//  ServersSettingsView.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 1/17/21.
//

import SwiftUI

struct ServerSettingsView: View {
    
    var body: some View {
        Form {
            Text("Configure servers to connect to automatically")
        }
        .padding(20)
        .frame(width: 350, height: 150, alignment: .top)
    }
}

struct ServerSettingsView_Previews: PreviewProvider {
    
    static var previews: some View {
        ServerSettingsView()
    }
}
