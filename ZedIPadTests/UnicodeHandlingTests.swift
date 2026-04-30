import XCTest
@testable import ZedIPad

@MainActor
final class UnicodeHandlingTests: XCTestCase {
    private let hl = SyntaxHighlighter(theme: .dark)

    func testHighlightCodeWithCJKCharacters() {
        let code = "// 中文注释\nlet name = \"こんにちは\"\nvar message: String = \"안녕하세요\""
        let tokens = hl.highlight(code, language: .swift)
        _ = tokens
    }

    func testHighlightCodeWithArabic() {
        let code = "// مرحبا\nvar text = \"مرحبا بالعالم\""
        let tokens = hl.highlight(code, language: .swift)
        _ = tokens
    }

    func testHighlightCodeWithEmojis() {
        let code = "let emoji = \"🎉\"\nlet rocket = \"🚀\"\n// ✨ sparkles ✨"
        let tokens = hl.highlight(code, language: .swift)
        _ = tokens
    }

    func testFindInUnicodeText() {
        let state = FindState()
        state.query = "hello"
        let text = "こんにちは hello 世界 hello!"
        let ranges = state.search(in: text)
        XCTAssertEqual(ranges.count, 2)
    }

    func testReplaceInUnicodeText() {
        let state = FindState()
        state.query = "world"
        state.replaceQuery = "世界"
        var text = "hello world! goodbye world."
        let count = state.replaceAll(in: &text)
        XCTAssertEqual(count, 2)
        XCTAssertTrue(text.contains("世界"))
    }

    func testFileNameWithUnicode() {
        let file = FileNode(name: "应用程序.swift", type: .file, path: "/应用程序.swift")
        XCTAssertEqual(file.fileExtension, "swift")
        XCTAssertEqual(Language.detect(from: file.fileExtension), .swift)
    }

    func testContentWithMixedScripts() {
        let file = FileNode(name: "mixed.py", type: .file, path: "/mixed.py",
                            content: "# Python script\nname = '世界'\nprint(f'Hello {name}')")
        XCTAssertFalse(file.content.isEmpty)
        let hl = SyntaxHighlighter(theme: .dark)
        let tokens = hl.highlight(file.content, language: .python)
        _ = tokens
    }

    func testLineCountWithUnicode() {
        let text = "hello\n世界\n🎉\nfoo"
        let lines = text.components(separatedBy: "\n")
        XCTAssertEqual(lines.count, 4)
    }

    func testCharCountWithEmoji() {
        let text = "hello 🌍"
        XCTAssertEqual(text.count, 7)
    }

    func testWordCountWithUnicode() {
        let text = "hello 世界 🎉 world"
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        XCTAssertEqual(words.count, 4)
    }
}
