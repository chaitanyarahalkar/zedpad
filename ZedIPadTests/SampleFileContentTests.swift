import XCTest
@testable import ZedIPad

final class SampleFileContentTests: XCTestCase {

    private let root = FileNode.sampleRoot()

    private func findFile(named name: String) -> FileNode? {
        func search(_ node: FileNode) -> FileNode? {
            if node.name == name && node.type == .file { return node }
            return node.children?.compactMap { search($0) }.first
        }
        return search(root)
    }

    func testMainSwiftContent() {
        let file = findFile(named: "main.swift")
        XCTAssertNotNil(file)
        XCTAssertTrue(file!.content.contains("import Foundation"))
        XCTAssertTrue(file!.content.contains("struct App"))
    }

    func testBuildPyContent() {
        let file = findFile(named: "build.py")
        XCTAssertNotNil(file)
        XCTAssertTrue(file!.content.contains("import os"))
        XCTAssertTrue(file!.content.contains("def build"))
    }

    func testServerJsContent() {
        let file = findFile(named: "server.js")
        XCTAssertNotNil(file)
        XCTAssertTrue(file!.content.contains("http.createServer"))
        XCTAssertTrue(file!.content.contains("PORT"))
    }

    func testParserRsContent() {
        let file = findFile(named: "parser.rs")
        XCTAssertNotNil(file)
        XCTAssertTrue(file!.content.contains("enum Token"))
        XCTAssertTrue(file!.content.contains("fn main"))
    }

    func testSettingsJsonContent() {
        let file = findFile(named: "settings.json")
        XCTAssertNotNil(file)
        XCTAssertTrue(file!.content.contains("\"app\""))
        XCTAssertTrue(file!.content.contains("\"server\""))
    }

    func testDeployYamlContent() {
        let file = findFile(named: "deploy.yaml")
        XCTAssertNotNil(file)
        XCTAssertTrue(file!.content.contains("kind: Deployment"))
        XCTAssertTrue(file!.content.contains("replicas:"))
    }

    func testIndexHtmlContent() {
        let file = findFile(named: "index.html")
        XCTAssertNotNil(file)
        XCTAssertTrue(file!.content.contains("<html"))
        XCTAssertTrue(file!.content.contains("<body"))
    }

    func testStylesCssContent() {
        let file = findFile(named: "styles.css")
        XCTAssertNotNil(file)
        XCTAssertTrue(file!.content.contains("body {"))
        XCTAssertTrue(file!.content.contains("color:"))
    }

    func testApiTsContent() {
        let file = findFile(named: "api.ts")
        XCTAssertNotNil(file)
        XCTAssertTrue(file!.content.contains("interface User"))
        XCTAssertTrue(file!.content.contains("class ApiClient"))
    }

    func testMainKtContent() {
        let file = findFile(named: "Main.kt")
        XCTAssertNotNil(file)
        XCTAssertTrue(file!.content.contains("data class"))
        XCTAssertTrue(file!.content.contains("suspend fun"))
    }
}
