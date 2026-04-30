import XCTest
@testable import ZedIPad

@MainActor
final class FinalIntegrationTests: XCTestCase {

    func testFullApplicationWorkflow() {
        // 1. Create AppState
        let state = AppState()
        XCTAssertEqual(state.theme, .dark)
        XCTAssertNil(state.activeFile)

        // 2. Load sample root
        XCTAssertNotNil(state.rootDirectory)

        // 3. Open files
        let root = FileNode.sampleRoot()
        let sources = root.children?.first { $0.name == "Sources" }
        let mainFile = sources?.children?.first { $0.name == "main.swift" }!
        let kotlinFile = root.children?.first { $0.name == "jvm" }?
            .children?.first { $0.name == "Main.kt" }

        state.openFile(mainFile!)
        XCTAssertEqual(state.openFiles.count, 1)
        if let kt = kotlinFile {
            state.openFile(kt)
            XCTAssertEqual(state.openFiles.count, 2)
        }

        // 4. Highlight active file
        if let active = state.activeFile {
            let lang = Language.detect(from: active.fileExtension)
            let hl = SyntaxHighlighter(theme: state.theme)
            let tokens = hl.highlight(active.content, language: lang)
            XCTAssertFalse(tokens.isEmpty)
        }

        // 5. Find in file
        let find = FindState()
        find.query = "import"
        let ranges = find.search(in: mainFile!.content)
        XCTAssertGreaterThan(ranges.count, 0)

        // 6. Change theme
        state.toggleTheme()
        XCTAssertEqual(state.theme, .light)

        // 7. Close files
        if let active = state.activeFile { state.closeFile(active) }
        XCTAssertLessThan(state.openFiles.count, 2)
    }

    func testFindReplaceFullCycle() {
        let find = FindState()
        var code = "func greet(name: String) -> String { return \"Hello, \\(name)!\" }"
        find.query = "String"
        let ranges = find.search(in: code)
        XCTAssertEqual(ranges.count, 3)
        find.replaceQuery = "Int"
        let count = find.replaceAll(in: &code)
        XCTAssertEqual(count, 3)
        XCTAssertFalse(code.contains("String"))
    }

    func testAllThemesWithAllSampleFiles() {
        let root = FileNode.sampleRoot()
        var files: [FileNode] = []
        func collect(_ node: FileNode) {
            if node.type == .file { files.append(node) }
            node.children?.forEach { collect($0) }
        }
        collect(root)
        for theme in ZedTheme.allCases {
            let hl = SyntaxHighlighter(theme: theme)
            for file in files.prefix(5) {
                let lang = Language.detect(from: file.fileExtension)
                _ = hl.highlight(file.content, language: lang)
            }
        }
    }

    func testSearchAcrossMultipleFiles() {
        let find = FindState()
        let root = FileNode.sampleRoot()
        var totalImports = 0
        func countImports(_ node: FileNode) {
            if node.type == .file {
                find.query = "import"
                let ranges = find.search(in: node.content)
                totalImports += ranges.count
            }
            node.children?.forEach { countImports($0) }
        }
        countImports(root)
        XCTAssertGreaterThan(totalImports, 5, "Multiple files should have import statements")
    }
}
