import XCTest
@testable import ZedIPad

@MainActor
final class CommandPaletteExtendedTests: XCTestCase {
    func testAllCommandsNotEmpty() {
        XCTAssertFalse(PaletteCommand.allCommands.isEmpty)
    }

    func testCommandCountIncludesNewCommands() {
        XCTAssertGreaterThanOrEqual(PaletteCommand.allCommands.count, 15)
    }

    func testToggleWordWrapCommandExists() {
        let found = PaletteCommand.allCommands.contains { $0.title == "Toggle Word Wrap" }
        XCTAssertTrue(found)
    }

    func testTabSize2CommandExists() {
        let found = PaletteCommand.allCommands.contains { $0.title == "Tab Size: 2 Spaces" }
        XCTAssertTrue(found)
    }

    func testTabSize4CommandExists() {
        let found = PaletteCommand.allCommands.contains { $0.title == "Tab Size: 4 Spaces" }
        XCTAssertTrue(found)
    }

    func testTabSize8CommandExists() {
        let found = PaletteCommand.allCommands.contains { $0.title == "Tab Size: 8 Spaces" }
        XCTAssertTrue(found)
    }

    func testToggleWordWrapAction() {
        let state = AppState()
        XCTAssertTrue(state.wordWrap)
        let cmd = PaletteCommand.allCommands.first { $0.title == "Toggle Word Wrap" }
        XCTAssertNotNil(cmd)
        cmd?.action(state)
        XCTAssertFalse(state.wordWrap)
        cmd?.action(state)
        XCTAssertTrue(state.wordWrap)
    }

    func testTabSize2Action() {
        let state = AppState()
        let cmd = PaletteCommand.allCommands.first { $0.title == "Tab Size: 2 Spaces" }
        cmd?.action(state)
        XCTAssertEqual(state.tabSize, 2)
    }

    func testTabSize4Action() {
        let state = AppState()
        let cmd = PaletteCommand.allCommands.first { $0.title == "Tab Size: 4 Spaces" }
        cmd?.action(state)
        XCTAssertEqual(state.tabSize, 4)
    }

    func testTabSize8Action() {
        let state = AppState()
        let cmd = PaletteCommand.allCommands.first { $0.title == "Tab Size: 8 Spaces" }
        cmd?.action(state)
        XCTAssertEqual(state.tabSize, 8)
    }

    func testAllCommandsHaveIcons() {
        for cmd in PaletteCommand.allCommands {
            XCTAssertFalse(cmd.icon.isEmpty, "\(cmd.title) missing icon")
        }
    }

    func testAllCommandsHaveSubtitles() {
        for cmd in PaletteCommand.allCommands {
            XCTAssertFalse(cmd.subtitle.isEmpty, "\(cmd.title) missing subtitle")
        }
    }

    func testCommandsHaveUniqueIDs() {
        let ids = PaletteCommand.allCommands.map { $0.id }
        let unique = Set(ids)
        XCTAssertEqual(ids.count, unique.count)
    }

    func testDarkThemeCommandAction() {
        let state = AppState()
        state.theme = .light
        let cmd = PaletteCommand.allCommands.first { $0.title == "Dark Theme" }
        cmd?.action(state)
        XCTAssertEqual(state.theme, .dark)
    }

    func testLightThemeCommandAction() {
        let state = AppState()
        let cmd = PaletteCommand.allCommands.first { $0.title == "Light Theme" }
        cmd?.action(state)
        XCTAssertEqual(state.theme, .light)
    }

    func testResetFontSizeCommandAction() {
        let state = AppState()
        state.fontSize = 18
        let cmd = PaletteCommand.allCommands.first { $0.title == "Reset Font Size" }
        cmd?.action(state)
        XCTAssertEqual(state.fontSize, 13)
    }
}
