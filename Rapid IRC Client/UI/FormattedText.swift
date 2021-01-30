//
//  FormattedText.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 1/29/21.
//

import SwiftUI

struct FormattedText: View {
    
    private let text: String
    
    private let colors: Dictionary<UInt16, Palette> = [
        0: .white,
        1: .black,
        2: .blue,
        3: .green,
        4: .red,
        5: .brown,
        6: .magenta,
        7: .orange,
        8: .yellow,
        9: .lightGreen,
        10: .cyan,
        11: .lightCyan,
        12: .lightBlue,
        13: .pink,
        14: .grey,
        15: .lightGrey,
        99: .none
    ]
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        let views = makeText()
        
        // since various formats can produce mixed views, we need to lay them out
        // in a row inside an HStack instead
        HStack(spacing: 0) {
            ForEach(0..<views.count, id: \.self) { i in
                views[i]
            }
        }
    }
    
    private func makeText() -> [AnyView] {
        var views: [AnyView] = []
        var formatting = TextFormatter()
        var current = ""
        
        var i = text.startIndex
        while i < text.endIndex {
            let ch = text[i]
            
            switch ch.asciiValue {
            // controls foreground and optionally background text color
            case 0x03:
                // is a color already active?
                if formatting.fgColor != nil || !current.isEmpty {
                    views.append(formatting.apply(current))
                    current = ""
                    formatting.fgColor = nil
                }
                
                i = text.index(after: i)
                
                // is the following byte an ascii digit?
                if let fgChar1 = text.peek(i),
                   let fgByte1 = UInt16(fgChar1) {
                    
                    var fgCode = fgByte1
                    i = text.index(after: i)
                    
                    // is the next byte after that also an ascii digit?
                    if let fgChar2 = text.peek(i),
                       let fgByte2 = UInt16(fgChar2) {
                       
                        fgCode = (fgCode * 10) + fgByte2
                        i = text.index(after: i)
                    }
                    
                    formatting.fgColor = (colors[fgCode] ?? .none).toColor()
                    
                    // if the next sequence of bytes is an ascii comma followed by an ascii digit,
                    // then we treat that as a background color
                    if let bgSeparator = text.peek(i), bgSeparator == ",",
                       let bgChar1 = text.peek(i, offsetBy: 1),
                       let bgByte1 = UInt16(bgChar1) {
                        
                        var bgCode = bgByte1
                        i = text.index(i, offsetBy: 2)
                        
                        // is the next byte also an ascii digit?
                        if let bgChar2 = text.peek(i),
                           let bgByte2 = UInt16(bgChar2) {
                            
                            bgCode = (bgCode * 10) + bgByte2
                            i = text.index(after: i)
                        }
                        
                        formatting.bgColor = (colors[bgCode] ?? .none).toColor()
                    }
                        
                } else {
                    // no digit character - reset both foreground and background colors
                    formatting.fgColor = nil
                    formatting.bgColor = nil
                }
            
            // no formatting; take the character as-is
            default:
                current.append(ch)
                i = text.index(after: i)
            }
        }
        
        if !current.isEmpty {
            views.append(formatting.apply(current))
        }
        
        return views
    }
}

extension FormattedText {
    
    enum Palette: String {
        case white      = "#FFFFFF"
        case black      = "#000000"
        case blue       = "#05007F"
        case green      = "#029303"
        case red        = "#FF0102"
        case brown      = "#800002"
        case magenta    = "#9C009C"
        case orange     = "#FC7F00"
        case yellow     = "#FEFF00"
        case lightGreen = "#02FC00"
        case cyan       = "#029393"
        case lightCyan  = "#08FEFF"
        case lightBlue  = "#1300FC"
        case pink       = "#FF02FF"
        case grey       = "#7F7F7F"
        case lightGrey  = "#D2D2D2"
        case none       = ""
        
        func toColor() -> Color? {
            var hex = self.rawValue.dropFirst()
            guard let red = UInt8(hex.prefix(2), radix: 16) else { return .none }
            hex = hex.dropFirst(2)
            
            guard let green = UInt8(hex.prefix(2), radix: 16) else { return .none }
            hex = hex.dropFirst(2)
            
            guard let blue = UInt8(hex.prefix(2), radix: 16) else { return .none }
            
            return Color(
                red: Double(red) / 255.0,
                green: Double(green) / 255.0,
                blue: Double(blue) / 255.0,
                opacity: 1.0)
        }
    }
    
    struct TextFormatter {
        
        var bgColor: Color?
        var fgColor: Color?
        
        func apply(_ str: String) -> AnyView {
            var text = Text(str)
            
            // apply foreground color to the text view directly
            if let fgColor = fgColor {
                text = text.foregroundColor(fgColor)
            }
            
            // background color requires a separate view
            if let bgColor = bgColor {
                return AnyView(text.background(bgColor))
            }
            
            return AnyView(text)
        }
    }
}

struct FormattedText_Previews: PreviewProvider {
    
    static var previews: some View {
        FormattedText("this is \u{03}03,08green\u{03} and \u{03}red?\u{03} eyy")
    }
}
