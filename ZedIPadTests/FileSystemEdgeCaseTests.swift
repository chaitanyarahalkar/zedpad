import XCTest
@testable import ZedIPad

@MainActor
final class FileSystemEdgeCaseTests: XCTestCase {
    var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    func testLargeFileContent() throws {
        let svc = FileSystemService.shared
        let large = String(repeating: "// line\n", count: 10000)
        let url = try svc.createFile(named: "large.swift", in: tempDir, content: large)
        let read = try svc.readFile(at: url)
        XCTAssertEqual(read.count, large.count)
    }

    func testFileNameWithSpaces() throws {
        let svc = FileSystemService.shared
        let url = try svc.createFile(named: "my file.txt", in: tempDir, content: "content")
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        let read = try svc.readFile(at: url)
        XCTAssertEqual(read, "content")
    }

    func testFileNameWithDots() throws {
        let svc = FileSystemService.shared
        let url = try svc.createFile(named: "my.file.with.dots.txt", in: tempDir, content: "dots")
        XCTAssertEqual(url.lastPathComponent, "my.file.with.dots.txt")
        XCTAssertEqual(url.pathExtension, "txt")
    }

    func testHiddenFilesNotInDirectory() throws {
        let svc = FileSystemService.shared
        // Create a hidden file
        let hidden = tempDir.appendingPathComponent(".hidden")
        FileManager.default.createFile(atPath: hidden.path, contents: Data())
        _ = try svc.createFile(named: "visible.txt", in: tempDir)
        let root = try svc.loadDirectory(at: tempDir)
        // .hidden should be excluded by skipsHiddenFiles
        let names = root.children?.map(\.name) ?? []
        XCTAssertFalse(names.contains(".hidden"))
        XCTAssertTrue(names.contains("visible.txt"))
    }

    func testDirectorySortedAlphabetically() throws {
        let svc = FileSystemService.shared
        _ = try svc.createFile(named: "z_last.txt", in: tempDir)
        _ = try svc.createFile(named: "a_first.txt", in: tempDir)
        _ = try svc.createFile(named: "m_middle.txt", in: tempDir)
        let root = try svc.loadDirectory(at: tempDir)
        let names = root.children?.map(\.name) ?? []
        XCTAssertEqual(names, names.sorted(by: { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }))
    }

    func testFileExtensionPreservedOnCopy() throws {
        let svc = FileSystemService.shared
        let src = try svc.createFile(named: "main.swift", in: tempDir, content: "let x = 1")
        let dst = tempDir.appendingPathComponent("main_copy.swift")
        try svc.copy(from: src, to: dst)
        XCTAssertEqual(dst.pathExtension, "swift")
    }

    func testOverwriteWithWrite() throws {
        let svc = FileSystemService.shared
        let url = try svc.createFile(named: "overwrite.txt", in: tempDir, content: "first")
        try svc.writeFile(at: url, content: "second")
        let content = try svc.readFile(at: url)
        XCTAssertEqual(content, "second")
    }

    func testMultipleWritesPreserveLastContent() throws {
        let svc = FileSystemService.shared
        let url = try svc.createFile(named: "multi.txt", in: tempDir)
        for i in 1...5 {
            try svc.writeFile(at: url, content: "version \(i)")
        }
        let final = try svc.readFile(at: url)
        XCTAssertEqual(final, "version 5")
    }

    func testCreateFileNameWithExtensionOnly() throws {
        let svc = FileSystemService.shared
        let url = try svc.createFile(named: ".gitignore", in: tempDir, content: ".build/")
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    func testAttributesReadableFlag() throws {
        let url = try FileSystemService.shared.createFile(named: "r.txt", in: tempDir, content: "read me")
        let meta = try FileSystemService.shared.attributes(at: url)
        XCTAssertTrue(meta.isReadable)
    }

    func testSortByTypeGroupsExtensions() {
        let state = AppState()
        let files: [FileNode] = [
            FileNode(name: "b.rs", type: .file, path: "/b.rs"),
            FileNode(name: "a.py", type: .file, path: "/a.py"),
            FileNode(name: "c.swift", type: .file, path: "/c.swift"),
            FileNode(name: "d.py", type: .file, path: "/d.py"),
        ]
        let parent = FileNode(name: "root", type: .directory, path: "/", children: files)
        state.sortOrder = .type
        state.sortChildren(of: parent)
        let exts = parent.children?.map(\.fileExtension) ?? []
        // py should come before rs and swift
        XCTAssertEqual(exts.prefix(2).sorted(), ["py", "py"])
    }

    func testFileNodeURLMatchesPath() {
        let url = URL(fileURLWithPath: "/tmp/test.swift")
        let node = FileNode(name: "test.swift", type: .file, path: url.path, url: url)
        XCTAssertEqual(node.path, node.fileURL?.path)
    }

    func testFileMetadataLargeSize() {
        let meta = FileMetadata(size: Int64.max, createdDate: nil, modifiedDate: nil, isReadable: true, isWritable: true)
        XCTAssertFalse(meta.formattedSize.isEmpty)
    }
}

// Performance: sorting large trees
@MainActor
final class FileSystemPerformanceTests: XCTestCase {
    func testSortPerformance1000Files() {
        let state = AppState()
        let files = (0..<1000).map { i -> FileNode in
            FileNode(name: "file\(Int.random(in: 0...9999)).swift", type: .file, path: "/file\(i).swift")
        }
        let parent = FileNode(name: "root", type: .directory, path: "/", children: files)
        let start = Date()
        state.sortOrder = .nameAscending
        state.sortChildren(of: parent)
        let elapsed = Date().timeIntervalSince(start)
        XCTAssertLessThan(elapsed, 1.0, "Sorting 1000 files should complete in under 1 second")
        XCTAssertEqual(parent.children?.count, 1000)
    }

    func testLoadDirectoryPerformance() throws {
        let svc = FileSystemService.shared
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        for i in 0..<50 {
            _ = try svc.createFile(named: "f\(i).txt", in: dir)
        }
        let start = Date()
        let root = try svc.loadDirectory(at: dir)
        let elapsed = Date().timeIntervalSince(start)
        XCTAssertLessThan(elapsed, 2.0, "Loading 50 files should complete in under 2 seconds")
        XCTAssertEqual(root.children?.count, 50)
    }
}
