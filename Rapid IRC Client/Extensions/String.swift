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

    // swiftlint:disable identifier_name
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
    
    func peek(_ index: String.Index, amount: UInt = 1, offsetBy: Int = 0) -> String? {
        var str = ""
        var charIndex = 0
        var idx = self.index(index, offsetBy: offsetBy)
        
        while charIndex < amount {
            // end of string? return nil to indicate this operation is out of bounds
            if idx == self.endIndex {
                return nil
            }
            
            str.append(self[idx])
            idx = self.index(after: idx)
            charIndex += 1
        }
        
        return str
    }
    
    var isEmptyOrWhitespace: Bool {
        return isEmpty || trimmingCharacters(in: .whitespaces).isEmpty
    }

    var isNumber: Bool {
        return !isEmpty && rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
}
