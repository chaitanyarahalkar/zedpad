import XCTest

final class FeatureShowcaseTests: XCTestCase {
    var app: XCUIApplication!

    func save(_ name: String) {
        guard app.exists else { return }
        let s = app.screenshot()
        let a = XCTAttachment(screenshot: s)
        a.name = name; a.lifetime = .keepAlways; add(a)
        let dir = URL(fileURLWithPath: "/Users/chaitanyarahalkar/Development/zed-ipad/autoresearch-screenshots/features")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? s.pngRepresentation.write(to: dir.appendingPathComponent("\(name).png"))
    }

    func expandSourcesAndOpenFile(_ name: String) {
        let sources = app.staticTexts["Sources"]
        if sources.waitForExistence(timeout: 4) {
            sources.tap()
            Thread.sleep(forTimeInterval: 0.6)
        }
        // Use firstMatch to avoid ambiguity with tab bar labels
        let fileEntry = app.staticTexts.matching(identifier: name).firstMatch
        if fileEntry.waitForExistence(timeout: 3) {
            fileEntry.tap()
            Thread.sleep(forTimeInterval: 1.5)
        }
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        Thread.sleep(forTimeInterval: 0.5)
    }

    override func tearDownWithError() throws {
        app.terminate()
    }

    // MARK: - 1a. Syntax Highlighting (Light Theme)

    func testSyntaxHighlightingLight() throws {
        let themeButton = app.buttons["Toggle theme"]
        if themeButton.waitForExistence(timeout: 3) {
            themeButton.tap()
            Thread.sleep(forTimeInterval: 0.6)
        }
        expandSourcesAndOpenFile("Editor.swift")
        save("1_syntax_highlighting_light")
    }

    // MARK: - 1b. Syntax Highlighting (Dark Theme)

    func testSyntaxHighlightingDark() throws {
        // Dark is the default — just open the file
        expandSourcesAndOpenFile("Editor.swift")
        save("2_syntax_highlighting_dark")
    }

    // MARK: - 2. Auto-Indent

    func testAutoIndent() throws {
        expandSourcesAndOpenFile("main.swift")
        let textView = app.textViews.firstMatch
        if textView.waitForExistence(timeout: 3) {
            textView.tap()
            Thread.sleep(forTimeInterval: 0.5)
            // Type at end — auto-indent should carry leading whitespace forward
            textView.typeText("\n    // auto-indent: new line keeps indentation\n    let result = true")
            Thread.sleep(forTimeInterval: 0.8)
        }
        save("3_auto_indent")
    }

    // MARK: - 3. Landscape Layout

    func testLandscapeLayout() throws {
        XCUIDevice.shared.orientation = .landscapeLeft
        Thread.sleep(forTimeInterval: 1.5)
        expandSourcesAndOpenFile("Editor.swift")
        save("4_landscape_layout")

        XCUIDevice.shared.orientation = .portrait
        Thread.sleep(forTimeInterval: 1.0)
        save("5_portrait_layout")
    }

    // MARK: - 4. Find + Syntax Highlighting Together

    func testFindHighlighting() throws {
        expandSourcesAndOpenFile("Editor.swift")
        Thread.sleep(forTimeInterval: 0.5)

        let findButton = app.buttons["Find in File"]
        if findButton.waitForExistence(timeout: 4) {
            findButton.tap()
            Thread.sleep(forTimeInterval: 0.6)
        }

        let searchField = app.textFields["Search field"]
        if searchField.waitForExistence(timeout: 3) {
            searchField.tap()
            Thread.sleep(forTimeInterval: 0.3)
            searchField.typeText("func")
            Thread.sleep(forTimeInterval: 0.8)
        }
        save("6_find_with_syntax_highlighting")
    }
}
