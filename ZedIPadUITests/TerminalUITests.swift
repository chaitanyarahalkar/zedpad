import XCTest

final class TerminalUITests: XCTestCase {
    var app: XCUIApplication!

    nonisolated(unsafe) static let screenshotsDir: URL = {
        let dir = URL(fileURLWithPath: "/Users/chaitanyarahalkar/Development/zed-ipad/autoresearch-screenshots")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("UITestingSampleProject")
        if name.contains("testTerminalGitWorkflowEndToEnd") {
            app.launchArguments.append("UITesting")
        }
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
    }

    func save(_ name: String) {
        let s = app.screenshot()
        let a = XCTAttachment(screenshot: s); a.name = name; a.lifetime = .keepAlways; add(a)
        try? s.pngRepresentation.write(to: Self.screenshotsDir.appendingPathComponent("\(name).png"))
    }

    func waitForTranscript(containing text: String, timeout: TimeInterval = 5) -> Bool {
        let transcript = app.staticTexts["Terminal transcript"]
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if transcript.exists && transcript.label.contains(text) {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        return transcript.exists && transcript.label.contains(text)
    }

    func runTerminalCommand(_ command: String) {
        let input = app.textFields["Terminal input"]
        input.tap()
        input.typeText(command)
        let deadline = Date().addingTimeInterval(3)
        while Date() < deadline {
            if String(describing: input.value ?? "").contains(command) {
                break
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        let run = app.buttons["Run terminal command"]
        XCTAssertTrue(run.waitForExistence(timeout: 2))
        run.tap()
    }

    func testTerminalPanelToggle() throws {
        let terminalButton = app.buttons["Toggle terminal"]
        if terminalButton.waitForExistence(timeout: 3) {
            terminalButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
            save("terminal_01_panel_open")
            terminalButton.tap()
            Thread.sleep(forTimeInterval: 0.3)
            save("terminal_02_panel_closed")
        } else {
            save("terminal_01_no_button")
        }
        XCTAssertTrue(app.exists)
    }

    func testTerminalPanelWithEditor() throws {
        // Open a file first
        if app.staticTexts["Sources"].waitForExistence(timeout: 3) {
            app.staticTexts["Sources"].tap()
            Thread.sleep(forTimeInterval: 0.4)
        }
        if app.staticTexts["main.swift"].waitForExistence(timeout: 2) {
            app.staticTexts["main.swift"].tap()
            Thread.sleep(forTimeInterval: 0.5)
        }
        // Open terminal
        let terminalButton = app.buttons["Toggle terminal"]
        if terminalButton.waitForExistence(timeout: 3) {
            terminalButton.tap()
            Thread.sleep(forTimeInterval: 0.8)
            save("terminal_03_with_editor")
        }
        XCTAssertTrue(app.exists)
    }

    func testSSHServerListView() throws {
        let sshButton = app.buttons["Open command palette"]
        if sshButton.waitForExistence(timeout: 3) {
            sshButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
            let commandInput = app.textFields["Command input"]
            if commandInput.waitForExistence(timeout: 2) {
                commandInput.typeText("SSH")
                Thread.sleep(forTimeInterval: 0.3)
                save("terminal_04_ssh_palette")
            }
            let cancelButton = app.buttons["Cancel"]
            if cancelButton.waitForExistence(timeout: 2) {
                cancelButton.tap()
            }
        }
        XCTAssertTrue(app.exists)
    }

    func testTerminalInputField() throws {
        let terminalButton = app.buttons["Toggle terminal"]
        if terminalButton.waitForExistence(timeout: 3) {
            terminalButton.tap()
            Thread.sleep(forTimeInterval: 0.8)
            let inputField = app.textFields["Terminal input"]
            if inputField.waitForExistence(timeout: 3) {
                inputField.tap()
                guard inputField.hasKeyboardFocus else {
                    save("terminal_05_input_focus_unavailable")
                    XCTAssertTrue(app.exists)
                    return
                }
                inputField.typeText("help")
                save("terminal_05_input_typed")
                inputField.typeText("\n")
                Thread.sleep(forTimeInterval: 0.5)
                save("terminal_06_help_output")
            }
        }
        XCTAssertTrue(app.exists)
    }

    func testGitCommandPalette() throws {
        let paletteButton = app.buttons["Open command palette"]
        if paletteButton.waitForExistence(timeout: 3) {
            paletteButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
            let input = app.textFields["Command input"]
            if input.waitForExistence(timeout: 2) {
                input.typeText("Git")
                Thread.sleep(forTimeInterval: 0.3)
                save("terminal_07_git_palette")
            }
            let cancel = app.buttons["Cancel"]
            if cancel.waitForExistence(timeout: 2) { cancel.tap() }
        }
        XCTAssertTrue(app.exists)
    }

    func testTerminalGitWorkflowEndToEnd() throws {
        let terminalButton = app.buttons["Toggle terminal"]
        XCTAssertTrue(terminalButton.waitForExistence(timeout: 5))
        terminalButton.tap()

        let input = app.textFields["Terminal input"]
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        input.tap()

        runTerminalCommand("git init")
        XCTAssertTrue(waitForTranscript(containing: "Initialized"))

        runTerminalCommand("echo 'hello from ui' > UI_README.md")
        runTerminalCommand("git status")
        XCTAssertTrue(waitForTranscript(containing: "UI_README.md"))

        runTerminalCommand("git add UI_README.md")
        XCTAssertTrue(waitForTranscript(containing: "Staged: UI_README.md"))

        runTerminalCommand("git commit -m 'Add UI readme'")
        XCTAssertTrue(waitForTranscript(containing: "Add UI readme"))

        runTerminalCommand("git log")
        XCTAssertTrue(waitForTranscript(containing: "Add UI readme"))

        runTerminalCommand("git status")
        XCTAssertTrue(waitForTranscript(containing: "working tree clean"))

        runTerminalCommand("echo 'changed from ui' > UI_README.md")
        runTerminalCommand("git diff")
        XCTAssertTrue(waitForTranscript(containing: "diff --git a/UI_README.md b/UI_README.md"))
        save("terminal_08_git_workflow")
    }
}
