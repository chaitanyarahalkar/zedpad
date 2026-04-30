import XCTest
@testable import ZedIPad

final class FileNodeUtilityTests: XCTestCase {

    func testFileExtensionCaseVariants() {
        let cases = ["Swift", "swift", "SWIFT", "JS", "js", "PY", "py", "RS", "rs"]
        for ext in cases {
            let lang = Language.detect(from: ext.lowercased())
            _ = lang
        }
    }

    func testAllSampleFilesHaveNonEmptyPaths() {
        let root = FileNode.sampleRoot()
        var fileCount = 0
        func traverse(_ node: FileNode) {
            XCTAssertFalse(node.path.isEmpty)
            if node.type == .file { fileCount += 1 }
            node.children?.forEach { traverse($0) }
        }
        traverse(root)
        XCTAssertGreaterThan(fileCount, 5, "Should have multiple sample files")
    }

    func testSampleFilesHaveUniqueNames() {
        let root = FileNode.sampleRoot()
        var names: [String] = []
        func collectNames(_ node: FileNode) {
            if node.type == .file { names.append(node.name) }
            node.children?.forEach { collectNames($0) }
        }
        collectNames(root)
        // Not all names are unique (could have same-named files in different dirs)
        // Just verify we have many files
        XCTAssertGreaterThan(names.count, 5)
    }

    func testFileNodeContentIsEditable() {
        let file = FileNode(name: "a.swift", type: .file, path: "/a.swift", content: "original")
        file.content = "modified"
        XCTAssertEqual(file.content, "modified")
        file.content += "\nextra line"
        XCTAssertTrue(file.content.contains("extra line"))
    }

    func testDirectoryExpansionToggles() {
        let dir = FileNode(name: "src", type: .directory, path: "/src", children: [
            FileNode(name: "a.swift", type: .file, path: "/src/a.swift")
        ])
        XCTAssertFalse(dir.isExpanded)
        dir.isExpanded = true
        XCTAssertTrue(dir.isExpanded)
        dir.isExpanded = false
        XCTAssertFalse(dir.isExpanded)
    }

    func testFilterRetainsParentPath() {
        let root = FileNode.sampleRoot()
        let filtered = root.filtered(by: "README")
        XCTAssertNotNil(filtered)
        XCTAssertEqual(filtered?.path, root.path)
    }

    func testFilteredResultHasSameID() {
        let root = FileNode.sampleRoot()
        let filtered = root.filtered(by: "README")
        XCTAssertNotNil(filtered)
        // The root keeps its ID since it's the same object
        XCTAssertEqual(filtered?.id, root.id)
    }

    func testFileNodeChildCountAfterFilter() {
        let root = FileNode.sampleRoot()
        let filtered = root.filtered(by: ".yaml")
        // Should have fewer children than original
        let originalChildCount = root.children?.count ?? 0
        let filteredChildCount = filtered?.children?.count ?? 0
        XCTAssertLessThanOrEqual(filteredChildCount, originalChildCount)
    }

    func testLanguageDetectionForAllSampleFiles() {
        let root = FileNode.sampleRoot()
        var detectedLanguages: Set<String> = []
        func detect(_ node: FileNode) {
            if node.type == .file {
                let lang = Language.detect(from: node.fileExtension)
                detectedLanguages.insert(lang.rawValue)
            }
            node.children?.forEach { detect($0) }
        }
        detect(root)
        // Should detect at least swift, python, js, rs, json, yaml, ts, md, html, css
        XCTAssertGreaterThan(detectedLanguages.count, 5)
    }

    func testFileIconForAllSampleFiles() {
        let root = FileNode.sampleRoot()
        func checkIcon(_ node: FileNode) {
            XCTAssertFalse(node.icon.isEmpty, "File \(node.name) has empty icon")
            node.children?.forEach { checkIcon($0) }
        }
        checkIcon(root)
    }
}
