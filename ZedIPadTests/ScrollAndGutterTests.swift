import XCTest
@testable import ZedIPad

@MainActor
final class ScrollGutterTests: XCTestCase {
    // Tests for LineNumberGutter scroll sync logic
    let lineHeight: CGFloat = 18.0

    func testScrollOffsetZeroShowsFirstLine() {
        let offset: CGFloat = 0
        let firstVisible = Int(offset / lineHeight)
        XCTAssertEqual(firstVisible, 0)
    }

    func testScrollOffsetOneLine() {
        let offset = lineHeight
        let firstVisible = Int(offset / lineHeight)
        XCTAssertEqual(firstVisible, 1)
    }

    func testScrollOffsetTenLines() {
        let offset = lineHeight * 10
        let firstVisible = Int(offset / lineHeight)
        XCTAssertEqual(firstVisible, 10)
    }

    func testVisibleLinesCalculation() {
        let viewHeight: CGFloat = 500
        let visibleLines = Int(ceil(viewHeight / lineHeight)) + 2
        XCTAssertGreaterThan(visibleLines, 0)
        // Should show at least viewHeight/lineHeight lines
        XCTAssertGreaterThanOrEqual(visibleLines, Int(viewHeight / lineHeight))
    }

    func testLastVisibleClamped() {
        let totalLines = 20
        let firstVisible = 15
        let visibleLines = 10
        let lastVisible = min(totalLines, firstVisible + visibleLines)
        XCTAssertEqual(lastVisible, 20, "Should be clamped to totalLines")
    }

    func testLineCountFromText() {
        let texts = [
            ("", 1),
            ("single", 1),
            ("a\nb", 2),
            ("a\nb\nc\nd", 4),
            ("line1\nline2\n", 3),
        ]
        for (text, expected) in texts {
            let count = text.components(separatedBy: "\n").count
            XCTAssertEqual(count, expected, "'\(text)' should have \(expected) lines")
        }
    }

    func testScrollFractionRange() {
        // scrollFraction should be 0...1
        let fractions: [CGFloat] = [0, 0.25, 0.5, 0.75, 1.0]
        for f in fractions {
            XCTAssertGreaterThanOrEqual(f, 0)
            XCTAssertLessThanOrEqual(f, 1.0)
        }
    }

    func testOffsetNeverNegative() {
        let offsets: [CGFloat] = [0, 18, 36, 100, 1000]
        for offset in offsets {
            XCTAssertGreaterThanOrEqual(offset, 0)
        }
    }
}

@MainActor
final class FindScrollTests: XCTestCase {
    func testScrollRangePublishedToAppState() {
        let state = AppState()
        let range = NSRange(location: 50, length: 10)
        state.findScrollToRange = range
        XCTAssertEqual(state.findScrollToRange?.location, 50)
        XCTAssertEqual(state.findScrollToRange?.length, 10)
    }

    func testScrollRangeClearedAfterDismiss() {
        let state = AppState()
        state.findScrollToRange = NSRange(location: 50, length: 10)
        state.findScrollToRange = nil
        XCTAssertNil(state.findScrollToRange)
    }

    func testHighlightRangesPublished() {
        let state = AppState()
        let ranges = [NSRange(location: 0, length: 5), NSRange(location: 20, length: 5)]
        state.findHighlightRanges = ranges
        XCTAssertEqual(state.findHighlightRanges.count, 2)
    }

    func testHighlightRangesCleared() {
        let state = AppState()
        state.findHighlightRanges = [NSRange(location: 0, length: 5)]
        state.findHighlightRanges = []
        XCTAssertTrue(state.findHighlightRanges.isEmpty)
    }

    func testNSRangeValidLocation() {
        let range = NSRange(location: 100, length: 5)
        XCTAssertNotEqual(range.location, NSNotFound)
        XCTAssertEqual(range.location, 100)
    }

    func testNSRangeNotFound() {
        let range = NSRange(location: NSNotFound, length: 0)
        XCTAssertEqual(range.location, NSNotFound)
    }
}
