import XCTest
@testable import ZedIPad

@MainActor
final class FindReplaceEdgeCaseTests: XCTestCase {

    func testSearchInTextWithOnlyNewlines() {
        let state = FindState()
        state.query = "\n"
        state.isRegex = true
        let text = "\n\n\n"
        let ranges = state.search(in: text)
        XCTAssertGreaterThan(ranges.count, 0)
    }

    func testSearchWithDollarSign() {
        let state = FindState()
        state.query = "$"
        state.isRegex = false
        let text = "price: $9.99 and $19.99"
        let ranges = state.search(in: text)
        XCTAssertEqual(ranges.count, 2)
    }

    func testReplacePreservesTextAfterLastMatch() {
        let state = FindState()
        state.query = "old"
        state.replaceQuery = "new"
        var text = "old text old text suffix"
        let count = state.replaceAll(in: &text)
        XCTAssertEqual(count, 2)
        XCTAssertTrue(text.hasSuffix(" text suffix"))
    }

    func testReplacePreservesTextBeforeFirstMatch() {
        let state = FindState()
        state.query = "end"
        state.replaceQuery = "finish"
        var text = "prefix text end of line"
        let _ = state.replaceAll(in: &text)
        XCTAssertTrue(text.hasPrefix("prefix text finish"))
    }

    func testSearchCurrentMatchStaysValidAfterReplace() {
        let state = FindState()
        state.query = "x"
        state.replaceQuery = "y"
        var text = "x x x x x"
        let _ = state.search(in: text)
        XCTAssertEqual(state.matchCount, 5)
        state.replace(in: &text, at: 0)
        // After replace, search again
        let newRanges = state.search(in: text)
        XCTAssertEqual(newRanges.count, 4) // one replaced
    }

    func testSearchWithForwardSlash() {
        let state = FindState()
        state.query = "/"
        state.isRegex = false
        let text = "path/to/file.swift"
        let ranges = state.search(in: text)
        XCTAssertEqual(ranges.count, 2)
    }

    func testReplaceAllWithSameString() {
        let state = FindState()
        state.query = "hello"
        state.replaceQuery = "hello"
        var text = "hello world hello"
        let count = state.replaceAll(in: &text)
        XCTAssertEqual(count, 2)
        XCTAssertEqual(text, "hello world hello") // unchanged
    }

    func testSearchCountAfterMultipleSearches() {
        let state = FindState()
        let text = "aaa bbb aaa ccc aaa"
        state.query = "aaa"
        let _ = state.search(in: text)
        XCTAssertEqual(state.matchCount, 3)
        state.query = "bbb"
        let _ = state.search(in: text)
        XCTAssertEqual(state.matchCount, 1)
        state.query = "zzz"
        let _ = state.search(in: text)
        XCTAssertEqual(state.matchCount, 0)
    }
}
