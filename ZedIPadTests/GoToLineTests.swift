import XCTest
@testable import ZedIPad

@MainActor
final class GoToLineTests: XCTestCase {

    func testInitialState() {
        let state = GoToLineState()
        XCTAssertFalse(state.isVisible)
        XCTAssertEqual(state.lineNumber, "")
    }

    func testShowSetsVisible() {
        let state = GoToLineState()
        state.show()
        XCTAssertTrue(state.isVisible)
        XCTAssertEqual(state.lineNumber, "")
    }

    func testHideClearsState() {
        let state = GoToLineState()
        state.show()
        state.lineNumber = "42"
        state.hide()
        XCTAssertFalse(state.isVisible)
        XCTAssertEqual(state.lineNumber, "")
    }

    func testParsedLineValidNumber() {
        let state = GoToLineState()
        state.lineNumber = "42"
        XCTAssertEqual(state.parsedLine, 42)
    }

    func testParsedLineZeroIsNil() {
        let state = GoToLineState()
        state.lineNumber = "0"
        XCTAssertNil(state.parsedLine)
    }

    func testParsedLineNegativeIsNil() {
        let state = GoToLineState()
        state.lineNumber = "-5"
        XCTAssertNil(state.parsedLine)
    }

    func testParsedLineEmptyIsNil() {
        let state = GoToLineState()
        state.lineNumber = ""
        XCTAssertNil(state.parsedLine)
    }

    func testParsedLineNonNumericIsNil() {
        let state = GoToLineState()
        state.lineNumber = "abc"
        XCTAssertNil(state.parsedLine)
    }

    func testParsedLineFloatIsNil() {
        let state = GoToLineState()
        state.lineNumber = "3.14"
        XCTAssertNil(state.parsedLine)
    }

    func testParsedLineLargeNumber() {
        let state = GoToLineState()
        state.lineNumber = "99999"
        XCTAssertEqual(state.parsedLine, 99999)
    }

    func testShowThenShowResetsLineNumber() {
        let state = GoToLineState()
        state.show()
        state.lineNumber = "10"
        state.show() // show again
        XCTAssertEqual(state.lineNumber, "")
    }
}
