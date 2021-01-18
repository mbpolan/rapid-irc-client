//
//  String.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/31/20.
//

import Foundation

extension String {
    func subString(from: Int) -> String {
        let startIndex = self.index(self.startIndex, offsetBy: from)
        let endIndex = self.index(self.startIndex, offsetBy: self.count - 1)

        return String(self[startIndex...endIndex])
    }

    func subString(from: Int, to: Int) -> String {
        let startIndex = self.index(self.startIndex, offsetBy: from)
        let endIndex = self.index(self.startIndex, offsetBy: to)

        return String(self[startIndex...endIndex])
    }
    
    func dropLeadingColon() -> String {
        if first == ":" {
            return String(dropFirst())
        }
        
        return self
    }
    
    var isEmptyOrWhitespace: Bool {
        return isEmpty || trimmingCharacters(in: .whitespaces).isEmpty
    }

    var isNumber: Bool {
        return !isEmpty && rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
}
