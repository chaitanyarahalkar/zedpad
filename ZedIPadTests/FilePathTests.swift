import XCTest
@testable import ZedIPad

final class FilePathTests: XCTestCase {

    func testAbsolutePath() {
        let file = FileNode(name: "main.swift", type: .file, path: "/project/src/main.swift")
        XCTAssertTrue(file.path.hasPrefix("/"))
    }

    func testPathDepth() {
        let file = FileNode(name: "deep.swift", type: .file, path: "/a/b/c/d/e/deep.swift")
        let components = file.path.split(separator: "/").filter { !$0.isEmpty }
        XCTAssertEqual(components.count, 6)
    }

    func testPathLastComponent() {
        let file = FileNode(name: "app.py", type: .file, path: "/project/scripts/app.py")
        let last = String(file.path.split(separator: "/").last ?? "")
        XCTAssertEqual(last, "app.py")
        XCTAssertEqual(last, file.name)
    }

    func testPathWithSpaces() {
        let file = FileNode(name: "my file.swift", type: .file, path: "/my project/my file.swift")
        XCTAssertFalse(file.path.isEmpty)
        XCTAssertEqual(file.fileExtension, "swift")
    }

    func testFileWithMultipleDots() {
        let file = FileNode(name: "app.test.swift", type: .file, path: "/app.test.swift")
        XCTAssertEqual(file.fileExtension, "swift")
    }

    func testFileWithLeadingDot() {
        let file = FileNode(name: ".gitignore", type: .file, path: "/.gitignore")
        // .gitignore has extension "gitignore" (NSString.pathExtension behavior)
        _ = file.fileExtension
        _ = Language.detect(from: file.fileExtension)
    }

    func testSampleRootAllPathsAbsolute() {
        let root = FileNode.sampleRoot()
        func checkPaths(_ node: FileNode) {
            XCTAssertTrue(node.path.hasPrefix("/"), "Path should be absolute: \(node.path)")
            node.children?.forEach { checkPaths($0) }
        }
        checkPaths(root)
    }

    func testSampleRootPathsAreUnique() {
        let root = FileNode.sampleRoot()
        var paths: [String] = []
        func collect(_ node: FileNode) {
            paths.append(node.path)
            node.children?.forEach { collect($0) }
        }
        collect(root)
        let uniquePaths = Set(paths)
        XCTAssertEqual(paths.count, uniquePaths.count, "All paths should be unique")
    }
}
