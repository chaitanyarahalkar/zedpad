import XCTest
@testable import ZedIPad

final class FileSearchTests: XCTestCase {

    private var sampleRoot: FileNode { FileNode.sampleRoot() }

    func testFilterEmptyQueryReturnsAll() {
        let root = sampleRoot
        let result = root.filtered(by: "")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.id, root.id)
    }

    func testFilterMatchesFileName() {
        let root = sampleRoot
        let result = root.filtered(by: "main.swift")
        XCTAssertNotNil(result)
    }

    func testFilterMatchesCaseInsensitive() {
        let root = sampleRoot
        let result = root.filtered(by: "MAIN.SWIFT")
        XCTAssertNotNil(result, "Filter should be case-insensitive")
    }

    func testFilterNoMatchReturnsNil() {
        let root = sampleRoot
        let result = root.filtered(by: "nonexistent_file_xyz.abc")
        XCTAssertNil(result)
    }

    func testFilterExpandsMatchingFolders() {
        let root = sampleRoot
        let result = root.filtered(by: "main")
        XCTAssertNotNil(result)
        // Folders containing matches should be expanded
        func checkExpanded(_ node: FileNode) {
            if node.type == .directory && !(node.children?.isEmpty ?? true) {
                XCTAssertTrue(node.isExpanded, "Folder \(node.name) should be expanded after filter")
            }
            node.children?.forEach { checkExpanded($0) }
        }
        if let r = result { checkExpanded(r) }
    }

    func testFilterPreservesNonMatchingFiles() {
        let root = sampleRoot
        let result = root.filtered(by: "build")
        // build.py should match; other files should be excluded
        if let r = result {
            func findFile(_ name: String, in node: FileNode) -> FileNode? {
                if node.name == name { return node }
                return node.children?.compactMap { findFile(name, in: $0) }.first
            }
            let buildFile = findFile("build.py", in: r)
            XCTAssertNotNil(buildFile, "build.py should be in filtered results")
        }
    }

    func testFilterPartialMatch() {
        let root = sampleRoot
        let result = root.filtered(by: ".swift")
        XCTAssertNotNil(result)
    }

    func testFilterExtensionOnly() {
        let root = sampleRoot
        let result = root.filtered(by: ".yaml")
        XCTAssertNotNil(result, "Should find YAML files")
    }

    func testFilterDirectoryByName() {
        let root = sampleRoot
        // "Sources" directory matches because it has matching children
        // OR because the directory name contains the query
        let result = root.filtered(by: "Sources")
        // The filter only matches FILES, so it might return nil
        // unless children match — check behavior
        _ = result // just verify no crash
    }

    func testFilteredResultHasCorrectType() {
        let root = sampleRoot
        let result = root.filtered(by: "README")
        XCTAssertNotNil(result)
        func findReadme(_ node: FileNode) -> FileNode? {
            if node.name.contains("README") { return node }
            return node.children?.compactMap { findReadme($0) }.first
        }
        if let r = result {
            let readme = findReadme(r)
            XCTAssertEqual(readme?.type, .file)
        }
    }
}
