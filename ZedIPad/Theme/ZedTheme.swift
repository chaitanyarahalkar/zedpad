import SwiftUI

enum ZedTheme: String, CaseIterable {
    case dark = "Zed Dark"
    case light = "Zed Light"
    case oneDark = "One Dark"
    case solarizedDark = "Solarized Dark"

    var colorScheme: ColorScheme {
        switch self {
        case .light: return .light
        default: return .dark
        }
    }

    // Background colors
    var background: Color {
        switch self {
        case .dark: return Color(hex: "#1e2124")
        case .light: return Color(hex: "#f5f5f0")
        case .oneDark: return Color(hex: "#282c34")
        case .solarizedDark: return Color(hex: "#002b36")
        }
    }

    var sidebarBackground: Color {
        switch self {
        case .dark: return Color(hex: "#171a1d")
        case .light: return Color(hex: "#ebebeb")
        case .oneDark: return Color(hex: "#21252b")
        case .solarizedDark: return Color(hex: "#073642")
        }
    }

    var editorBackground: Color {
        switch self {
        case .dark: return Color(hex: "#1e2124")
        case .light: return Color(hex: "#ffffff")
        case .oneDark: return Color(hex: "#282c34")
        case .solarizedDark: return Color(hex: "#002b36")
        }
    }

    // Text colors
    var primaryText: Color {
        switch self {
        case .dark: return Color(hex: "#cdd6f4")
        case .light: return Color(hex: "#24292e")
        case .oneDark: return Color(hex: "#abb2bf")
        case .solarizedDark: return Color(hex: "#839496")
        }
    }

    var secondaryText: Color {
        switch self {
        case .dark: return Color(hex: "#6e738d")
        case .light: return Color(hex: "#6a737d")
        case .oneDark: return Color(hex: "#5c6370")
        case .solarizedDark: return Color(hex: "#586e75")
        }
    }

    var lineNumberText: Color {
        switch self {
        case .dark: return Color(hex: "#45475a")
        case .light: return Color(hex: "#babbbc")
        case .oneDark: return Color(hex: "#495162")
        case .solarizedDark: return Color(hex: "#4c5c60")
        }
    }

    // UI colors
    var accentColor: Color {
        switch self {
        case .dark: return Color(hex: "#89b4fa")
        case .light: return Color(hex: "#0969da")
        case .oneDark: return Color(hex: "#61afef")
        case .solarizedDark: return Color(hex: "#268bd2")
        }
    }

    var selectionColor: Color {
        switch self {
        case .dark: return Color(hex: "#89b4fa").opacity(0.3)
        case .light: return Color(hex: "#0969da").opacity(0.15)
        case .oneDark: return Color(hex: "#3e4451")
        case .solarizedDark: return Color(hex: "#073642")
        }
    }

    var borderColor: Color {
        switch self {
        case .dark: return Color(hex: "#313244")
        case .light: return Color(hex: "#d0d7de")
        case .oneDark: return Color(hex: "#3b4048")
        case .solarizedDark: return Color(hex: "#073642")
        }
    }

    var tabBarBackground: Color {
        switch self {
        case .dark: return Color(hex: "#181b1f")
        case .light: return Color(hex: "#f0f0eb")
        case .oneDark: return Color(hex: "#21252b")
        case .solarizedDark: return Color(hex: "#073642")
        }
    }

    var activeTabBackground: Color {
        editorBackground
    }

    var inactiveTabBackground: Color {
        tabBarBackground
    }

    // Syntax colors
    var syntaxKeyword: Color {
        switch self {
        case .dark: return Color(hex: "#cba6f7")
        case .light: return Color(hex: "#d73a49")
        case .oneDark: return Color(hex: "#c678dd")
        case .solarizedDark: return Color(hex: "#859900")
        }
    }

    var syntaxString: Color {
        switch self {
        case .dark: return Color(hex: "#a6e3a1")
        case .light: return Color(hex: "#032f62")
        case .oneDark: return Color(hex: "#98c379")
        case .solarizedDark: return Color(hex: "#2aa198")
        }
    }

    var syntaxComment: Color {
        switch self {
        case .dark: return Color(hex: "#6c7086")
        case .light: return Color(hex: "#6a737d")
        case .oneDark: return Color(hex: "#5c6370")
        case .solarizedDark: return Color(hex: "#586e75")
        }
    }

    var syntaxFunction: Color {
        switch self {
        case .dark: return Color(hex: "#89b4fa")
        case .light: return Color(hex: "#6f42c1")
        case .oneDark: return Color(hex: "#61afef")
        case .solarizedDark: return Color(hex: "#268bd2")
        }
    }

    var syntaxType: Color {
        switch self {
        case .dark: return Color(hex: "#89dceb")
        case .light: return Color(hex: "#005cc5")
        case .oneDark: return Color(hex: "#e5c07b")
        case .solarizedDark: return Color(hex: "#cb4b16")
        }
    }

    var syntaxNumber: Color {
        switch self {
        case .dark: return Color(hex: "#fab387")
        case .light: return Color(hex: "#005cc5")
        case .oneDark: return Color(hex: "#d19a66")
        case .solarizedDark: return Color(hex: "#d33682")
        }
    }

    var findHighlight: Color {
        Color(hex: "#f9e2af").opacity(0.4)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
