//
//  OperatorLoginSheet.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 1/27/21.
//

import SwiftUI

// MARK: - View
struct OperatorLoginSheet: View {
    
    @State private var username: String = ""
    @State private var password: String = ""
    var onClose: (Result) -> Void
    
    var body: some View {
        VStack {
            LazyVGrid(columns: [
                GridItem(.flexible(maximum: 100)),
                GridItem(.flexible())
            ]) {
                Text("Username")
                TextField("", text: $username)
                
                Text("Password")
                SecureField("", text: $password)
            }
            
            Divider()
            
            HStack {
                Spacer()
                
                Button("Cancel") {
                    onClose(Result(
                                accepted: false,
                                credentials: nil))
                }
                .keyboardShortcut(.cancelAction)
                
                Button("OK") {
                    onClose(Result(
                                accepted: true,
                                credentials: Credentials(
                                    username: username,
                                    password: password)))
                    
                    self.username = ""
                    self.password = ""
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
    }
}

// MARK: - Extensions
extension OperatorLoginSheet {
    
    struct Result {
        var accepted: Bool
        var credentials: Credentials?
    }
    
    struct Credentials {
        var username: String
        var password: String
    }
}

// MARK: - Preview
struct OperatorLoginSheet_Previews: PreviewProvider {
    
    static var previews: some View {
        OperatorLoginSheet(onClose: { _ in })
    }
}
