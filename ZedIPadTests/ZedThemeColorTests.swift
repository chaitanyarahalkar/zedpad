import XCTest
import SwiftUI
@testable import ZedIPad

final class ZedThemeColorTests: XCTestCase {

    func testDarkThemeColors() {
        let t = ZedTheme.dark
        _ = t.background; _ = t.sidebarBackground; _ = t.editorBackground
        _ = t.primaryText; _ = t.secondaryText; _ = t.lineNumberText
        _ = t.accentColor; _ = t.selectionColor; _ = t.borderColor
        _ = t.tabBarBackground; _ = t.activeTabBackground; _ = t.inactiveTabBackground
        _ = t.syntaxKeyword; _ = t.syntaxString; _ = t.syntaxComment
        _ = t.syntaxFunction; _ = t.syntaxType; _ = t.syntaxNumber
        _ = t.findHighlight
    }

    func testLightThemeColors() {
        let t = ZedTheme.light
        _ = t.background; _ = t.sidebarBackground; _ = t.editorBackground
        _ = t.primaryText; _ = t.secondaryText; _ = t.lineNumberText
        _ = t.accentColor; _ = t.selectionColor; _ = t.borderColor
        _ = t.syntaxKeyword; _ = t.syntaxString; _ = t.syntaxComment
        _ = t.syntaxFunction; _ = t.syntaxType; _ = t.syntaxNumber
    }

    func testOneDarkThemeColors() {
        let t = ZedTheme.oneDark
        _ = t.background; _ = t.primaryText; _ = t.accentColor
        _ = t.syntaxKeyword; _ = t.syntaxString; _ = t.syntaxComment
    }

    func testSolarizedDarkThemeColors() {
        let t = ZedTheme.solarizedDark
        _ = t.background; _ = t.primaryText; _ = t.accentColor
        _ = t.syntaxKeyword; _ = t.syntaxString; _ = t.syntaxComment
    }

    func testColorHexInitializerWith3Chars() {
        let c = Color(hex: "#fff")
        _ = c
    }

    func testColorHexInitializerWith6Chars() {
        let colors = ["#000000", "#ffffff", "#89b4fa", "#1e2124", "#cdd6f4"]
        for hex in colors {
            _ = Color(hex: hex)
        }
    }

    func testColorHexInitializerWith8Chars() {
        let c = Color(hex: "#89b4faff")
        _ = c
    }

    func testColorHexWithoutHash() {
        let c = Color(hex: "89b4fa")
        _ = c
    }

    func testAllThemeRawValues() {
        let expected = ["Zed Dark", "Zed Light", "One Dark", "Solarized Dark"]
        let actual = ZedTheme.allCases.map(\.rawValue)
        XCTAssertEqual(actual, expected)
    }

    func testThemeEquality() {
        XCTAssertEqual(ZedTheme.dark, ZedTheme.dark)
        XCTAssertNotEqual(ZedTheme.dark, ZedTheme.light)
        XCTAssertNotEqual(ZedTheme.oneDark, ZedTheme.solarizedDark)
    }

    func testThemeHashable() {
        let set: Set<ZedTheme> = [.dark, .light, .oneDark, .solarizedDark, .dark]
        XCTAssertEqual(set.count, 4)
    }
}
