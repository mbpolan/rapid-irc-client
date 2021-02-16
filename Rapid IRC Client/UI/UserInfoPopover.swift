//
//  UserInfoPopover.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 2/15/21.
//

import SwiftUI

// MARK: - View

/// A popover that shows some basic information about an IRC user.
struct UserInfoPopover: View {
    
    var nick: String
    var privilege: String
    
    var body: some View {
        let popoverGrid = [
            GridItem(.fixed(70), spacing: 5),
            GridItem(.fixed(100), spacing: 5)
        ]
        
        let cells = [
            "Nick",
            nick,
            "Privilege",
            privilege
        ]
        
        return LazyVGrid(
            columns: popoverGrid,
            alignment: .leading,
            spacing: 5,
            pinnedViews: []) {
            ForEach(cells, id: \.self) { cell in
                Text(cell)
            }
        }.padding()
    }
}

// MARK: - Preview
struct UserInfoPopover_Previews: PreviewProvider {
    
    static var previews: some View {
        UserInfoPopover(
            nick: "mike",
            privilege: "Operator")
    }
}
