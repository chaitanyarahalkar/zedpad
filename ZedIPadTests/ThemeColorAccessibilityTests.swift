import XCTest
import SwiftUI
@testable import ZedIPad

final class ThemeColorAccessibilityTests: XCTestCase {

    // Test that theme colors are not identical to background (ensures readability)
    func testDarkThemeTextReadable() {
        let t = ZedTheme.dark
        XCTAssertNotEqual("\(t.primaryText)", "\(t.editorBackground)",
                          "Primary text should contrast with editor background")
    }

    func testLightThemeTextReadable() {
        let t = ZedTheme.light
        XCTAssertNotEqual("\(t.primaryText)", "\(t.editorBackground)")
    }

    func testSyntaxColorsDistinctFromBackground() {
        for theme in ZedTheme.allCases {
            let bg = "\(theme.editorBackground)"
            XCTAssertNotEqual("\(theme.syntaxKeyword)", bg, "\(theme.rawValue) keyword = background")
            XCTAssertNotEqual("\(theme.syntaxString)", bg, "\(theme.rawValue) string = background")
        }
    }

    func testAccentColorDistinctFromText() {
        for theme in ZedTheme.allCases {
            XCTAssertNotEqual("\(theme.accentColor)", "\(theme.primaryText)",
                              "\(theme.rawValue) accent should differ from primary text")
        }
    }

    func testAllColorPropertiesReturn() {
        let theme = ZedTheme.dark
        let colors: [Color] = [
            theme.background, theme.sidebarBackground, theme.editorBackground,
            theme.primaryText, theme.secondaryText, theme.lineNumberText,
            theme.accentColor, theme.selectionColor, theme.borderColor,
            theme.tabBarBackground, theme.activeTabBackground, theme.inactiveTabBackground,
            theme.syntaxKeyword, theme.syntaxString, theme.syntaxComment,
            theme.syntaxFunction, theme.syntaxType, theme.syntaxNumber,
            theme.findHighlight
        ]
        XCTAssertEqual(colors.count, 19)
    }

    func testColorSchemeCorrectForAllThemes() {
        XCTAssertEqual(ZedTheme.dark.colorScheme, .dark)
        XCTAssertEqual(ZedTheme.light.colorScheme, .light)
        XCTAssertEqual(ZedTheme.oneDark.colorScheme, .dark)
        XCTAssertEqual(ZedTheme.solarizedDark.colorScheme, .dark)
    }
}
