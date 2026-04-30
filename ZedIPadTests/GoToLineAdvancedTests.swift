import XCTest
@testable import ZedIPad

@MainActor
final class GoToLineAdvancedTests: XCTestCase {

    func testGoToLineWithContent() {
        let state = GoToLineState()
        let content = (1...50).map { "line \($0) content" }.joined(separator: "\n")
        let lineCount = content.components(separatedBy: "\n").count
        XCTAssertEqual(lineCount, 50)
        state.lineNumber = "25"
        let line = state.parsedLine!
        let clamped = max(1, min(line, lineCount))
        XCTAssertEqual(clamped, 25)
    }

    func testGoToLineClampedToMax() {
        let lineCount = 100
        let state = GoToLineState()
        state.lineNumber = "999"
        let line = state.parsedLine!
        let clamped = max(1, min(line, lineCount))
        XCTAssertEqual(clamped, 100)
    }

    func testGoToLineClampedToMin() {
        let lineCount = 100
        let state = GoToLineState()
        state.lineNumber = "1"
        let line = state.parsedLine!
        let clamped = max(1, min(line, lineCount))
        XCTAssertEqual(clamped, 1)
    }

    func testGoToLineVisibilityToggle() {
        let state = GoToLineState()
        XCTAssertFalse(state.isVisible)
        state.show(); XCTAssertTrue(state.isVisible)
        state.hide(); XCTAssertFalse(state.isVisible)
        state.show(); XCTAssertTrue(state.isVisible)
        state.show(); XCTAssertTrue(state.isVisible) // show twice
        XCTAssertEqual(state.lineNumber, "") // reset
    }

    func testGoToLineWithMultipleEdits() {
        let state = GoToLineState()
        state.show()
        state.lineNumber = "1"
        XCTAssertEqual(state.parsedLine, 1)
        state.lineNumber = "50"
        XCTAssertEqual(state.parsedLine, 50)
        state.lineNumber = "100"
        XCTAssertEqual(state.parsedLine, 100)
        state.hide()
        XCTAssertNil(state.parsedLine)
    }

    func testAllLargeFileNavigations() {
        let state = GoToLineState()
        let lineNumbers = [1, 10, 100, 1000, 9999]
        let maxLines = 10000
        for lineNum in lineNumbers {
            state.lineNumber = "\(lineNum)"
            if let parsed = state.parsedLine {
                let clamped = max(1, min(parsed, maxLines))
                XCTAssertEqual(clamped, lineNum)
            }
        }
    }
}
