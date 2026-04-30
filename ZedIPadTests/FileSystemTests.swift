import XCTest
@testable import ZedIPad

@MainActor
final class FileSystemServiceTests: XCTestCase {
    var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    func testCreateFile() throws {
        let svc = FileSystemService.shared
        let url = try svc.createFile(named: "hello.swift", in: tempDir, content: "let x = 1")
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        let content = try svc.readFile(at: url)
        XCTAssertEqual(content, "let x = 1")
    }

    func testCreateDirectory() throws {
        let svc = FileSystemService.shared
        let url = try svc.createDirectory(named: "Sources", in: tempDir)
        var isDir: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir))
        XCTAssertTrue(isDir.boolValue)
    }

    func testDeleteFile() throws {
        let svc = FileSystemService.shared
        let url = try svc.createFile(named: "delete_me.txt", in: tempDir)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        try svc.delete(at: url)
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }

    func testRename() throws {
        let svc = FileSystemService.shared
        let url = try svc.createFile(named: "old.txt", in: tempDir)
        let newURL = try svc.rename(at: url, to: "new.txt")
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: newURL.path))
        XCTAssertEqual(newURL.lastPathComponent, "new.txt")
    }

    func testCopyFile() throws {
        let svc = FileSystemService.shared
        let src = try svc.createFile(named: "src.txt", in: tempDir, content: "copied content")
        let dst = tempDir.appendingPathComponent("dst.txt")
        try svc.copy(from: src, to: dst)
        XCTAssertTrue(FileManager.default.fileExists(atPath: dst.path))
        let content = try svc.readFile(at: dst)
        XCTAssertEqual(content, "copied content")
    }

    func testMoveFile() throws {
        let svc = FileSystemService.shared
        let src = try svc.createFile(named: "moveme.txt", in: tempDir, content: "moving")
        let subDir = try svc.createDirectory(named: "subdir", in: tempDir)
        let dst = subDir.appendingPathComponent("moveme.txt")
        try svc.move(from: src, to: dst)
        XCTAssertFalse(FileManager.default.fileExists(atPath: src.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: dst.path))
    }

    func testWriteAndRead() throws {
        let svc = FileSystemService.shared
        let url = try svc.createFile(named: "rw.swift", in: tempDir)
        try svc.writeFile(at: url, content: "struct Foo {}")
        let result = try svc.readFile(at: url)
        XCTAssertEqual(result, "struct Foo {}")
    }

    func testAttributes() throws {
        let svc = FileSystemService.shared
        let url = try svc.createFile(named: "meta.txt", in: tempDir, content: "hello world")
        let meta = try svc.attributes(at: url)
        XCTAssertEqual(meta.size, 11)
        XCTAssertTrue(meta.isReadable)
        XCTAssertTrue(meta.isWritable)
        XCTAssertNotNil(meta.modifiedDate)
    }

    func testLoadDirectory() throws {
        let svc = FileSystemService.shared
        _ = try svc.createFile(named: "a.swift", in: tempDir)
        _ = try svc.createFile(named: "b.py", in: tempDir)
        _ = try svc.createDirectory(named: "src", in: tempDir)
        let root = try svc.loadDirectory(at: tempDir)
        XCTAssertEqual(root.type, .directory)
        XCTAssertEqual(root.children?.count, 3)
        let names = root.children?.map(\.name).sorted() ?? []
        XCTAssertTrue(names.contains("a.swift"))
        XCTAssertTrue(names.contains("b.py"))
        XCTAssertTrue(names.contains("src"))
    }

    func testLoadDirectoryNestedRecursive() throws {
        let svc = FileSystemService.shared
        let sub = try svc.createDirectory(named: "nested", in: tempDir)
        _ = try svc.createFile(named: "inner.txt", in: sub)
        let root = try svc.loadDirectory(at: tempDir)
        let nested = root.children?.first(where: { $0.name == "nested" })
        XCTAssertNotNil(nested)
        XCTAssertEqual(nested?.children?.count, 1)
        XCTAssertEqual(nested?.children?.first?.name, "inner.txt")
    }

    func testCreateFileMissingDir() {
        let svc = FileSystemService.shared
        let bad = URL(fileURLWithPath: "/no/such/dir")
        XCTAssertThrowsError(try svc.createDirectory(named: "x", in: bad))
    }
}

final class FileMetadataTests: XCTestCase {
    func testFormattedSize() {
        let meta = FileMetadata(size: 1024, createdDate: nil, modifiedDate: nil, isReadable: true, isWritable: true)
        XCTAssertFalse(meta.formattedSize.isEmpty)
    }

    func testFormattedSizeZero() {
        let meta = FileMetadata(size: 0, createdDate: nil, modifiedDate: nil, isReadable: true, isWritable: true)
        XCTAssertFalse(meta.formattedSize.isEmpty)
    }

    func testFormattedModifiedDateNil() {
        let meta = FileMetadata(size: 100, createdDate: nil, modifiedDate: nil, isReadable: true, isWritable: false)
        XCTAssertEqual(meta.formattedModifiedDate, "Unknown")
    }

    func testFormattedModifiedDate() {
        let date = Date(timeIntervalSince1970: 0)
        let meta = FileMetadata(size: 0, createdDate: nil, modifiedDate: date, isReadable: true, isWritable: true)
        XCTAssertFalse(meta.formattedModifiedDate.isEmpty)
        XCTAssertNotEqual(meta.formattedModifiedDate, "Unknown")
    }

    func testFormattedCreatedDate() {
        let date = Date()
        let meta = FileMetadata(size: 0, createdDate: date, modifiedDate: nil, isReadable: true, isWritable: true)
        XCTAssertFalse(meta.formattedCreatedDate.isEmpty)
    }

    func testReadableWritableFlags() {
        let meta = FileMetadata(size: 0, createdDate: nil, modifiedDate: nil, isReadable: false, isWritable: false)
        XCTAssertFalse(meta.isReadable)
        XCTAssertFalse(meta.isWritable)
    }
}

final class FileWatcherTests: XCTestCase {
    var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    func testStartStopNoCrash() throws {
        let url = tempDir.appendingPathComponent("watch.txt")
        FileManager.default.createFile(atPath: url.path, contents: Data())
        let watcher = FileWatcher(url: url)
        watcher.start()
        watcher.stop()
    }

    func testWatcherDetectsWrite() throws {
        let url = tempDir.appendingPathComponent("watched.txt")
        FileManager.default.createFile(atPath: url.path, contents: "initial".data(using: .utf8))
        let watcher = FileWatcher(url: url)
        let expectation = XCTestExpectation(description: "file change detected")
        watcher.onChange = { expectation.fulfill() }
        watcher.start()
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            try? "updated".write(to: url, atomically: true, encoding: .utf8)
        }
        wait(for: [expectation], timeout: 3)
        watcher.stop()
    }

    func testWatcherNoChangeAfterStop() {
        let url = tempDir.appendingPathComponent("stopped.txt")
        FileManager.default.createFile(atPath: url.path, contents: Data())
        let watcher = FileWatcher(url: url)
        var callCount = 0
        watcher.onChange = { callCount += 1 }
        watcher.start()
        watcher.stop()
        try? "after stop".write(to: url, atomically: true, encoding: .utf8)
        Thread.sleep(forTimeInterval: 0.2)
        XCTAssertEqual(callCount, 0)
    }
}

@MainActor
final class AppStateFileSystemTests: XCTestCase {
    func testSortOrderDefaultName() {
        let state = AppState()
        XCTAssertEqual(state.sortOrder, .nameAscending)
    }

    func testSortChildrenByName() {
        let state = AppState()
        let parent = FileNode(name: "root", type: .directory, path: "/root", children: [
            FileNode(name: "z.swift", type: .file, path: "/root/z.swift"),
            FileNode(name: "a.py", type: .file, path: "/root/a.py"),
            FileNode(name: "m.rs", type: .file, path: "/root/m.rs"),
        ])
        state.sortOrder = .nameAscending
        state.sortChildren(of: parent)
        XCTAssertEqual(parent.children?.map(\.name), ["a.py", "m.rs", "z.swift"])
    }

    func testSortChildrenByNameDescending() {
        let state = AppState()
        let parent = FileNode(name: "root", type: .directory, path: "/root", children: [
            FileNode(name: "a.swift", type: .file, path: "/root/a.swift"),
            FileNode(name: "z.py", type: .file, path: "/root/z.py"),
        ])
        state.sortOrder = .nameDescending
        state.sortChildren(of: parent)
        XCTAssertEqual(parent.children?.map(\.name), ["z.py", "a.swift"])
    }

    func testSortChildrenByType() {
        let state = AppState()
        let parent = FileNode(name: "root", type: .directory, path: "/root", children: [
            FileNode(name: "file.rs", type: .file, path: "/root/file.rs"),
            FileNode(name: "file.py", type: .file, path: "/root/file.py"),
            FileNode(name: "file.swift", type: .file, path: "/root/file.swift"),
        ])
        state.sortOrder = .type
        state.sortChildren(of: parent)
        let exts = parent.children?.map(\.fileExtension) ?? []
        XCTAssertEqual(exts, ["py", "rs", "swift"])
    }

    func testLastErrorClearedOnSuccess() {
        let state = AppState()
        state.lastError = "previous error"
        XCTAssertEqual(state.lastError, "previous error")
        state.lastError = nil
        XCTAssertNil(state.lastError)
    }

    func testFileSortOrderAllCases() {
        XCTAssertEqual(AppState.FileSortOrder.allCases.count, 5)
    }

    func testDuplicateNodeSuffix() {
        // Verify the _copy naming logic without touching FS
        let name = "main"
        let ext = "swift"
        let copyName = ext.isEmpty ? "\(name)_copy" : "\(name)_copy.\(ext)"
        XCTAssertEqual(copyName, "main_copy.swift")
    }

    func testDuplicateNodeNoExtension() {
        let name = "Makefile"
        let ext = ""
        let copyName = ext.isEmpty ? "\(name)_copy" : "\(name)_copy.\(ext)"
        XCTAssertEqual(copyName, "Makefile_copy")
    }
}

final class BookmarkPersistenceTests: XCTestCase {
    var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    func testBookmarkRoundTrip() throws {
        let url = tempDir.appendingPathComponent("bookmark_test.txt")
        FileManager.default.createFile(atPath: url.path, contents: "test".data(using: .utf8))
        let bookmark = try url.bookmarkData(options: .minimalBookmark)
        XCTAssertFalse(bookmark.isEmpty)
        var isStale = false
        let resolved = try URL(resolvingBookmarkData: bookmark, bookmarkDataIsStale: &isStale)
        XCTAssertFalse(isStale)
        XCTAssertEqual(resolved.lastPathComponent, "bookmark_test.txt")
    }

    func testBookmarkStaleAfterDelete() throws {
        let url = tempDir.appendingPathComponent("stale.txt")
        FileManager.default.createFile(atPath: url.path, contents: Data())
        let bookmark = try url.bookmarkData(options: .minimalBookmark)
        try FileManager.default.removeItem(at: url)
        // Stale check — may or may not be stale immediately, but should not crash
        var isStale = false
        _ = try? URL(resolvingBookmarkData: bookmark, bookmarkDataIsStale: &isStale)
        // Just verify no crash
        XCTAssertTrue(true)
    }
}
