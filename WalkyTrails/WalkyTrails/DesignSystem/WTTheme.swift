//
//  WTTheme.swift
//  WalkyTrails
//

import SwiftUI

enum WTTheme {
    enum ColorToken {
        static let brandOrange = SwiftUI.Color(hex: 0xC65A1E)
        static let forest = SwiftUI.Color(hex: 0x2F4F3E)
        static let warmGrey = SwiftUI.Color(hex: 0xF4F3F1)
        static let stone = SwiftUI.Color(hex: 0xD9D6D2)
        static let charcoal = SwiftUI.Color(hex: 0x121212)
        static let mutedText = SwiftUI.Color(hex: 0x6B6B6B)

        static let mapBase = SwiftUI.Color(hex: 0xEDEBE7)
        static let mapPark = SwiftUI.Color(hex: 0xDDE5DB)
        static let mapWater = SwiftUI.Color(hex: 0xD6DEE3)

        static let route = SwiftUI.Color(hex: 0xC65A1E)
    }

    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum Radius {
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 22
    }

    enum Stroke {
        static let hairline: CGFloat = 1
    }

    enum Shadow {
        static let y: CGFloat = 6
        static let radius: CGFloat = 18
        static let opacity: CGFloat = 0.06
    }

    enum Typography {
        static let pageTitle = Font.system(.largeTitle, design: .default).weight(.bold)
        static let sectionTitle = Font.system(.title3, design: .default).weight(.semibold)

        static let statValue = Font.system(.largeTitle, design: .default).weight(.bold)
        static let statLabel = Font.system(.caption, design: .default).weight(.medium)

        static let body = Font.system(.body, design: .default)
        static let callout = Font.system(.callout, design: .default)
        static let caption = Font.system(.caption, design: .default)

        static let monoTimer = Font.system(.largeTitle, design: .monospaced).weight(.bold)
    }
}

extension SwiftUI.Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

