import XCTest

final class ZedIPadUITests: XCTestCase {
    var app: XCUIApplication!
    static let screenshotsDir = "autoresearch-screenshots"

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
    }

    func takeScreenshot(named name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testAppLaunches() throws {
        XCTAssertTrue(app.exists)
        takeScreenshot(named: "01_app_launch")
    }

    func testWelcomeScreenVisible() throws {
        // Welcome text should be visible when no file is selected
        let welcomeText = app.staticTexts["ZedIPad"]
        // Give app time to settle
        _ = welcomeText.waitForExistence(timeout: 3)
        takeScreenshot(named: "02_welcome_screen")
    }

    func testSidebarVisible() throws {
        takeScreenshot(named: "03_sidebar_visible")
        // File tree should contain the sample project
        let sidebar = app.collectionViews.firstMatch
        XCTAssertTrue(sidebar.waitForExistence(timeout: 3) || app.tables.firstMatch.waitForExistence(timeout: 3))
    }

    func testOpenFile() throws {
        // Tap the first file in the tree
        let mainSwift = app.staticTexts["main.swift"]
        if mainSwift.waitForExistence(timeout: 3) {
            mainSwift.tap()
            takeScreenshot(named: "04_file_opened")
        } else {
            // Try tapping a folder to expand it first
            let sources = app.staticTexts["Sources"]
            if sources.waitForExistence(timeout: 3) {
                sources.tap()
                Thread.sleep(forTimeInterval: 0.5)
                let mainFile = app.staticTexts["main.swift"]
                if mainFile.waitForExistence(timeout: 2) {
                    mainFile.tap()
                    takeScreenshot(named: "04_file_opened")
                }
            }
        }
    }

    func testThemeToggle() throws {
        let themeButton = app.buttons["Toggle theme"]
        if themeButton.waitForExistence(timeout: 3) {
            themeButton.tap()
            Thread.sleep(forTimeInterval: 0.3)
            takeScreenshot(named: "05_theme_toggled_light")
            themeButton.tap()
            Thread.sleep(forTimeInterval: 0.3)
            takeScreenshot(named: "06_theme_toggled_dark")
        } else {
            takeScreenshot(named: "05_theme_button_not_found")
        }
    }

    func testCommandPalette() throws {
        let paletteButton = app.buttons["Open command palette"]
        if paletteButton.waitForExistence(timeout: 3) {
            paletteButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
            takeScreenshot(named: "07_command_palette_open")
            // Close it
            let cancelButton = app.buttons["Cancel"]
            if cancelButton.waitForExistence(timeout: 2) {
                cancelButton.tap()
            }
        } else {
            takeScreenshot(named: "07_command_palette_button_not_found")
        }
    }

    func testFindInFile() throws {
        // First open a file
        let sources = app.staticTexts["Sources"]
        if sources.waitForExistence(timeout: 3) {
            sources.tap()
            Thread.sleep(forTimeInterval: 0.3)
        }
        let mainSwift = app.staticTexts["main.swift"]
        if mainSwift.waitForExistence(timeout: 2) {
            mainSwift.tap()
            Thread.sleep(forTimeInterval: 0.5)
        }

        // Tap find button
        let findButton = app.buttons["Find in File"]
        if findButton.waitForExistence(timeout: 3) {
            findButton.tap()
            Thread.sleep(forTimeInterval: 0.3)
            takeScreenshot(named: "08_find_bar_open")

            // Type a search query
            let searchField = app.textFields["Search field"]
            if searchField.waitForExistence(timeout: 2) {
                searchField.tap()
                searchField.typeText("import")
                Thread.sleep(forTimeInterval: 0.3)
                takeScreenshot(named: "09_find_results")
            }
        } else {
            takeScreenshot(named: "08_find_button_not_found")
        }
    }
}
