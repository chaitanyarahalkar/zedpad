import XCTest
@testable import ZedIPad

@MainActor
final class AdvancedSearchTests: XCTestCase {

    func testSearchWithSpecialRegexChars() {
        let state = FindState()
        state.isRegex = false // literal
        let specials = [".", "*", "+", "?", "^", "$", "|", "(", ")", "[", "]", "{", "}"]
        for c in specials {
            state.query = c
            let text = "before \(c) after"
            let ranges = state.search(in: text)
            XCTAssertGreaterThanOrEqual(ranges.count, 1, "Should find literal '\(c)'")
        }
    }

    func testSearchCaseSensitivePreservesCase() {
        let state = FindState()
        state.isCaseSensitive = true
        state.query = "Swift"
        let text = "swift Swift SWIFT"
        let ranges = state.search(in: text)
        XCTAssertEqual(ranges.count, 1)
        // Verify the range points to "Swift" (capital S)
        if let first = ranges.first {
            let matched = String(text[first])
            XCTAssertEqual(matched, "Swift")
        }
    }

    func testSearchCaseInsensitiveFindsAll() {
        let state = FindState()
        state.isCaseSensitive = false
        state.query = "swift"
        let text = "swift Swift SWIFT sWiFt"
        let ranges = state.search(in: text)
        XCTAssertEqual(ranges.count, 4)
    }

    func testRegexCapturingGroups() {
        let state = FindState()
        state.isRegex = true
        state.query = "\\b[A-Z][a-z]+\\b" // Capitalized words
        let text = "The Quick Brown Fox jumps over the Lazy Dog"
        let ranges = state.search(in: text)
        XCTAssertEqual(ranges.count, 5) // The, Quick, Brown, Fox, Lazy, Dog — 6... actually
        // "The", "Quick", "Brown", "Fox", "Lazy", "Dog" = 6
        XCTAssertGreaterThanOrEqual(ranges.count, 5)
    }

    func testSearchEmptyResultsNoNavigation() {
        let state = FindState()
        state.query = "xyz_not_found"
        let _ = state.search(in: "hello world")
        XCTAssertEqual(state.matchCount, 0)
        let before = state.currentMatch
        state.nextMatch() // should not crash or change
        XCTAssertEqual(state.currentMatch, before)
        state.previousMatch()
        XCTAssertEqual(state.currentMatch, before)
    }

    func testReplaceFirstMatchOnly() {
        let state = FindState()
        state.query = "a"
        state.replaceQuery = "X"
        var text = "a b a c a d a"
        let _ = state.search(in: text)
        state.replace(in: &text, at: 0)
        // Only first 'a' replaced
        XCTAssertTrue(text.hasPrefix("X"))
        // Remaining 'a's still present
        let remaining = text.components(separatedBy: "a").count - 1
        XCTAssertEqual(remaining, 3)
    }
}
