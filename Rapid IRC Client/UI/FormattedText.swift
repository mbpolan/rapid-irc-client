//
//  FormattedText.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 1/29/21.
//

import SwiftUI

// MARK: - View
struct FormattedText: View {
    
    private let text: String
    
    private let colors: [UInt16: Palette] = [
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
            ForEach(0..<views.count, id: \.self) { index in
                views[index]
            }
        }
    }
    
    private func extractUrls() -> String {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return text
        }
        
        var string = text
        var matches = detector.matches(in: string, options: [], range: NSRange(location: 0, length: string.utf16.count))
        while let first = matches.first {
            guard let range = Range(first.range, in: string) else { break }
            
            // extract the matched url and surround it with formatting control characters
            let url = String(string[range])
            string.replaceSubrange(range, with: ControlCharacter.url.wrap(url))
            
            matches = detector.matches(
                in: string,
                options: [],
                range: NSRange(
                    location: first.range.upperBound,
                    length: string.utf16.count - first.range.upperBound))
        }
        
        return string
    }
    
    private func makeText() -> [AnyView] {
        var views: [ViewHolder] = []
        var formatting = TextFormatter()
        var current = ""
        
        // preprocess the text before we begin formatting it
        let text = extractUrls()
        
        var index = text.startIndex
        while index < text.endIndex {
            let char = text[index]
            
            switch ControlCharacter(rawValue: char.asciiValue ?? 0x00) {
            // toggles bold font
            case .bold:
                if formatting.bold || !current.isEmpty {
                    views.append(formatting.apply(current))
                    current = ""
                }
                
                formatting.bold = !formatting.bold
                index = text.index(after: index)
                
            // toggles italics font
            case .italics:
                if formatting.italics || !current.isEmpty {
                    views.append(formatting.apply(current))
                    current = ""
                }
                
                formatting.italics = !formatting.italics
                index = text.index(after: index)
                
            // toggles strikethrough font
            case .strikethrough:
                if formatting.strikethrough || !current.isEmpty {
                    views.append(formatting.apply(current))
                    current = ""
                }
                
                formatting.strikethrough = !formatting.strikethrough
                index = text.index(after: index)
                
            // toggles underline font
            case .underline:
                if formatting.underline || !current.isEmpty {
                    views.append(formatting.apply(current))
                    current = ""
                }
                
                formatting.underline = !formatting.underline
                index = text.index(after: index)
                
            // invert foreground and background colors
            case .invert:
                if formatting.inverted || !current.isEmpty {
                    views.append(formatting.apply(current))
                    current = ""
                }
                
                formatting.inverted = !formatting.inverted
                index = text.index(after: index)
                
            // controls foreground and optionally background text color
            case .color:
                // is a color already active?
                if formatting.fgColor != nil || !current.isEmpty {
                    views.append(formatting.apply(current))
                    current = ""
                    formatting.fgColor = nil
                }
                
                index = text.index(after: index)
                
                // is the following byte an ascii digit?
                if let fgChar1 = text.peek(index),
                   let fgByte1 = UInt16(fgChar1) {
                    
                    var fgCode = fgByte1
                    index = text.index(after: index)
                    
                    // is the next byte after that also an ascii digit?
                    if let fgChar2 = text.peek(index),
                       let fgByte2 = UInt16(fgChar2) {
                        
                        fgCode = (fgCode * 10) + fgByte2
                        index = text.index(after: index)
                    }
                    
                    formatting.fgColor = (colors[fgCode] ?? .none).toColor()
                    
                    // if the next sequence of bytes is an ascii comma followed by an ascii digit,
                    // then we treat that as a background color
                    if let bgSeparator = text.peek(index), bgSeparator == ",",
                       let bgChar1 = text.peek(index, offsetBy: 1),
                       let bgByte1 = UInt16(bgChar1) {
                        
                        var bgCode = bgByte1
                        index = text.index(index, offsetBy: 2)
                        
                        // is the next byte also an ascii digit?
                        if let bgChar2 = text.peek(index),
                           let bgByte2 = UInt16(bgChar2) {
                            
                            bgCode = (bgCode * 10) + bgByte2
                            index = text.index(after: index)
                        }
                        
                        formatting.bgColor = (colors[bgCode] ?? .none).toColor()
                    }
                    
                } else {
                    // no digit character - reset both foreground and background colors
                    formatting.fgColor = nil
                    formatting.bgColor = nil
                }
                
            // reset all formatting
            case .reset:
                // apply any currently buffered formatted text
                if !current.isEmpty {
                    views.append(formatting.apply(current))
                    current = ""
                }
                
                formatting = TextFormatter()
                index = text.index(after: index)
                
            // custom: indicates a url
            case .url:
                // apply any currently buffered formatted text
                if !current.isEmpty {
                    views.append(formatting.apply(current))
                    current = ""
                }
                
                formatting.url = !formatting.url
                index = text.index(after: index)
                
            // no formatting; take the character as-is
            default:
                current.append(char)
                index = text.index(after: index)
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
            if consolidated.isEmpty || !view.canBeMerged {
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

// MARK: - Extensions
extension FormattedText {
    
    enum ControlCharacter: UInt8 {
        case bold = 0x02
        case color = 0x03
        case invert = 0x16
        case reset = 0x0F
        case italics = 0x01D
        case strikethrough = 0x1E
        case underline = 0x1F
        
        // custom (non-standard) codes for our client
        case url = 0x19
        
        func wrap(_ string: String) -> String {
            return "\(UnicodeScalar(self.rawValue))\(string)\(UnicodeScalar(self.rawValue))"
        }
    }
    
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
    
    struct URLResult {
        let string: String
        let urls: [String: String]
    }
    
    struct ViewHolder {
        
        var text: Text?
        var url: AnyView?
        var view: AnyView?
        
        var canBeMerged: Bool {
            return text != nil
        }
        
        func toErasedView() -> AnyView {
            if let text = self.text {
                return AnyView(text)
            } else if let view = self.view {
                return view
            } else if let url = self.url {
                return url
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
        var url: Bool = false
        
        func apply(_ str: String) -> ViewHolder {
            var text = Text(str)
            
            // url formatting overrides all other format options
            if url {
                return ViewHolder(url: AnyView(
                    text
                        .foregroundColor(.blue)
                        .bold()
                        .onTapGesture {
                            guard let url = URL(string: str) else { return }
                            NSWorkspace.shared.open(url)
                        }
                        .onHover { hover in
                            if hover {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                ))
            }
            
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

// MARK: - Preview
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
