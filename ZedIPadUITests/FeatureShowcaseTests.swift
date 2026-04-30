import XCTest

final class FeatureShowcaseTests: XCTestCase {
    var app: XCUIApplication!

    func save(_ name: String) {
        let s = app.screenshot()
        let a = XCTAttachment(screenshot: s)
        a.name = name
        a.lifetime = .keepAlways
        add(a)
        let dir = URL(fileURLWithPath: "/Users/chaitanyarahalkar/Development/zed-ipad/autoresearch-screenshots/features")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? s.pngRepresentation.write(to: dir.appendingPathComponent("\(name).png"))
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
    }

    // MARK: - 1. Syntax Highlighting

    func testSyntaxHighlighting() throws {
        // Switch to light theme
        let themeButton = app.buttons["Toggle theme"]
        if themeButton.waitForExistence(timeout: 3) {
            themeButton.tap()
            Thread.sleep(forTimeInterval: 0.4)
        }

        // Expand Sources and open Editor.swift
        let sources = app.staticTexts["Sources"]
        if sources.waitForExistence(timeout: 3) {
            sources.tap()
            Thread.sleep(forTimeInterval: 0.5)
        }
        let editorSwift = app.staticTexts["Editor.swift"]
        if editorSwift.waitForExistence(timeout: 3) {
            editorSwift.tap()
            Thread.sleep(forTimeInterval: 1.5)
        }
        save("1_syntax_highlighting_light")

        // Switch back to dark theme
        if themeButton.waitForExistence(timeout: 3) {
            themeButton.tap()
            Thread.sleep(forTimeInterval: 0.4)
        }
        // Re-open Editor.swift (may need to re-tap)
        if editorSwift.waitForExistence(timeout: 2) {
            editorSwift.tap()
            Thread.sleep(forTimeInterval: 1.5)
        }
        save("2_syntax_highlighting_dark")
    }

    // MARK: - 2. Auto-Indent

    func testAutoIndent() throws {
        // Open main.swift
        let sources = app.staticTexts["Sources"]
        if sources.waitForExistence(timeout: 3) {
            sources.tap()
            Thread.sleep(forTimeInterval: 0.5)
        }
        let mainSwift = app.staticTexts["main.swift"]
        if mainSwift.waitForExistence(timeout: 3) {
            mainSwift.tap()
            Thread.sleep(forTimeInterval: 1.0)
        }

        // Tap the editor text view and type at the end to trigger auto-indent
        let textView = app.textViews.firstMatch
        if textView.waitForExistence(timeout: 3) {
            textView.tap()
            Thread.sleep(forTimeInterval: 0.5)
            // Move to end and type a new indented block
            textView.typeText("\n    // auto-indent works here\n    let x = 42")
            Thread.sleep(forTimeInterval: 0.5)
        }
        save("3_auto_indent")
    }

    // MARK: - 3. Landscape Layout

    func testLandscapeLayout() throws {
        // Rotate to landscape
        XCUIDevice.shared.orientation = .landscapeLeft
        Thread.sleep(forTimeInterval: 1.5)

        // Open Editor.swift in landscape
        let sources = app.staticTexts["Sources"]
        if sources.waitForExistence(timeout: 3) {
            sources.tap()
            Thread.sleep(forTimeInterval: 0.5)
        }
        let editorSwift = app.staticTexts["Editor.swift"]
        if editorSwift.waitForExistence(timeout: 3) {
            editorSwift.tap()
            Thread.sleep(forTimeInterval: 1.5)
        }
        save("4_landscape_layout")

        // Back to portrait
        XCUIDevice.shared.orientation = .portrait
        Thread.sleep(forTimeInterval: 1.0)
        save("5_portrait_layout")
    }

    // MARK: - 4. Find + Syntax Highlighting Together

    func testFindHighlighting() throws {
        // Open Editor.swift in dark theme
        let sources = app.staticTexts["Sources"]
        if sources.waitForExistence(timeout: 3) {
            sources.tap()
            Thread.sleep(forTimeInterval: 0.5)
        }
        let editorSwift = app.staticTexts["Editor.swift"]
        if editorSwift.waitForExistence(timeout: 3) {
            editorSwift.tap()
            Thread.sleep(forTimeInterval: 1.0)
        }

        // Open find bar
        let findButton = app.buttons["Find in File"]
        if findButton.waitForExistence(timeout: 3) {
            findButton.tap()
            Thread.sleep(forTimeInterval: 0.4)
        }

        // Type search query
        let searchField = app.textFields["Search field"]
        if searchField.waitForExistence(timeout: 2) {
            searchField.tap()
            searchField.typeText("func")
            Thread.sleep(forTimeInterval: 0.6)
        }
        save("6_find_with_syntax_highlighting")
    }
}
