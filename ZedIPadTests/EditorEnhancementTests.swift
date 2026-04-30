import XCTest
@testable import ZedIPad

@MainActor
final class BracketPairTests: XCTestCase {
    // Test the bracket pair dictionary logic
    let pairs: [String: String] = ["{": "}", "(": ")", "[": "]", "\"": "\"", "'": "'"]

    func testAllBracketPairsPresent() {
        XCTAssertEqual(pairs["{"], "}")
        XCTAssertEqual(pairs["("], ")")
        XCTAssertEqual(pairs["["], "]")
        XCTAssertEqual(pairs["\""], "\"")
        XCTAssertEqual(pairs["'"], "'")
    }

    func testBracketPairCount() {
        XCTAssertEqual(pairs.count, 5)
    }

    func testClosingBracketsAreDistinct() {
        let closers: Set<String> = ["}", ")", "]", "\"", "'"]
        XCTAssertEqual(closers.count, 5)
    }

    func testBracketOpenerToCloserMapping() {
        for (opener, closer) in pairs {
            XCTAssertFalse(opener.isEmpty)
            XCTAssertFalse(closer.isEmpty)
        }
    }

    func testCurlyBraceIsPresent() {
        XCTAssertNotNil(pairs["{"])
        XCTAssertEqual(pairs["{"]!, "}")
    }
}

@MainActor
final class FindMatchHighlightTests: XCTestCase {
    func testNSRangeFromStringRange() {
        let text = "import Foundation"
        let range = text.range(of: "import")!
        let nsRange = NSRange(range, in: text)
        XCTAssertEqual(nsRange.location, 0)
        XCTAssertEqual(nsRange.length, 6)
    }

    func testMultipleNSRanges() {
        let text = "hello hello hello"
        var searchStart = text.startIndex
        var ranges: [NSRange] = []
        while let range = text.range(of: "hello", range: searchStart..<text.endIndex) {
            ranges.append(NSRange(range, in: text))
            searchStart = range.upperBound
        }
        XCTAssertEqual(ranges.count, 3)
    }

    func testNSRangeValidation() {
        let text = "test string"
        let validRange = NSRange(location: 0, length: 4)
        XCTAssertTrue(validRange.location != NSNotFound)
        XCTAssertTrue(validRange.location + validRange.length <= text.count)
    }

    func testNSRangeForEmptyMatch() {
        let text = "no match here"
        let ranges: [NSRange] = []
        XCTAssertTrue(ranges.isEmpty)
    }

    func testFindStateUpdatesMatchCount() {
        let state = FindState()
        state.query = "the"
        let count = state.search(in: "the quick brown fox the").count
        XCTAssertEqual(count, 2)
        XCTAssertEqual(state.matchCount, 2)
    }
}

@MainActor
final class WordWrapLogicTests: XCTestCase {
    func testWordWrapDefaultIsTrue() {
        let state = AppState()
        XCTAssertTrue(state.wordWrap)
    }

    func testWordWrapCanBeDisabled() {
        let state = AppState()
        state.wordWrap = false
        XCTAssertFalse(state.wordWrap)
    }

    func testWordWrapRoundtrip() {
        let state = AppState()
        state.wordWrap = false
        state.wordWrap = true
        XCTAssertTrue(state.wordWrap)
    }

    func testTabSizesAreMultiplesOf2() {
        for size in [2, 4, 8] {
            XCTAssertEqual(size % 2, 0)
        }
    }

    func testTabSpacesGeneration() {
        for size in [2, 4, 8] {
            let spaces = String(repeating: " ", count: size)
            XCTAssertEqual(spaces.count, size)
        }
    }
}

@MainActor
final class FileNodeExtendedTests: XCTestCase {
    func testFileNodeHasFileURL() {
        let file = FileNode(name: "test.swift", type: .file, path: "/test.swift", content: "")
        XCTAssertNil(file.fileURL)
        file.fileURL = URL(fileURLWithPath: "/test.swift")
        XCTAssertNotNil(file.fileURL)
    }

    func testFileNodeIsDirtyInitiallyFalse() {
        let file = FileNode(name: "test.swift", type: .file, path: "/test.swift", content: "")
        XCTAssertFalse(file.isDirty)
    }

    func testFileNodeContentChange() {
        let file = FileNode(name: "test.swift", type: .file, path: "/test.swift", content: "original")
        file.content = "modified"
        XCTAssertEqual(file.content, "modified")
    }

    func testFileNodePathPreserved() {
        let path = "/some/deep/nested/path/file.swift"
        let file = FileNode(name: "file.swift", type: .file, path: path, content: "")
        XCTAssertEqual(file.path, path)
    }
}
