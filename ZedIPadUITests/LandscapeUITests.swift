import XCTest

final class LandscapeUITests: XCTestCase {
    var app: XCUIApplication!

    nonisolated(unsafe) private static let screenshotsDir: URL = {
        let dir = URL(fileURLWithPath: "/Users/chaitanyarahalkar/Development/zed-ipad/autoresearch-screenshots/landscape")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("UITestingSampleProject")
        app.launch()
        XCUIDevice.shared.orientation = .landscapeLeft
        Thread.sleep(forTimeInterval: 0.8)
    }

    override func tearDownWithError() throws {
        XCUIDevice.shared.orientation = .portrait
        app.terminate()
    }

    private func save(_ name: String) {
        let shot = app.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        let url = Self.screenshotsDir.appendingPathComponent("\(name).png")
        try? shot.pngRepresentation.write(to: url)
    }

    func testLandscape01WelcomeScreen() throws {
        _ = app.staticTexts["ZedIPad"].waitForExistence(timeout: 4)
        save("landscape_01_welcome")
    }

    func testLandscape02EditorWithSyntaxHighlighting() throws {
        let sources = app.staticTexts["Sources"]
        if sources.waitForExistence(timeout: 4) {
            sources.tap()
            Thread.sleep(forTimeInterval: 0.4)
        }
        let mainSwift = app.staticTexts["main.swift"]
        if mainSwift.waitForExistence(timeout: 3) {
            mainSwift.tap()
            Thread.sleep(forTimeInterval: 0.6)
        }
        save("landscape_02_editor")
    }

    func testLandscape03CommandPalette() throws {
        let paletteButton = app.buttons["Open command palette"]
        if paletteButton.waitForExistence(timeout: 4) {
            paletteButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
            save("landscape_03_command_palette")
            let cancel = app.buttons["Cancel"]
            if cancel.waitForExistence(timeout: 2) { cancel.tap() }
        } else {
            save("landscape_03_command_palette_fallback")
        }
        XCTAssertTrue(app.exists)
    }

    func testLandscape04FindBar() throws {
        // Open a file first
        let sources = app.staticTexts["Sources"]
        if sources.waitForExistence(timeout: 4) {
            sources.tap()
            Thread.sleep(forTimeInterval: 0.4)
        }
        if app.staticTexts["main.swift"].waitForExistence(timeout: 3) {
            app.staticTexts["main.swift"].tap()
            Thread.sleep(forTimeInterval: 0.5)
        }
        let findBtn = app.buttons["Find in File"]
        if findBtn.waitForExistence(timeout: 4) {
            findBtn.tap()
            Thread.sleep(forTimeInterval: 0.3)
            let field = app.textFields["Search field"]
            if field.waitForExistence(timeout: 2) {
                field.tap()
                field.typeText("struct")
                Thread.sleep(forTimeInterval: 0.3)
            }
            save("landscape_04_find_bar")
        } else {
            save("landscape_04_find_bar_fallback")
        }
        XCTAssertTrue(app.exists)
    }

    func testLandscape05LightTheme() throws {
        let themeBtn = app.buttons["Toggle theme"]
        if themeBtn.waitForExistence(timeout: 4) {
            themeBtn.tap()
            Thread.sleep(forTimeInterval: 0.4)
            // Open a file to show the editor in light theme
            let sources = app.staticTexts["Sources"]
            if sources.waitForExistence(timeout: 3) {
                sources.tap()
                Thread.sleep(forTimeInterval: 0.3)
            }
            if app.staticTexts["main.swift"].waitForExistence(timeout: 2) {
                app.staticTexts["main.swift"].tap()
                Thread.sleep(forTimeInterval: 0.5)
            }
            save("landscape_05_light_theme_editor")
            // Toggle back to dark
            if themeBtn.waitForExistence(timeout: 2) {
                themeBtn.tap()
                Thread.sleep(forTimeInterval: 0.3)
            }
        } else {
            save("landscape_05_light_theme_fallback")
        }
        XCTAssertTrue(app.exists)
    }

    func testLandscape06PythonFile() throws {
        let scripts = app.staticTexts["scripts"]
        if scripts.waitForExistence(timeout: 4) {
            scripts.tap()
            Thread.sleep(forTimeInterval: 0.4)
        }
        let buildPy = app.staticTexts["build.py"]
        if buildPy.waitForExistence(timeout: 3) {
            buildPy.tap()
            Thread.sleep(forTimeInterval: 0.6)
            save("landscape_06_python_file")
        } else {
            save("landscape_06_python_fallback")
        }
        XCTAssertTrue(app.exists)
    }

    func testLandscape07FileTreeExpanded() throws {
        // Expand all top-level folders
        for name in ["Sources", "scripts", "web", "config", "Tests"] {
            let node = app.staticTexts[name]
            if node.waitForExistence(timeout: 2) {
                node.tap()
                Thread.sleep(forTimeInterval: 0.2)
            }
        }
        save("landscape_07_file_tree_expanded")
        XCTAssertTrue(app.exists)
    }
}
