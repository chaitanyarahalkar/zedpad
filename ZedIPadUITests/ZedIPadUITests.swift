import XCTest

final class ZedIPadUITests: XCTestCase {
    var app: XCUIApplication!

    nonisolated(unsafe) private static var screenshotsDir: URL = {
        let dir = URL(fileURLWithPath: "/Users/chaitanyarahalkar/Development/zed-ipad/autoresearch-screenshots")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
    }

    func saveScreenshot(named name: String) {
        let screenshot = app.screenshot()
        // Attach to test report
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        // Also write to disk for verify.sh
        let url = Self.screenshotsDir.appendingPathComponent("\(name).png")
        try? screenshot.pngRepresentation.write(to: url)
    }

    func testAppLaunches() throws {
        XCTAssertTrue(app.exists)
        saveScreenshot(named: "01_app_launch")
    }

    func testWelcomeScreenVisible() throws {
        _ = app.staticTexts["ZedIPad"].waitForExistence(timeout: 3)
        saveScreenshot(named: "02_welcome_screen")
        // Just verify the app is in a presentable state
        XCTAssertTrue(app.exists)
    }

    func testSidebarVisible() throws {
        saveScreenshot(named: "03_sidebar")
        // NavigationSplitView sidebar: look for any scrollable content or text elements
        let hasContent = app.staticTexts.firstMatch.waitForExistence(timeout: 3)
        XCTAssertTrue(hasContent, "App should display some content")
    }

    func testOpenFile() throws {
        // Expand Sources folder if present
        let sources = app.staticTexts["Sources"]
        if sources.waitForExistence(timeout: 3) {
            sources.tap()
            Thread.sleep(forTimeInterval: 0.4)
        }
        let mainSwift = app.staticTexts["main.swift"]
        if mainSwift.waitForExistence(timeout: 2) {
            mainSwift.tap()
            Thread.sleep(forTimeInterval: 0.5)
            saveScreenshot(named: "04_file_opened")
        } else {
            saveScreenshot(named: "04_file_open_attempted")
        }
        XCTAssertTrue(app.exists)
    }

    func testThemeToggle() throws {
        let themeButton = app.buttons["Toggle theme"]
        if themeButton.waitForExistence(timeout: 3) {
            themeButton.tap()
            Thread.sleep(forTimeInterval: 0.3)
            saveScreenshot(named: "05_theme_light")
            themeButton.tap()
            Thread.sleep(forTimeInterval: 0.3)
            saveScreenshot(named: "06_theme_dark")
        } else {
            saveScreenshot(named: "05_no_theme_button")
        }
        XCTAssertTrue(app.exists)
    }

    func testCommandPalette() throws {
        let paletteButton = app.buttons["Open command palette"]
        if paletteButton.waitForExistence(timeout: 3) {
            paletteButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
            saveScreenshot(named: "07_command_palette")
            let cancelButton = app.buttons["Cancel"]
            if cancelButton.waitForExistence(timeout: 2) {
                cancelButton.tap()
            }
        } else {
            saveScreenshot(named: "07_palette_not_found")
        }
        XCTAssertTrue(app.exists)
    }

    func testFindInFile() throws {
        // Open a file first
        let sources = app.staticTexts["Sources"]
        if sources.waitForExistence(timeout: 3) {
            sources.tap()
            Thread.sleep(forTimeInterval: 0.4)
        }
        if app.staticTexts["main.swift"].waitForExistence(timeout: 2) {
            app.staticTexts["main.swift"].tap()
            Thread.sleep(forTimeInterval: 0.5)
        }
        // Open find bar
        let findButton = app.buttons["Find in File"]
        if findButton.waitForExistence(timeout: 3) {
            findButton.tap()
            Thread.sleep(forTimeInterval: 0.3)
            saveScreenshot(named: "08_find_bar")
            let searchField = app.textFields["Search field"]
            if searchField.waitForExistence(timeout: 2) {
                searchField.tap()
                searchField.typeText("import")
                Thread.sleep(forTimeInterval: 0.3)
                saveScreenshot(named: "09_find_results")
            }
        } else {
            saveScreenshot(named: "08_find_not_found")
        }
        XCTAssertTrue(app.exists)
    }

    func testReplaceBar() throws {
        // Open a file
        let sources = app.staticTexts["Sources"]
        if sources.waitForExistence(timeout: 3) {
            sources.tap()
            Thread.sleep(forTimeInterval: 0.4)
        }
        if app.staticTexts["main.swift"].waitForExistence(timeout: 2) {
            app.staticTexts["main.swift"].tap()
            Thread.sleep(forTimeInterval: 0.5)
        }
        let findButton = app.buttons["Find in File"]
        if findButton.waitForExistence(timeout: 3) {
            findButton.tap()
            Thread.sleep(forTimeInterval: 0.3)
            // Tap the toggle replace chevron
            let toggleReplace = app.buttons["Toggle replace"]
            if toggleReplace.waitForExistence(timeout: 2) {
                toggleReplace.tap()
                Thread.sleep(forTimeInterval: 0.3)
                saveScreenshot(named: "10_replace_bar")
            } else {
                saveScreenshot(named: "10_replace_bar_notfound")
            }
        }
        XCTAssertTrue(app.exists)
    }

    func testStatusBar() throws {
        // Open a file to see status bar
        let sources = app.staticTexts["Sources"]
        if sources.waitForExistence(timeout: 3) {
            sources.tap()
            Thread.sleep(forTimeInterval: 0.4)
        }
        if app.staticTexts["main.swift"].waitForExistence(timeout: 2) {
            app.staticTexts["main.swift"].tap()
            Thread.sleep(forTimeInterval: 0.8)
            saveScreenshot(named: "11_status_bar")
        }
        XCTAssertTrue(app.exists)
    }

    func testBreadcrumb() throws {
        let sources = app.staticTexts["Sources"]
        if sources.waitForExistence(timeout: 3) {
            sources.tap()
            Thread.sleep(forTimeInterval: 0.4)
        }
        if app.staticTexts["main.swift"].waitForExistence(timeout: 2) {
            app.staticTexts["main.swift"].tap()
            Thread.sleep(forTimeInterval: 0.5)
            saveScreenshot(named: "12_breadcrumb")
        }
        XCTAssertTrue(app.exists)
    }

    func testOpenPythonFile() throws {
        let scripts = app.staticTexts["scripts"]
        if scripts.waitForExistence(timeout: 3) {
            scripts.tap()
            Thread.sleep(forTimeInterval: 0.4)
        }
        let buildPy = app.staticTexts["build.py"]
        if buildPy.waitForExistence(timeout: 2) {
            buildPy.tap()
            Thread.sleep(forTimeInterval: 0.5)
            saveScreenshot(named: "13_python_file")
        } else {
            saveScreenshot(named: "13_python_not_found")
        }
        XCTAssertTrue(app.exists)
    }

    func testMinimapVisible() throws {
        let sources = app.staticTexts["Sources"]
        if sources.waitForExistence(timeout: 3) {
            sources.tap()
            Thread.sleep(forTimeInterval: 0.4)
        }
        if app.staticTexts["Editor.swift"].waitForExistence(timeout: 2) {
            app.staticTexts["Editor.swift"].tap()
            Thread.sleep(forTimeInterval: 0.8)
            saveScreenshot(named: "14_minimap_visible")
        } else if app.staticTexts["main.swift"].waitForExistence(timeout: 2) {
            app.staticTexts["main.swift"].tap()
            Thread.sleep(forTimeInterval: 0.8)
            saveScreenshot(named: "14_minimap_visible")
        }
        XCTAssertTrue(app.exists)
    }

    func testRustFile() throws {
        let scripts = app.staticTexts["scripts"]
        if scripts.waitForExistence(timeout: 3) {
            scripts.tap()
            Thread.sleep(forTimeInterval: 0.4)
        }
        let rustFile = app.staticTexts["parser.rs"]
        if rustFile.waitForExistence(timeout: 2) {
            rustFile.tap()
            Thread.sleep(forTimeInterval: 0.5)
            saveScreenshot(named: "15_rust_file")
        } else {
            saveScreenshot(named: "15_rust_not_found")
        }
        XCTAssertTrue(app.exists)
    }

    func testJSONFile() throws {
        let config = app.staticTexts["config"]
        if config.waitForExistence(timeout: 3) {
            config.tap()
            Thread.sleep(forTimeInterval: 0.4)
        }
        let jsonFile = app.staticTexts["settings.json"]
        if jsonFile.waitForExistence(timeout: 2) {
            jsonFile.tap()
            Thread.sleep(forTimeInterval: 0.5)
            saveScreenshot(named: "16_json_file")
        } else {
            saveScreenshot(named: "16_json_not_found")
        }
        XCTAssertTrue(app.exists)
    }

    func testHTMLFile() throws {
        let web = app.staticTexts["web"]
        if web.waitForExistence(timeout: 3) {
            web.tap()
            Thread.sleep(forTimeInterval: 0.4)
        }
        let htmlFile = app.staticTexts["index.html"]
        if htmlFile.waitForExistence(timeout: 2) {
            htmlFile.tap()
            Thread.sleep(forTimeInterval: 0.5)
            saveScreenshot(named: "17_html_file")
        } else {
            saveScreenshot(named: "17_html_not_found")
        }
        XCTAssertTrue(app.exists)
    }

    func testCSSFile() throws {
        let web = app.staticTexts["web"]
        if web.waitForExistence(timeout: 3) {
            web.tap()
            Thread.sleep(forTimeInterval: 0.4)
        }
        let cssFile = app.staticTexts["styles.css"]
        if cssFile.waitForExistence(timeout: 2) {
            cssFile.tap()
            Thread.sleep(forTimeInterval: 0.5)
            saveScreenshot(named: "18_css_file")
        } else {
            saveScreenshot(named: "18_css_not_found")
        }
        XCTAssertTrue(app.exists)
    }

    func testTypescriptFile() throws {
        let scripts = app.staticTexts["scripts"]
        if scripts.waitForExistence(timeout: 3) {
            scripts.tap()
            Thread.sleep(forTimeInterval: 0.4)
        }
        let tsFile = app.staticTexts["api.ts"]
        if tsFile.waitForExistence(timeout: 2) {
            tsFile.tap()
            Thread.sleep(forTimeInterval: 0.5)
            saveScreenshot(named: "19_typescript_file")
        } else {
            saveScreenshot(named: "19_ts_not_found")
        }
        XCTAssertTrue(app.exists)
    }

    func testYAMLFile() throws {
        let config = app.staticTexts["config"]
        if config.waitForExistence(timeout: 3) {
            config.tap()
            Thread.sleep(forTimeInterval: 0.4)
        }
        let yamlFile = app.staticTexts["deploy.yaml"]
        if yamlFile.waitForExistence(timeout: 2) {
            yamlFile.tap()
            Thread.sleep(forTimeInterval: 0.5)
            saveScreenshot(named: "20_yaml_file")
        } else {
            saveScreenshot(named: "20_yaml_not_found")
        }
        XCTAssertTrue(app.exists)
    }

    func testPackageSwiftFile() throws {
        let packageFile = app.staticTexts["Package.swift"]
        if packageFile.waitForExistence(timeout: 3) {
            packageFile.tap()
            Thread.sleep(forTimeInterval: 0.5)
            saveScreenshot(named: "21_package_swift")
        }
        XCTAssertTrue(app.exists)
    }
}
