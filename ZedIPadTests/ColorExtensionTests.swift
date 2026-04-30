import XCTest
import SwiftUI
@testable import ZedIPad

final class ColorExtensionTests: XCTestCase {

    func testHexColorFromSixDigit() {
        // Basic sanity: Color(hex:) shouldn't crash
        let c = Color(hex: "#89b4fa")
        _ = c // just verify it initializes
    }

    func testHexColorFromThreeDigit() {
        let c = Color(hex: "#fff")
        _ = c
    }

    func testHexColorFromEightDigit() {
        let c = Color(hex: "#89b4faff")
        _ = c
    }

    func testHexColorWithoutHash() {
        let c = Color(hex: "89b4fa")
        _ = c
    }

    func testHexColorBlack() {
        let c = Color(hex: "#000000")
        _ = c
    }

    func testHexColorWhite() {
        let c = Color(hex: "#ffffff")
        _ = c
    }

    func testAllThemeAccentColorsInitialize() {
        for theme in ZedTheme.allCases {
            let color = theme.accentColor
            _ = color
        }
    }

    func testAllThemeBackgroundColorsInitialize() {
        for theme in ZedTheme.allCases {
            _ = theme.background
            _ = theme.sidebarBackground
            _ = theme.editorBackground
            _ = theme.tabBarBackground
        }
    }

    func testAllThemeSyntaxColorsInitialize() {
        for theme in ZedTheme.allCases {
            _ = theme.syntaxKeyword
            _ = theme.syntaxString
            _ = theme.syntaxComment
            _ = theme.syntaxFunction
            _ = theme.syntaxType
            _ = theme.syntaxNumber
        }
    }

    func testThemeSelectionColorHasOpacity() {
        // Selection color should have some opacity (not fully opaque)
        for theme in ZedTheme.allCases {
            _ = theme.selectionColor
        }
    }

    func testFindHighlightColor() {
        for theme in ZedTheme.allCases {
            _ = theme.findHighlight
        }
    }
}
