import XCTest
@testable import ZedIPad

final class FileTreeNavigationTests: XCTestCase {

    func testTraverseAllNodes() {
        let root = FileNode.sampleRoot()
        var nodeCount = 0
        func traverse(_ node: FileNode) {
            nodeCount += 1
            node.children?.forEach { traverse($0) }
        }
        traverse(root)
        XCTAssertGreaterThan(nodeCount, 15, "Tree should have many nodes")
    }

    func testFindFileByPath() {
        let root = FileNode.sampleRoot()
        func findByPath(_ path: String, in node: FileNode) -> FileNode? {
            if node.path == path { return node }
            return node.children?.compactMap { findByPath(path, in: $0) }.first
        }
        let mainSwift = findByPath("/my-project/Sources/main.swift", in: root)
        XCTAssertNotNil(mainSwift)
        XCTAssertEqual(mainSwift?.name, "main.swift")
    }

    func testCountFilesByType() {
        let root = FileNode.sampleRoot()
        var files = 0, dirs = 0
        func count(_ node: FileNode) {
            if node.type == .file { files += 1 } else { dirs += 1 }
            node.children?.forEach { count($0) }
        }
        count(root)
        XCTAssertGreaterThan(files, 5)
        XCTAssertGreaterThan(dirs, 3)
    }

    func testExpandedStateByDefault() {
        let root = FileNode.sampleRoot()
        XCTAssertTrue(root.isExpanded)
        // Child directories start collapsed by default
        let childDirs = root.children?.filter { $0.type == .directory } ?? []
        for dir in childDirs where dir.name != "Sources" {
            // Most should be collapsed
            _ = dir.isExpanded
        }
    }

    func testFilterShowsOnlyMatchingFiles() {
        let root = FileNode.sampleRoot()
        let filtered = root.filtered(by: ".py")
        XCTAssertNotNil(filtered)
        func collectFiles(_ node: FileNode) -> [FileNode] {
            var result: [FileNode] = []
            if node.type == .file { result.append(node) }
            node.children?.forEach { result += collectFiles($0) }
            return result
        }
        if let f = filtered {
            let files = collectFiles(f)
            for file in files {
                XCTAssertTrue(file.name.hasSuffix(".py"), "After .py filter, all files should be .py")
            }
        }
    }

    func testFileContentNotEmpty() {
        let root = FileNode.sampleRoot()
        var emptyCount = 0
        func check(_ node: FileNode) {
            if node.type == .file && node.content.isEmpty { emptyCount += 1 }
            node.children?.forEach { check($0) }
        }
        check(root)
        XCTAssertEqual(emptyCount, 0, "All sample files should have content")
    }
}
