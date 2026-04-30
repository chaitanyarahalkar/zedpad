import XCTest
import UniformTypeIdentifiers
@testable import ZedIPad

@MainActor
final class DocumentPickerTests: XCTestCase {

    func testFileNodeCreatedFromURL() {
        let url = URL(fileURLWithPath: "/tmp/test.swift")
        let node = FileNode(
            name: url.lastPathComponent,
            type: .file,
            path: url.path,
            content: "let x = 1"
        )
        XCTAssertEqual(node.name, "test.swift")
        XCTAssertEqual(node.path, "/tmp/test.swift")
        XCTAssertEqual(node.fileExtension, "swift")
        XCTAssertEqual(Language.detect(from: node.fileExtension), .swift)
    }

    func testFileNodeFromURLInAppState() {
        let state = AppState()
        let url = URL(fileURLWithPath: "/tmp/hello.py")
        let node = FileNode(
            name: url.lastPathComponent,
            type: .file,
            path: url.path,
            content: "print('hello')"
        )
        state.openFile(node)
        XCTAssertEqual(state.activeFile?.name, "hello.py")
        XCTAssertEqual(Language.detect(from: state.activeFile!.fileExtension), .python)
    }

    func testSupportedExtensions() {
        let supported = ["swift", "py", "js", "ts", "rs", "go", "kt", "scala",
                         "rb", "php", "lua", "sql", "c", "cpp", "h", "hpp",
                         "html", "css", "json", "yaml", "yml", "md", "sh", "r"]
        for ext in supported {
            let lang = Language.detect(from: ext)
            XCTAssertNotEqual(lang, .unknown, "Extension .\(ext) should not be unknown")
        }
    }

    func testUnsupportedExtensionFallsToUnknown() {
        let unsupported = ["exe", "dll", "bin", "pdf", "jpg", "png", "mp4"]
        for ext in unsupported {
            let lang = Language.detect(from: ext)
            XCTAssertEqual(lang, .unknown, "Extension .\(ext) should be unknown")
        }
    }

    func testFileNodeContentEditable() {
        let node = FileNode(name: "draft.swift", type: .file, path: "/draft.swift", content: "")
        XCTAssertTrue(node.content.isEmpty)
        node.content = "import Foundation"
        XCTAssertEqual(node.content, "import Foundation")
    }
}
