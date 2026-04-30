import XCTest
@testable import ZedIPad

final class SampleFileHighlightTests: XCTestCase {

    private let hl = SyntaxHighlighter(theme: .dark)

    private func findFile(named name: String) -> FileNode? {
        let root = FileNode.sampleRoot()
        func search(_ node: FileNode) -> FileNode? {
            if node.name == name { return node }
            return node.children?.compactMap { search($0) }.first
        }
        return search(root)
    }

    func testHighlightMainSwift() {
        guard let file = findFile(named: "main.swift") else { XCTFail(); return }
        let tokens = hl.highlight(file.content, language: .swift)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testHighlightBuildPy() {
        guard let file = findFile(named: "build.py") else { XCTFail(); return }
        let tokens = hl.highlight(file.content, language: .python)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testHighlightServerJs() {
        guard let file = findFile(named: "server.js") else { XCTFail(); return }
        let tokens = hl.highlight(file.content, language: .javascript)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testHighlightParserRs() {
        guard let file = findFile(named: "parser.rs") else { XCTFail(); return }
        let tokens = hl.highlight(file.content, language: .rust)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testHighlightSettingsJson() {
        guard let file = findFile(named: "settings.json") else { XCTFail(); return }
        let tokens = hl.highlight(file.content, language: .json)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testHighlightDeployYaml() {
        guard let file = findFile(named: "deploy.yaml") else { XCTFail(); return }
        let tokens = hl.highlight(file.content, language: .yaml)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testHighlightIndexHtml() {
        guard let file = findFile(named: "index.html") else { XCTFail(); return }
        let tokens = hl.highlight(file.content, language: .html)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testHighlightStylesCss() {
        guard let file = findFile(named: "styles.css") else { XCTFail(); return }
        let tokens = hl.highlight(file.content, language: .css)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testHighlightApiTs() {
        guard let file = findFile(named: "api.ts") else { XCTFail(); return }
        let tokens = hl.highlight(file.content, language: .typescript)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testHighlightMainKt() {
        guard let file = findFile(named: "Main.kt") else { XCTFail(); return }
        let tokens = hl.highlight(file.content, language: .kotlin)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testHighlightAnalysisScala() {
        guard let file = findFile(named: "Analysis.scala") else { XCTFail(); return }
        let tokens = hl.highlight(file.content, language: .scala)
        XCTAssertFalse(tokens.isEmpty)
    }
}
