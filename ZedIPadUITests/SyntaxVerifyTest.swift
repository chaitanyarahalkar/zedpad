import XCTest

final class SyntaxVerifyTest: XCTestCase {
    var app: XCUIApplication!

    nonisolated(unsafe) static let dir = URL(fileURLWithPath: "/Users/chaitanyarahalkar/Development/zed-ipad/autoresearch-screenshots")

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    override func tearDownWithError() throws { app.terminate() }

    func save(_ name: String) {
        let s = app.screenshot()
        add({ let a = XCTAttachment(screenshot: s); a.name = name; a.lifetime = .keepAlways; return a }())
        try? s.pngRepresentation.write(to: Self.dir.appendingPathComponent("\(name).png"))
    }

    func testSyntaxHighlightDark() throws {
        // open main.swift in dark theme
        if app.staticTexts["Sources"].waitForExistence(timeout: 3) { app.staticTexts["Sources"].tap(); Thread.sleep(forTimeInterval: 0.4) }
        if app.staticTexts["main.swift"].waitForExistence(timeout: 2) { app.staticTexts["main.swift"].tap(); Thread.sleep(forTimeInterval: 1.0) }
        save("syntax_dark")
    }

    func testSyntaxHighlightLight() throws {
        // switch to light then open file
        let toggle = app.buttons["Toggle theme"]
        if toggle.waitForExistence(timeout: 3) { toggle.tap(); Thread.sleep(forTimeInterval: 0.3) }
        if app.staticTexts["Sources"].waitForExistence(timeout: 3) { app.staticTexts["Sources"].tap(); Thread.sleep(forTimeInterval: 0.4) }
        if app.staticTexts["main.swift"].waitForExistence(timeout: 2) { app.staticTexts["main.swift"].tap(); Thread.sleep(forTimeInterval: 1.0) }
        save("syntax_light")
    }
}
