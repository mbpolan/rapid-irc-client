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
        var views: [ViewHolder] = []
        var formatting = TextFormatter()
        var current = ""
        
        var i = text.startIndex
        while i < text.endIndex {
            let ch = text[i]
            
            switch ch.asciiValue {
            // toggles bold font
            case 0x02:
                if formatting.bold || !current.isEmpty {
                    views.append(formatting.apply(current))
                    current = ""
                }
                
                formatting.bold = !formatting.bold
                i = text.index(after: i)
                
            // toggles italics font
            case 0x1D:
                if formatting.italics || !current.isEmpty {
                    views.append(formatting.apply(current))
                    current = ""
                }
                
                formatting.italics = !formatting.italics
                i = text.index(after: i)
                
            // toggles strikethrough font
            case 0x1E:
                if formatting.strikethrough || !current.isEmpty {
                    views.append(formatting.apply(current))
                    current = ""
                }
                
                formatting.strikethrough = !formatting.strikethrough
                i = text.index(after: i)
                
            // toggles underline font
            case 0x1F:
                if formatting.underline || !current.isEmpty {
                    views.append(formatting.apply(current))
                    current = ""
                }
                
                formatting.underline = !formatting.underline
                i = text.index(after: i)
                
            // invert foreground and background colors
            case 0x16:
                if formatting.inverted || !current.isEmpty {
                    views.append(formatting.apply(current))
                    current = ""
                }
                
                formatting.inverted = !formatting.inverted
                i = text.index(after: i)
                
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
            
            // reset all formatting
            case 0x0F:
                // apply any currently buffered formatted text
                if !current.isEmpty {
                    views.append(formatting.apply(current))
                    current = ""
                }
                
                formatting = TextFormatter()
                i = text.index(after: i)
            
            // no formatting; take the character as-is
            default:
                current.append(ch)
                i = text.index(after: i)
            }
        }
        
        // apply any remaining text formatting into our ongoing message
        if !current.isEmpty {
            views.append(formatting.apply(current))
        }
        
        // merge consecutive text views into as few instances as possible. plain views remain as-is
        // since those cannot be reliably merged.
        var consolidated: [ViewHolder] = []
        views.forEach { view in
            if consolidated.isEmpty {
                consolidated.append(view)
            } else if view.view != nil {
                consolidated.append(view)
            } else if view.text != nil {
                // if the previous view is a text view, we can merge the two
                // together to reduce nesting of views
                if let previous = consolidated.last, previous.text != nil {
                    consolidated = consolidated.dropLast()
                    consolidated.append(previous.mergeText(view))
                } else {
                    consolidated.append(view)
                }
            }
        }
        
        return consolidated.map { $0.toErasedView() }
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
    
    struct ViewHolder {
        
        var text: Text?
        var view: AnyView?
        
        func toErasedView() -> AnyView {
            if let text = self.text {
                return AnyView(text)
            } else if let view = self.view {
                return AnyView(view)
            } else {
                return AnyView(EmptyView())
            }
        }
        
        func mergeText(_ other: ViewHolder) -> ViewHolder {
            guard let ourText = self.text else {
                return self
            }
            
            guard let theirText = other.text else {
                return self
            }
            
            return ViewHolder(text: ourText + theirText)
        }
    }
    
    struct TextFormatter {
        
        var bgColor: Color?
        var fgColor: Color?
        var inverted: Bool = false
        var bold: Bool = false
        var italics: Bool = false
        var underline: Bool = false
        var strikethrough: Bool = false
        
        func apply(_ str: String) -> ViewHolder {
            var text = Text(str)
            
            // apply bold font face
            if bold {
                text = text.bold()
            }
            
            // apply italics
            if italics {
                text = text.italic()
            }
            
            // apply underline decoration
            if underline {
                text = text.underline()
            }
            
            // apply strikethrough decoration
            if strikethrough {
                text = text.strikethrough()
            }
            
            var realFgColor = fgColor
            var realBgColor = bgColor
            
            // when colors are inverted, we need to assign actual colors when none
            // are specified. for this, we can default to the system text foreground
            // and background colors.
            if inverted {
                realFgColor = bgColor ?? Color(NSColor.textBackgroundColor)
                realBgColor = fgColor ?? Color(NSColor.textColor)
            }
            
            // apply foreground color to the text view directly
            if let fgColor = realFgColor {
                text = text.foregroundColor(fgColor)
            }
            
            // background color requires a separate view, so we need to apply it last
            if let bgColor = realBgColor {
                return ViewHolder(view: AnyView(text.background(bgColor)))
            }
            
            return ViewHolder(text: text)
        }
    }
}

struct FormattedText_Previews: PreviewProvider {
    
    static var previews: some View {
        VStack {
            FormattedText("this is \u{03}03,08green\u{03} lorem ipsum")
            FormattedText("this is \u{03}04red\u{03} lorem ipsum")
            FormattedText("this is \u{02}bold\u{02} and \u{1D}italics\u{1D} lorem ipsum")
            FormattedText("this is \u{1F}underlined\u{1F} and \u{1E}strikethrough\u{1E} lorem ipsum")
            FormattedText("this is \u{16}defaults reversed\u{16} lorem ipsum")
            FormattedText("this is \u{03}03\u{16}foreground reversed\u{16}\u{03} lorem ipsum")
            FormattedText("this is \u{03}03,08\u{16}both reversed\u{16}\u{03} lorem ipsum")
        }
    }
}
