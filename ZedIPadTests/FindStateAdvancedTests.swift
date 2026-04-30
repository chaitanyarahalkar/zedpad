import XCTest
@testable import ZedIPad

@MainActor
final class FindStateAdvancedTests: XCTestCase {

    func testSearchInMultilineCode() {
        let state = FindState()
        state.query = "return"
        let code = """
        func add(a: Int, b: Int) -> Int {
            return a + b
        }
        func multiply(a: Int, b: Int) -> Int {
            return a * b
        }
        """
        let ranges = state.search(in: code)
        XCTAssertEqual(ranges.count, 2)
    }

    func testRegexSearchComplexPattern() {
        let state = FindState()
        state.isRegex = true
        state.query = "func [a-z]+\\("
        let code = "func hello() {}\nfunc world() {}\nfunc Capitalized() {}"
        let ranges = state.search(in: code)
        XCTAssertEqual(ranges.count, 2) // Capitalized doesn't match
    }

    func testCaseSensitiveSearch() {
        let state = FindState()
        state.isCaseSensitive = true
        state.query = "Swift"
        let text = "swift is great, Swift is better, SWIFT is caps"
        let ranges = state.search(in: text)
        XCTAssertEqual(ranges.count, 1)
    }

    func testReplaceWithLongerString() {
        let state = FindState()
        state.query = "x"
        state.replaceQuery = "longVariableName"
        var text = "let x = x + 1"
        let count = state.replaceAll(in: &text)
        XCTAssertEqual(count, 2)
        XCTAssertFalse(text.contains(" x "))
        XCTAssertTrue(text.contains("longVariableName"))
    }

    func testReplaceWithShorterString() {
        let state = FindState()
        state.query = "longVariableName"
        state.replaceQuery = "v"
        var text = "let longVariableName = longVariableName + 1"
        let count = state.replaceAll(in: &text)
        XCTAssertEqual(count, 2)
        XCTAssertFalse(text.contains("longVariableName"))
    }

    func testSearchDoesNotModifyText() {
        let state = FindState()
        state.query = "test"
        let original = "test text test"
        var copy = original
        let _ = state.search(in: copy)
        XCTAssertEqual(copy, original)
    }

    func testNextMatchWrapsAtEnd() {
        let state = FindState()
        state.query = "x"
        let _ = state.search(in: "x y x z x")
        XCTAssertEqual(state.matchCount, 3)
        state.nextMatch() // 0→1
        state.nextMatch() // 1→2
        state.nextMatch() // 2→0 (wrap)
        XCTAssertEqual(state.currentMatch, 0)
    }

    func testPrevMatchAtZeroWraps() {
        let state = FindState()
        state.query = "a"
        let _ = state.search(in: "a b a c a")
        XCTAssertEqual(state.matchCount, 3)
        XCTAssertEqual(state.currentMatch, 0)
        state.previousMatch() // 0→2 (wrap)
        XCTAssertEqual(state.currentMatch, 2)
    }

    func testSearchCountConsistentWithMatchCount() {
        let state = FindState()
        state.query = "foo"
        let text = "foo bar foo baz foo qux"
        let ranges = state.search(in: text)
        XCTAssertEqual(ranges.count, state.matchCount)
        XCTAssertEqual(state.matchCount, 3)
    }
}
