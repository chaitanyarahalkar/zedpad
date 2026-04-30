import XCTest
@testable import ZedIPad

@MainActor
final class FileSaveTests: XCTestCase {
    func testFileSaveToTemporaryURL() throws {
        let file = FileNode(name: "test.swift", type: .file, path: "/test.swift", content: "let x = 1")
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_save.swift")
        file.fileURL = tempURL
        file.content = "let x = 42"

        // Write content
        try file.content.write(to: tempURL, atomically: true, encoding: .utf8)
        let readBack = try String(contentsOf: tempURL, encoding: .utf8)
        XCTAssertEqual(readBack, "let x = 42")

        // Clean up
        try? FileManager.default.removeItem(at: tempURL)
    }

    func testFileNodeDirtySetOnContentChange() {
        let file = FileNode(name: "test.swift", type: .file, path: "/test.swift", content: "initial")
        file.fileURL = URL(fileURLWithPath: "/fake/path.swift")
        file.content = "modified"
        XCTAssertTrue(file.isDirty)
    }

    func testFileNodeDirtyResetManually() {
        let file = FileNode(name: "test.swift", type: .file, path: "/test.swift", content: "initial")
        file.fileURL = URL(fileURLWithPath: "/fake/path.swift")
        file.content = "modified"
        XCTAssertTrue(file.isDirty)
        file.isDirty = false
        XCTAssertFalse(file.isDirty)
    }

    func testFileNodeNoURLNoDirty() {
        let file = FileNode(name: "test.swift", type: .file, path: "/test.swift", content: "")
        file.content = "changed"
        XCTAssertFalse(file.isDirty, "Without fileURL, isDirty should stay false")
    }

    func testFileSaveWithUnicodeContent() throws {
        let file = FileNode(name: "unicode.swift", type: .file, path: "/unicode.swift",
            content: "// 日本語テスト\nlet greeting = \"こんにちは\"\n// Emoji: 🚀")
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("unicode_test.swift")
        file.fileURL = tempURL
        try file.content.write(to: tempURL, atomically: true, encoding: .utf8)
        let readBack = try String(contentsOf: tempURL, encoding: .utf8)
        XCTAssertEqual(readBack, file.content)
        try? FileManager.default.removeItem(at: tempURL)
    }

    func testMultipleFilesHaveIndependentDirtyState() {
        let file1 = FileNode(name: "a.swift", type: .file, path: "/a.swift", content: "")
        let file2 = FileNode(name: "b.swift", type: .file, path: "/b.swift", content: "")
        file1.fileURL = URL(fileURLWithPath: "/a.swift")
        file2.fileURL = URL(fileURLWithPath: "/b.swift")
        file1.content = "changed"
        XCTAssertTrue(file1.isDirty)
        XCTAssertFalse(file2.isDirty)
    }

    func testSaveToRealFileRoundtrip() throws {
        let content = """
        import Foundation
        struct Config {
            let name = "ZedIPad"
            let version = "2.0.0"
        }
        """
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("roundtrip.swift")
        try content.write(to: tempURL, atomically: true, encoding: .utf8)
        let readBack = try String(contentsOf: tempURL)
        XCTAssertEqual(readBack, content)
        try? FileManager.default.removeItem(at: tempURL)
    }
}

@MainActor
final class LineNumberGutterTests: XCTestCase {
    func testLineCountCorrect() {
        let text = "line1\nline2\nline3"
        let lines = text.components(separatedBy: "\n").count
        XCTAssertEqual(lines, 3)
    }

    func testLineCountSingleLine() {
        let text = "single line"
        let lines = text.components(separatedBy: "\n").count
        XCTAssertEqual(lines, 1)
    }

    func testLineCountWithTrailingNewline() {
        let text = "line1\nline2\n"
        let lines = text.components(separatedBy: "\n").count
        XCTAssertEqual(lines, 3)
    }

    func testLineCountEmptyString() {
        let text = ""
        let lines = text.components(separatedBy: "\n").count
        XCTAssertEqual(lines, 1)
    }
}
