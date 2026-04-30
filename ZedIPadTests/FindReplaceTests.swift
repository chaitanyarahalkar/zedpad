import XCTest
@testable import ZedIPad

@MainActor
final class FindReplaceTests: XCTestCase {

    // MARK: - Replace single

    func testReplaceCurrentMatch() {
        let state = FindState()
        state.query = "foo"
        state.replaceQuery = "bar"
        var text = "foo baz foo"
        let _ = state.search(in: text)
        XCTAssertEqual(state.matchCount, 2)
        state.replace(in: &text, at: 0)
        XCTAssertTrue(text.contains("bar"))
    }

    func testReplaceAll() {
        let state = FindState()
        state.query = "hello"
        state.replaceQuery = "world"
        var text = "hello there hello hello"
        let _ = state.search(in: text)
        let count = state.replaceAll(in: &text)
        XCTAssertEqual(count, 3)
        XCTAssertFalse(text.contains("hello"))
        XCTAssertEqual(text.components(separatedBy: "world").count - 1, 3)
    }

    func testReplaceAllCaseInsensitive() {
        let state = FindState()
        state.query = "SWIFT"
        state.replaceQuery = "Kotlin"
        state.isCaseSensitive = false
        var text = "swift is great, SWIFT is fast, Swift is fun"
        let _ = state.search(in: text)
        let count = state.replaceAll(in: &text)
        XCTAssertEqual(count, 3)
        XCTAssertFalse(text.lowercased().contains("swift"))
    }

    func testReplaceAllWithEmptyReplace() {
        let state = FindState()
        state.query = "remove"
        state.replaceQuery = ""
        var text = "please remove this word and remove that"
        let _ = state.search(in: text)
        let count = state.replaceAll(in: &text)
        XCTAssertEqual(count, 2)
        XCTAssertFalse(text.contains("remove"))
    }

    func testReplaceAllResetsMatchCount() {
        let state = FindState()
        state.query = "x"
        state.replaceQuery = "y"
        var text = "x x x"
        let _ = state.search(in: text)
        XCTAssertEqual(state.matchCount, 3)
        let _ = state.replaceAll(in: &text)
        XCTAssertEqual(state.matchCount, 0)
        XCTAssertEqual(state.currentMatch, 0)
    }

    func testReplaceWithNoMatches() {
        let state = FindState()
        state.query = "missing"
        state.replaceQuery = "present"
        var text = "no match here"
        let _ = state.search(in: text)
        let count = state.replaceAll(in: &text)
        XCTAssertEqual(count, 0)
        XCTAssertEqual(text, "no match here")
    }

    func testReplaceAllRegex() {
        let state = FindState()
        state.query = "\\d+"
        state.replaceQuery = "NUM"
        state.isRegex = true
        var text = "price 42 and size 100"
        let _ = state.search(in: text)
        XCTAssertEqual(state.matchCount, 2)
        let count = state.replaceAll(in: &text)
        XCTAssertEqual(count, 2)
        XCTAssertTrue(text.contains("NUM"))
    }

    // MARK: - Syntax highlighter replace interaction

    func testHighlightAfterReplace() {
        let hl = SyntaxHighlighter(theme: .dark)
        let original = "import Foundation\nlet x = 42"
        let state = FindState()
        state.query = "Foundation"
        state.replaceQuery = "SwiftUI"
        var text = original
        let _ = state.search(in: text)
        let _ = state.replaceAll(in: &text)
        // After replace, highlighting should still work
        let tokens = hl.highlight(text, language: .swift)
        XCTAssertFalse(tokens.isEmpty)
        XCTAssertTrue(text.contains("SwiftUI"))
    }

    // MARK: - Edge cases

    func testSearchWithSpecialCharacters() {
        let state = FindState()
        state.query = "hello.world"
        state.isRegex = false  // literal search
        let ranges = state.search(in: "hello.world is great")
        XCTAssertEqual(ranges.count, 1)
    }

    func testSearchMultiline() {
        let state = FindState()
        state.query = "line"
        let ranges = state.search(in: "line one\nline two\nthird line")
        XCTAssertEqual(ranges.count, 3)
    }

    func testSearchUnicode() {
        let state = FindState()
        state.query = "emoji"
        let ranges = state.search(in: "find emoji 🎉 and emoji 🚀 here")
        XCTAssertEqual(ranges.count, 2)
    }
}
