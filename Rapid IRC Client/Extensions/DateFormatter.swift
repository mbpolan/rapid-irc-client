//
//  DateFormatter.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 1/24/21.
//

import Foundation

extension DateFormatter {
    
    static var displayDateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.setLocalizedDateFormatFromTemplate("dd MMM YYYY HH:mm:ss")
        
        return dateFormatter
    }
}
