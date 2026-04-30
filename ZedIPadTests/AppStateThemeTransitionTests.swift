import XCTest
@testable import ZedIPad

@MainActor
final class AppStateThemeTransitionTests: XCTestCase {

    func testCycleAllThemes() {
        let state = AppState()
        let allThemes = ZedTheme.allCases
        for theme in allThemes {
            state.theme = theme
            XCTAssertEqual(state.theme, theme)
            // Verify syntax highlighting works with current theme
            let hl = SyntaxHighlighter(theme: state.theme)
            let tokens = hl.highlight("let x: Int = 42", language: .swift)
            XCTAssertFalse(tokens.isEmpty)
        }
    }

    func testHighlightingConsistentAcrossToggle() {
        let state = AppState()
        let code = "import SwiftUI\nstruct ContentView: View { var body: some View { Text(\"Hello\") } }"
        let initialTheme = state.theme
        let hl1 = SyntaxHighlighter(theme: initialTheme)
        let tokens1 = hl1.highlight(code, language: .swift)
        state.toggleTheme()
        let hl2 = SyntaxHighlighter(theme: state.theme)
        let tokens2 = hl2.highlight(code, language: .swift)
        XCTAssertEqual(tokens1.count, tokens2.count, "Token count should be same across themes")
    }

    func testFilesRemainOpenAfterThemeChange() {
        let state = AppState()
        let files = (0..<5).map { FileNode(name: "f\($0).swift", type: .file, path: "/f\($0).swift") }
        files.forEach { state.openFile($0) }
        for theme in ZedTheme.allCases {
            state.theme = theme
            XCTAssertEqual(state.openFiles.count, 5, "Files should remain open after theme change to \(theme)")
        }
    }

    func testRecentFilesPreservedAcrossThemeChange() {
        let state = AppState()
        let file = FileNode(name: "test.swift", type: .file, path: "/test.swift")
        state.openFile(file)
        XCTAssertEqual(state.recentFiles.count, 1)
        state.toggleTheme()
        XCTAssertEqual(state.recentFiles.count, 1)
        XCTAssertEqual(state.recentFiles.first?.id, file.id)
    }

    func testFontSizePreservedAcrossThemeChange() {
        let state = AppState()
        state.increaseFontSize()
        state.increaseFontSize()
        let expectedSize = state.fontSize
        state.theme = .oneDark
        XCTAssertEqual(state.fontSize, expectedSize)
        state.theme = .solarizedDark
        XCTAssertEqual(state.fontSize, expectedSize)
    }
}
