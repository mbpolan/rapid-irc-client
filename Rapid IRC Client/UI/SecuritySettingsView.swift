//
//  SecuritySettingsView.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 2/21/21.
//

import SwiftUI

// MARK: - View

/// A view that presents security related preferences.
struct SecuritySettingsView: View {
    
    @AppStorage(AppSettings.sslVerificationMode.rawValue) private var verificationMode: SSLVerificationMode = .full
    
    var body: some View {
        Form {
            Picker(selection: $verificationMode, label: Text("Verify SSL Certificates")) {
                ForEach(SSLVerificationMode.allCases, id: \.self) { mode in
                    switch mode {
                    case .full:
                        Text("Full Verification")
                    case .ignoreHostnames:
                        Text("Ignore Hostnames")
                    case .disabled:
                        Text("No Verification")
                    }
                }
            }
        }
        .padding(20)
        .frame(width: 350, height: 100)
    }
}

// MARK: - Preview
struct SecuritySettingsView_Previews: PreviewProvider {
    
    static var previews: some View {
        SecuritySettingsView()
    }
}
