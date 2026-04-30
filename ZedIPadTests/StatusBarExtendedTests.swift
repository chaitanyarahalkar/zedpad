import XCTest
@testable import ZedIPad

final class StatusBarExtendedTests: XCTestCase {

    func testWordCountSingleWord() {
        let text = "hello"
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        XCTAssertEqual(words.count, 1)
    }

    func testWordCountMultipleWords() {
        let text = "The quick brown fox"
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        XCTAssertEqual(words.count, 4)
    }

    func testWordCountMultipleLines() {
        let text = "line one\nline two\nline three"
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        XCTAssertEqual(words.count, 6)
    }

    func testWordCountWithExtraSpaces() {
        let text = "hello   world   foo"
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        XCTAssertEqual(words.count, 3)
    }

    func testWordCountEmptyString() {
        let text = ""
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        XCTAssertEqual(words.count, 0)
    }

    func testWordCountOnlyWhitespace() {
        let text = "   \n\t   "
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        XCTAssertEqual(words.count, 0)
    }

    func testLineCountSingleLine() {
        let text = "hello world"
        XCTAssertEqual(text.components(separatedBy: "\n").count, 1)
    }

    func testLineCountMultipleLines() {
        let text = "line1\nline2\nline3"
        XCTAssertEqual(text.components(separatedBy: "\n").count, 3)
    }

    func testLineCountTrailingNewline() {
        let text = "line1\nline2\n"
        XCTAssertEqual(text.components(separatedBy: "\n").count, 3)
    }

    func testCharCountUnicode() {
        let text = "hello 🌍"
        XCTAssertEqual(text.count, 7) // "hello " = 6 + emoji = 1
    }

    func testLanguageForAllKnownExtensions() {
        let knownExtensions = ["swift", "js", "ts", "py", "rs", "md", "json", "yaml",
                                "sh", "rb", "html", "css", "go", "kt", "c", "cpp", "sql",
                                "scala", "lua", "php", "r"]
        for ext in knownExtensions {
            let lang = Language.detect(from: ext)
            XCTAssertNotEqual(lang, .unknown, "Extension .\(ext) should be known")
        }
    }
}
