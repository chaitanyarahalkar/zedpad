import XCTest
@testable import ZedIPad

@MainActor
final class FileSystemFinalTests: XCTestCase {
    var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    // Multiple sequential creates
    func testSequentialCreates() throws {
        let svc = FileSystemService.shared
        var urls: [URL] = []
        for i in 0..<10 {
            let url = try svc.createFile(named: "seq\(i).txt", in: tempDir, content: "line \(i)")
            urls.append(url)
        }
        XCTAssertEqual(urls.count, 10)
        let root = try svc.loadDirectory(at: tempDir)
        XCTAssertEqual(root.children?.count, 10)
    }

    // Delete all files one by one
    func testDeleteAll() throws {
        let svc = FileSystemService.shared
        for i in 0..<5 {
            _ = try svc.createFile(named: "del\(i).txt", in: tempDir)
        }
        let root = try svc.loadDirectory(at: tempDir)
        for child in root.children ?? [] {
            try svc.delete(at: URL(fileURLWithPath: child.path))
        }
        let empty = try svc.loadDirectory(at: tempDir)
        XCTAssertEqual(empty.children?.count ?? 0, 0)
    }

    // Rename chain: a → b → c
    func testRenameChain() throws {
        let svc = FileSystemService.shared
        let a = try svc.createFile(named: "a.txt", in: tempDir, content: "data")
        let b = try svc.rename(at: a, to: "b.txt")
        let c = try svc.rename(at: b, to: "c.txt")
        XCTAssertTrue(FileManager.default.fileExists(atPath: c.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: a.path))
        let content = try svc.readFile(at: c)
        XCTAssertEqual(content, "data")
    }

    // Copy then modify original, copy should be unchanged
    func testCopyIndependence() throws {
        let svc = FileSystemService.shared
        let src = try svc.createFile(named: "ind_src.txt", in: tempDir, content: "original")
        let dst = tempDir.appendingPathComponent("ind_dst.txt")
        try svc.copy(from: src, to: dst)
        try svc.writeFile(at: src, content: "modified")
        let dstContent = try svc.readFile(at: dst)
        XCTAssertEqual(dstContent, "original")
    }

    // FileNode with URL has correct extension
    func testFileNodeExtensionFromURL() {
        let url = URL(fileURLWithPath: "/tmp/main.swift")
        let node = FileNode(name: url.lastPathComponent, type: .file, path: url.path, url: url)
        XCTAssertEqual(node.fileExtension, "swift")
    }

    // URL property delegates to fileURL
    func testFileNodeURLDelegatesToFileURL() {
        let url = URL(fileURLWithPath: "/tmp/test.py")
        let node = FileNode(name: "test.py", type: .file, path: url.path, url: url)
        XCTAssertEqual(node.url, node.fileURL)
    }

    // FileMetadata created date nil when not provided
    func testFileMetadataCreatedDateNil() {
        let meta = FileMetadata(size: 0, createdDate: nil, modifiedDate: nil, isReadable: true, isWritable: true)
        XCTAssertEqual(meta.formattedCreatedDate, "Unknown")
    }

    // FSError descriptions
    func testFSErrorCreateFailedDescription() {
        let error = FileSystemService.FSError.createFailed("/tmp/x")
        XCTAssertTrue(error.errorDescription?.contains("/tmp/x") ?? false)
    }

    func testFSErrorNotFoundDescription() {
        let error = FileSystemService.FSError.notFound("/missing")
        XCTAssertTrue(error.errorDescription?.contains("/missing") ?? false)
    }

    // Attributes: modifiedDate updates after write
    func testModifiedDateUpdatesAfterWrite() throws {
        let svc = FileSystemService.shared
        let url = try svc.createFile(named: "dates.txt", in: tempDir, content: "v1")
        let before = try svc.attributes(at: url)
        Thread.sleep(forTimeInterval: 0.05)
        try svc.writeFile(at: url, content: "v2 with more content to change modified date")
        let after = try svc.attributes(at: url)
        // Modified date should be >= before modified date
        if let b = before.modifiedDate, let a = after.modifiedDate {
            XCTAssertGreaterThanOrEqual(a, b)
        }
    }

    // Documents URL exists
    func testDocumentsURLExists() {
        let url = FileSystemService.shared.documentsURL
        var isDir: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir))
        XCTAssertTrue(isDir.boolValue)
    }

    // Sort single file no crash
    func testSortSingleFile() {
        let state = AppState()
        let file = FileNode(name: "only.swift", type: .file, path: "/only.swift")
        let parent = FileNode(name: "root", type: .directory, path: "/", children: [file])
        state.sortChildren(of: parent)
        XCTAssertEqual(parent.children?.count, 1)
    }

    // File watcher multiple start/stop cycles
    func testFileWatcherMultipleCycles() throws {
        let url = tempDir.appendingPathComponent("cycle.txt")
        FileManager.default.createFile(atPath: url.path, contents: Data())
        let watcher = FileWatcher(url: url)
        for _ in 0..<5 {
            watcher.start()
            watcher.stop()
        }
        XCTAssertTrue(true) // no crash = pass
    }

    // Copy to subdirectory
    func testCopyToSubdirectory() throws {
        let svc = FileSystemService.shared
        let src = try svc.createFile(named: "tosub.txt", in: tempDir, content: "subdir copy")
        let sub = try svc.createDirectory(named: "subdir", in: tempDir)
        let dst = sub.appendingPathComponent("tosub.txt")
        try svc.copy(from: src, to: dst)
        XCTAssertTrue(FileManager.default.fileExists(atPath: dst.path))
        XCTAssertEqual(try svc.readFile(at: dst), "subdir copy")
    }

    // AppState sort order persists across sortChildren calls
    func testAppStateSortOrderPersists() {
        let state = AppState()
        state.sortOrder = .nameDescending
        XCTAssertEqual(state.sortOrder, .nameDescending)
        let parent = FileNode(name: "root", type: .directory, path: "/", children: [
            FileNode(name: "a.txt", type: .file, path: "/a.txt"),
            FileNode(name: "b.txt", type: .file, path: "/b.txt"),
        ])
        state.sortChildren(of: parent)
        XCTAssertEqual(parent.children?.first?.name, "b.txt")
        XCTAssertEqual(state.sortOrder, .nameDescending)
    }
}
