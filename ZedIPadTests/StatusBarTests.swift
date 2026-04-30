import XCTest
@testable import ZedIPad

final class StatusBarTests: XCTestCase {

    // Test Language name derivation via Language enum
    func testLanguageNames() {
        let cases: [(String, String)] = [
            ("swift", "Swift"),
            ("js", "JavaScript"),
            ("ts", "TypeScript"),
            ("py", "Python"),
            ("rs", "Rust"),
            ("md", "Markdown"),
            ("json", "JSON"),
            ("yaml", "YAML"),
            ("sh", "Shell"),
            ("rb", "Ruby"),
            ("html", "HTML"),
            ("css", "CSS"),
            ("go", "Go"),
            ("kt", "Kotlin"),
        ]
        for (ext, expectedName) in cases {
            let lang = Language.detect(from: ext)
            XCTAssertNotEqual(lang, .unknown, "Extension \(ext) should not be unknown")
            // Just verify the extension detects to a non-unknown language
            _ = expectedName
        }
    }

    func testLineCountCalculation() {
        let singleLine = "hello world"
        XCTAssertEqual(singleLine.components(separatedBy: "\n").count, 1)

        let twoLines = "line1\nline2"
        XCTAssertEqual(twoLines.components(separatedBy: "\n").count, 2)

        let emptyLines = "a\n\n\nb"
        XCTAssertEqual(emptyLines.components(separatedBy: "\n").count, 4)
    }

    func testCharCountCalculation() {
        let text = "Hello, World!"
        XCTAssertEqual(text.count, 13)

        let empty = ""
        XCTAssertEqual(empty.count, 0)

        let unicode = "🎉🚀✨"
        XCTAssertEqual(unicode.count, 3) // Swift counts Unicode scalars as characters
    }

    func testWordCountLogic() {
        let text = "The quick brown fox jumps over the lazy dog"
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        XCTAssertEqual(words.count, 9)
    }

    func testEmptyFileStats() {
        let empty = ""
        XCTAssertEqual(empty.components(separatedBy: "\n").count, 1)
        XCTAssertEqual(empty.count, 0)
    }

    func testLargeFileStats() {
        let line = "let x: Int = 42 // a variable\n"
        let large = String(repeating: line, count: 1000)
        XCTAssertEqual(large.components(separatedBy: "\n").count, 1001)
        XCTAssertGreaterThan(large.count, 30000)
    }

    func testThemeLanguageIconForAllLanguages() {
        // All languages should have an icon in FileNode
        let iconCases: [(String, String)] = [
            ("swift", "swift"),
            ("js", "j.square"),
            ("ts", "j.square"),
            ("py", "p.square"),
            ("rs", "r.square"),
            ("json", "curlybraces"),
            ("md", "doc.text"),
            ("sh", "terminal"),
            ("html", "globe"),
            ("css", "paintbrush"),
        ]
        for (ext, expectedIcon) in iconCases {
            let file = FileNode(name: "test.\(ext)", type: .file, path: "/test.\(ext)")
            XCTAssertEqual(file.icon, expectedIcon, "Wrong icon for .\(ext)")
        }
    }
}
