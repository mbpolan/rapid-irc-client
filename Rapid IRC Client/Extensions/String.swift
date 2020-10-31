//
//  String.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/31/20.
//

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
}
