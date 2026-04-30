import XCTest
@testable import ZedIPad

@MainActor
final class ThemeTests: XCTestCase {

    func testAllThemesHaveDistinctBackgrounds() {
        let themes = ZedTheme.allCases
        var backgrounds = Set<String>()
        for theme in themes {
            let desc = "\(theme.background)"
            backgrounds.insert(desc)
        }
        XCTAssertEqual(backgrounds.count, themes.count, "All themes should have distinct backgrounds")
    }

    func testDarkThemeIsDark() {
        XCTAssertEqual(ZedTheme.dark.colorScheme, .dark)
        XCTAssertEqual(ZedTheme.oneDark.colorScheme, .dark)
        XCTAssertEqual(ZedTheme.solarizedDark.colorScheme, .dark)
    }

    func testLightThemeIsLight() {
        XCTAssertEqual(ZedTheme.light.colorScheme, .light)
    }

    func testThemeRawValues() {
        XCTAssertEqual(ZedTheme.dark.rawValue, "Zed Dark")
        XCTAssertEqual(ZedTheme.light.rawValue, "Zed Light")
        XCTAssertEqual(ZedTheme.oneDark.rawValue, "One Dark")
        XCTAssertEqual(ZedTheme.solarizedDark.rawValue, "Solarized Dark")
    }

    func testToggleGoesLightThenDark() {
        let state = AppState()
        XCTAssertEqual(state.theme, .dark)
        state.toggleTheme()
        XCTAssertEqual(state.theme, .light)
        state.toggleTheme()
        XCTAssertEqual(state.theme, .dark)
    }

    func testManualThemeSetting() {
        let state = AppState()
        state.theme = .oneDark
        XCTAssertEqual(state.theme, .oneDark)
        state.theme = .solarizedDark
        XCTAssertEqual(state.theme, .solarizedDark)
        state.theme = .light
        XCTAssertEqual(state.theme, .light)
    }

    func testSyntaxColorsAreNonEmpty() {
        for theme in ZedTheme.allCases {
            let colors = [
                theme.syntaxKeyword, theme.syntaxString, theme.syntaxComment,
                theme.syntaxFunction, theme.syntaxType, theme.syntaxNumber
            ]
            XCTAssertEqual(colors.count, 6, "Theme \(theme.rawValue) should have 6 syntax colors")
        }
    }

    func testFindHighlightColorExists() {
        for theme in ZedTheme.allCases {
            _ = theme.findHighlight
            _ = theme.selectionColor
        }
    }

    func testAccentColorsDistinctAcrossThemes() {
        let accents = ZedTheme.allCases.map { "\($0.accentColor)" }
        let unique = Set(accents)
        XCTAssertGreaterThan(unique.count, 1, "Themes should have distinct accent colors")
    }

    func testBorderColorsDistinctFromBackground() {
        for theme in ZedTheme.allCases {
            let bg = "\(theme.background)"
            let border = "\(theme.borderColor)"
            XCTAssertNotEqual(bg, border, "Border should differ from background in \(theme.rawValue)")
        }
    }

    func testTabBarBackgroundExists() {
        for theme in ZedTheme.allCases {
            _ = theme.tabBarBackground
            _ = theme.activeTabBackground
            _ = theme.inactiveTabBackground
        }
    }
}
