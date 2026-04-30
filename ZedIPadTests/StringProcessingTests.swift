import XCTest
@testable import ZedIPad

final class StringProcessingTests: XCTestCase {

    func testPathComponentSplit() {
        let path = "/my-project/Sources/main.swift"
        let components = path.split(separator: "/").map(String.init).filter { !$0.isEmpty }
        XCTAssertEqual(components, ["my-project", "Sources", "main.swift"])
    }

    func testPathComponentsSingleFile() {
        let path = "/README.md"
        let components = path.split(separator: "/").map(String.init).filter { !$0.isEmpty }
        XCTAssertEqual(components, ["README.md"])
    }

    func testPathComponentsEmpty() {
        let path = "/"
        let components = path.split(separator: "/").map(String.init).filter { !$0.isEmpty }
        XCTAssertTrue(components.isEmpty)
    }

    func testFileExtensionFromName() {
        let testCases: [(String, String)] = [
            ("main.swift", "swift"),
            ("index.html", "html"),
            ("styles.css", "css"),
            ("data.json", "json"),
            ("script.py", "py"),
            ("lib.rs", "rs"),
            ("Makefile", ""),
            (".gitignore", "gitignore"),
            ("file.tar.gz", "gz"),
            ("no_ext", ""),
        ]
        for (name, expectedExt) in testCases {
            let ext = (name as NSString).pathExtension.lowercased()
            XCTAssertEqual(ext, expectedExt, "Extension of '\(name)'")
        }
    }

    func testLineCountFromContent() {
        let cases: [(String, Int)] = [
            ("", 1),
            ("single line", 1),
            ("a\nb\nc", 3),
            ("a\n", 2),
            ("\n\n\n", 4),
        ]
        for (text, expectedLines) in cases {
            let count = text.components(separatedBy: "\n").count
            XCTAssertEqual(count, expectedLines, "Line count for: \(text.prefix(20))")
        }
    }

    func testRegexEscapeForLiteral() {
        let special = "foo.bar(baz)"
        let escaped = NSRegularExpression.escapedPattern(for: special)
        XCTAssertTrue(escaped.contains("\\."))
        XCTAssertTrue(escaped.contains("\\("))
        XCTAssertTrue(escaped.contains("\\)"))
    }

    func testRegexMatchCount() {
        let pattern = "\\d+"
        let text = "abc 123 def 456 ghi 789"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            XCTFail("Invalid regex")
            return
        }
        let count = regex.numberOfMatches(in: text, range: NSRange(text.startIndex..., in: text))
        XCTAssertEqual(count, 3)
    }

    func testCaseInsensitiveRegex() {
        let pattern = "swift"
        let options: NSRegularExpression.Options = [.caseInsensitive]
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            XCTFail("Invalid regex")
            return
        }
        let text = "Swift is great, SWIFT is fast, swift is fun"
        let count = regex.numberOfMatches(in: text, range: NSRange(text.startIndex..., in: text))
        XCTAssertEqual(count, 3)
    }
}
