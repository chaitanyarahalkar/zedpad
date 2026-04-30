import XCTest
@testable import ZedIPad

final class FileTreeTests: XCTestCase {

    func testSampleRootHasAllTopLevelFolders() {
        let root = FileNode.sampleRoot()
        let names = root.children?.map(\.name) ?? []
        XCTAssertTrue(names.contains("Sources"))
        XCTAssertTrue(names.contains("Tests"))
        XCTAssertTrue(names.contains("scripts"))
        XCTAssertTrue(names.contains("config"))
        XCTAssertTrue(names.contains("web"))
        XCTAssertTrue(names.contains("README.md"))
        XCTAssertTrue(names.contains("Package.swift"))
        XCTAssertTrue(names.contains(".gitignore"))
    }

    func testWebFolderContainsHTMLAndCSS() {
        let root = FileNode.sampleRoot()
        let web = root.children?.first { $0.name == "web" }
        XCTAssertNotNil(web, "web folder should exist")
        let webNames = web?.children?.map(\.name) ?? []
        XCTAssertTrue(webNames.contains("index.html"))
        XCTAssertTrue(webNames.contains("styles.css"))
    }

    func testHTMLFileLanguageDetection() {
        let root = FileNode.sampleRoot()
        let web = root.children?.first { $0.name == "web" }
        let html = web?.children?.first { $0.name == "index.html" }
        XCTAssertNotNil(html)
        XCTAssertEqual(Language.detect(from: html!.fileExtension), .html)
    }

    func testCSSFileLanguageDetection() {
        let root = FileNode.sampleRoot()
        let web = root.children?.first { $0.name == "web" }
        let css = web?.children?.first { $0.name == "styles.css" }
        XCTAssertNotNil(css)
        XCTAssertEqual(Language.detect(from: css!.fileExtension), .css)
    }

    func testScriptsFolderContainsPythonJSRust() {
        let root = FileNode.sampleRoot()
        let scripts = root.children?.first { $0.name == "scripts" }
        XCTAssertNotNil(scripts)
        let names = scripts?.children?.map(\.name) ?? []
        XCTAssertTrue(names.contains("build.py"))
        XCTAssertTrue(names.contains("server.js"))
        XCTAssertTrue(names.contains("parser.rs"))
    }

    func testConfigFolderContainsJSONAndYAML() {
        let root = FileNode.sampleRoot()
        let config = root.children?.first { $0.name == "config" }
        XCTAssertNotNil(config)
        let names = config?.children?.map(\.name) ?? []
        XCTAssertTrue(names.contains("settings.json"))
        XCTAssertTrue(names.contains("deploy.yaml"))
    }

    func testAllFilesHaveContent() {
        let root = FileNode.sampleRoot()
        func checkNode(_ node: FileNode) {
            if node.type == .file {
                XCTAssertFalse(node.content.isEmpty, "File \(node.name) should have content")
            }
            node.children?.forEach { checkNode($0) }
        }
        checkNode(root)
    }

    func testAllFilesHaveValidPaths() {
        let root = FileNode.sampleRoot()
        func checkNode(_ node: FileNode) {
            XCTAssertFalse(node.path.isEmpty, "Node \(node.name) should have a path")
            XCTAssertTrue(node.path.hasPrefix("/"), "Path should be absolute: \(node.path)")
            node.children?.forEach { checkNode($0) }
        }
        checkNode(root)
    }

    func testFileNodeUniqueIDs() {
        let root = FileNode.sampleRoot()
        var ids = Set<UUID>()
        func collectIDs(_ node: FileNode) {
            XCTAssertFalse(ids.contains(node.id), "Duplicate ID found for \(node.name)")
            ids.insert(node.id)
            node.children?.forEach { collectIDs($0) }
        }
        collectIDs(root)
        XCTAssertGreaterThan(ids.count, 10)
    }

    func testFileNodeTypeConsistency() {
        let root = FileNode.sampleRoot()
        func check(_ node: FileNode) {
            if node.children != nil {
                XCTAssertEqual(node.type, .directory,
                               "\(node.name) has children but type is not .directory")
            }
            node.children?.forEach { check($0) }
        }
        check(root)
    }
}
