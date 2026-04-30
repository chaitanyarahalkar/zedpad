import XCTest
@testable import ZedIPad

@MainActor
final class AppStateScenario2Tests: XCTestCase {

    func testOpenAllSampleFilesAndHighlight() {
        let state = AppState()
        let root = FileNode.sampleRoot()
        var files: [FileNode] = []
        func collectFiles(_ node: FileNode) {
            if node.type == .file { files.append(node) }
            node.children?.forEach { collectFiles($0) }
        }
        collectFiles(root)
        for file in files { state.openFile(file) }
        XCTAssertEqual(state.openFiles.count, files.count)
        for file in files {
            let hl = SyntaxHighlighter(theme: state.theme)
            let lang = Language.detect(from: file.fileExtension)
            _ = hl.highlight(file.content, language: lang)
        }
    }

    func testFindAcrossAllSampleFiles() {
        let root = FileNode.sampleRoot()
        let find = FindState()
        find.query = "function"
        find.isCaseSensitive = false
        var foundFiles = 0
        func searchFile(_ node: FileNode) {
            if node.type == .file {
                let ranges = find.search(in: node.content)
                if ranges.count > 0 { foundFiles += 1 }
            }
            node.children?.forEach { searchFile($0) }
        }
        searchFile(root)
        XCTAssertGreaterThan(foundFiles, 0, "Should find 'function' in at least one file")
    }

    func testThemeChangePreservesOpenFiles() {
        let state = AppState()
        let files = (0..<3).map { FileNode(name: "p\($0).swift", type: .file, path: "/p\($0).swift") }
        files.forEach { state.openFile($0) }
        let fileIds = state.openFiles.map(\.id)
        for theme in ZedTheme.allCases {
            state.theme = theme
            XCTAssertEqual(state.openFiles.map(\.id), fileIds)
        }
    }

    func testFontChangePreservesSearch() {
        let state = AppState()
        let find = FindState()
        find.query = "hello"
        let text = "hello world hello"
        let ranges1 = find.search(in: text)
        state.increaseFontSize()
        let ranges2 = find.search(in: text)
        XCTAssertEqual(ranges1.count, ranges2.count)
    }

    func testGoToLineDoesNotAffectOpenFiles() {
        let state = AppState()
        let gts = GoToLineState()
        let files = (0..<3).map { FileNode(name: "q\($0).swift", type: .file, path: "/q\($0).swift") }
        files.forEach { state.openFile($0) }
        gts.show()
        gts.lineNumber = "42"
        gts.hide()
        XCTAssertEqual(state.openFiles.count, 3)
    }

    func testSplitViewDoesNotCloseOtherFiles() {
        let state = AppState()
        let split = SplitEditorState()
        let files = (0..<5).map { FileNode(name: "z\($0).swift", type: .file, path: "/z\($0).swift") }
        files.forEach { state.openFile($0) }
        split.openSplit(files[0])
        XCTAssertEqual(state.openFiles.count, 5)
        split.closeSplit()
        XCTAssertEqual(state.openFiles.count, 5)
    }
}
