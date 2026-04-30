import XCTest
@testable import ZedIPad

final class FileTreeExpansionTests: XCTestCase {

    func testExpandAllDirectories() {
        let root = FileNode.sampleRoot()
        func expandAll(_ node: FileNode) {
            if node.type == .directory {
                node.isExpanded = true
                node.children?.forEach { expandAll($0) }
            }
        }
        expandAll(root)
        func checkExpanded(_ node: FileNode) {
            if node.type == .directory {
                XCTAssertTrue(node.isExpanded, "Dir \(node.name) should be expanded")
            }
            node.children?.forEach { checkExpanded($0) }
        }
        checkExpanded(root)
    }

    func testCollapseAllDirectories() {
        let root = FileNode.sampleRoot()
        root.isExpanded = true
        root.children?.forEach { $0.isExpanded = true }
        func collapseAll(_ node: FileNode) {
            node.isExpanded = false
            node.children?.forEach { collapseAll($0) }
        }
        collapseAll(root)
        func checkCollapsed(_ node: FileNode) {
            if node.type == .directory {
                XCTAssertFalse(node.isExpanded, "Dir \(node.name) should be collapsed")
            }
            node.children?.forEach { checkCollapsed($0) }
        }
        checkCollapsed(root)
    }

    func testDirectoryChildCount() {
        let root = FileNode.sampleRoot()
        XCTAssertGreaterThan(root.children?.count ?? 0, 3, "Root should have multiple children")
    }

    func testFolderNesting() {
        let root = FileNode.sampleRoot()
        let sources = root.children?.first { $0.name == "Sources" }
        XCTAssertNotNil(sources)
        XCTAssertEqual(sources?.type, .directory)
        let mainSwift = sources?.children?.first { $0.name == "main.swift" }
        XCTAssertNotNil(mainSwift)
        XCTAssertEqual(mainSwift?.type, .file)
    }

    func testDeepNestingDoesntCrash() {
        var current = FileNode(name: "root", type: .directory, path: "/root", children: [])
        for i in 0..<20 {
            let child = FileNode(name: "level\(i)", type: .directory, path: "/root/level\(i)", children: [])
            current.children = [child]
            current = child
        }
        // Just verify we can traverse it
        var depth = 0
        var node: FileNode? = current
        while node != nil {
            depth += 1
            node = node?.children?.first
        }
        XCTAssertGreaterThan(depth, 0)
    }

    func testAllTopLevelFolderIcons() {
        let root = FileNode.sampleRoot()
        let dirs = root.children?.filter { $0.type == .directory } ?? []
        for dir in dirs {
            XCTAssertEqual(dir.icon, "folder", "Collapsed dir \(dir.name) should have folder icon")
            dir.isExpanded = true
            XCTAssertEqual(dir.icon, "folder.fill", "Expanded dir \(dir.name) should have folder.fill icon")
        }
    }

    func testFilterQueryPreservesDirectoryStructure() {
        let root = FileNode.sampleRoot()
        // Filter for swift files
        let filtered = root.filtered(by: ".swift")
        XCTAssertNotNil(filtered)
        // All remaining nodes should be directories or .swift files
        func checkStructure(_ node: FileNode) {
            if node.type == .file {
                XCTAssertEqual(node.fileExtension, "swift",
                               "After filter, files should be .swift files, got: \(node.name)")
            }
            node.children?.forEach { checkStructure($0) }
        }
        if let f = filtered { checkStructure(f) }
    }
}
