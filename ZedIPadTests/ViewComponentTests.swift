import XCTest
@testable import ZedIPad

final class ViewComponentTests: XCTestCase {

    // MARK: - BreadcrumbView logic

    func testBreadcrumbPathComponents() {
        let file = FileNode(name: "main.swift", type: .file, path: "/my-project/Sources/main.swift")
        let components = file.path
            .split(separator: "/")
            .map(String.init)
            .filter { !$0.isEmpty }
        XCTAssertEqual(components, ["my-project", "Sources", "main.swift"])
    }

    func testBreadcrumbRootPath() {
        let file = FileNode(name: "README.md", type: .file, path: "/README.md")
        let components = file.path
            .split(separator: "/")
            .map(String.init)
            .filter { !$0.isEmpty }
        XCTAssertEqual(components, ["README.md"])
    }

    func testBreadcrumbDeepPath() {
        let file = FileNode(name: "test.ts", type: .file, path: "/a/b/c/d/e/test.ts")
        let components = file.path
            .split(separator: "/")
            .map(String.init)
            .filter { !$0.isEmpty }
        XCTAssertEqual(components.count, 6)
        XCTAssertEqual(components.last, "test.ts")
    }

    // MARK: - Minimap logic

    func testMinimapScrollFractionClamped() {
        // Verify that scroll fractions between 0 and 1 are valid
        let validFractions: [CGFloat] = [0, 0.1, 0.5, 0.99, 1.0]
        for f in validFractions {
            let clamped = max(0, min(1, f))
            XCTAssertEqual(clamped, f)
        }
        let over: CGFloat = 1.5
        XCTAssertEqual(max(0, min(1, over)), 1.0)
        let under: CGFloat = -0.5
        XCTAssertEqual(max(0, min(1, under)), 0.0)
    }

    func testMinimapLineCount() {
        let content = "line1\nline2\nline3\n"
        let lines = content.components(separatedBy: "\n")
        XCTAssertEqual(lines.count, 4) // trailing newline creates empty last
    }

    // MARK: - EditorTab

    func testEditorTabFileIcon() {
        let swift = FileNode(name: "App.swift", type: .file, path: "/App.swift")
        XCTAssertEqual(swift.icon, "swift")
        let json = FileNode(name: "config.json", type: .file, path: "/config.json")
        XCTAssertEqual(json.icon, "curlybraces")
        let html = FileNode(name: "page.html", type: .file, path: "/page.html")
        XCTAssertEqual(html.icon, "globe")
    }

    // MARK: - PaletteCommand filtering

    @MainActor func testCommandPaletteFiltering() {
        let commands = PaletteCommand.allCommands
        // Filter by "theme" keyword
        let themeCommands = commands.filter {
            $0.title.localizedCaseInsensitiveContains("theme")
        }
        XCTAssertGreaterThan(themeCommands.count, 0)
        // Filter by "font"
        let fontCommands = commands.filter {
            $0.title.localizedCaseInsensitiveContains("font")
        }
        XCTAssertGreaterThan(fontCommands.count, 0)
    }

    @MainActor func testAllCommandsHaveIcons() {
        for cmd in PaletteCommand.allCommands {
            XCTAssertFalse(cmd.icon.isEmpty, "Command '\(cmd.title)' has empty icon")
        }
    }

    @MainActor func testAllCommandsHaveTitles() {
        for cmd in PaletteCommand.allCommands {
            XCTAssertFalse(cmd.title.isEmpty, "Command has empty title")
        }
    }

    @MainActor func testFontSizeCommandsPresent() {
        let commands = PaletteCommand.allCommands
        let titles = commands.map(\.title)
        XCTAssertTrue(titles.contains(where: { $0.contains("Font") }))
    }
}
