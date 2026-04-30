import XCTest
@testable import ZedIPad

final class SearchBarTests: XCTestCase {

    func testFilterEmptyReturnsRoot() {
        let root = FileNode.sampleRoot()
        let result = root.filtered(by: "")
        XCTAssertEqual(result?.id, root.id)
    }

    func testFilterSingleCharacter() {
        let root = FileNode.sampleRoot()
        let result = root.filtered(by: "s")
        XCTAssertNotNil(result) // Should find files with 's' in name
    }

    func testFilterDotExtension() {
        let root = FileNode.sampleRoot()
        let result = root.filtered(by: ".json")
        XCTAssertNotNil(result)
    }

    func testFilterMultipleMatches() {
        let root = FileNode.sampleRoot()
        let result = root.filtered(by: ".swift")
        XCTAssertNotNil(result)
        var count = 0
        func countFiles(_ node: FileNode) {
            if node.type == .file { count += 1 }
            node.children?.forEach { countFiles($0) }
        }
        if let r = result { countFiles(r) }
        XCTAssertGreaterThan(count, 1, "Should find multiple .swift files")
    }

    func testFilterPreservesFileContent() {
        let root = FileNode.sampleRoot()
        let filtered = root.filtered(by: "README")
        func findReadme(_ node: FileNode) -> FileNode? {
            if node.name.hasPrefix("README") { return node }
            return node.children?.compactMap { findReadme($0) }.first
        }
        if let readme = filtered.flatMap({ findReadme($0) }) {
            XCTAssertFalse(readme.content.isEmpty, "README should have content after filtering")
        }
    }

    func testFilterNoMatchReturnsNilForFileNode() {
        let file = FileNode(name: "specific.swift", type: .file, path: "/specific.swift")
        let result = file.filtered(by: "nomatch")
        XCTAssertNil(result, "File not matching query should return nil")
    }

    func testFilterMatchReturnsFileNode() {
        let file = FileNode(name: "specific.swift", type: .file, path: "/specific.swift")
        let result = file.filtered(by: "specific")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.id, file.id)
    }

    func testFilterDirectoryWithNoMatchingDescendants() {
        let dir = FileNode(name: "empty-dir", type: .directory, path: "/empty", children: [
            FileNode(name: "a.swift", type: .file, path: "/empty/a.swift"),
            FileNode(name: "b.swift", type: .file, path: "/empty/b.swift"),
        ])
        let result = dir.filtered(by: "python")
        XCTAssertNil(result)
    }

    func testFilterDirectoryWithSomeMatchingDescendants() {
        let dir = FileNode(name: "mixed", type: .directory, path: "/mixed", children: [
            FileNode(name: "main.swift", type: .file, path: "/mixed/main.swift"),
            FileNode(name: "app.py", type: .file, path: "/mixed/app.py"),
        ])
        let result = dir.filtered(by: ".swift")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.children?.count, 1)
        XCTAssertEqual(result?.children?.first?.name, "main.swift")
    }
}
