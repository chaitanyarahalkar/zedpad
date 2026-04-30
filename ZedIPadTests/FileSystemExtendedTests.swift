import XCTest
@testable import ZedIPad

@MainActor
final class FileSystemExtendedTests: XCTestCase {
    var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    // MARK: - Error handling

    func testReadNonExistentFileThrows() {
        let url = tempDir.appendingPathComponent("nonexistent.txt")
        XCTAssertThrowsError(try FileSystemService.shared.readFile(at: url))
    }

    func testDeleteNonExistentThrows() {
        let url = tempDir.appendingPathComponent("ghost.txt")
        XCTAssertThrowsError(try FileSystemService.shared.delete(at: url))
    }

    func testRenameToExistingNameOverwrites() throws {
        let svc = FileSystemService.shared
        let a = try svc.createFile(named: "a.txt", in: tempDir, content: "A")
        _ = try svc.createFile(named: "b.txt", in: tempDir, content: "B")
        // moveItem will throw if destination exists and is different — verify behavior
        XCTAssertThrowsError(try svc.rename(at: a, to: "b.txt"))
    }

    func testCreateFileWithUnicodeContent() throws {
        let svc = FileSystemService.shared
        let content = "// こんにちは世界 🌏\nlet x = 42"
        let url = try svc.createFile(named: "unicode.swift", in: tempDir, content: content)
        let read = try svc.readFile(at: url)
        XCTAssertEqual(read, content)
    }

    func testCreateFileWithEmptyContent() throws {
        let svc = FileSystemService.shared
        let url = try svc.createFile(named: "empty.txt", in: tempDir)
        let read = try svc.readFile(at: url)
        XCTAssertEqual(read, "")
    }

    func testLoadDirectoryEmpty() throws {
        let svc = FileSystemService.shared
        let sub = try svc.createDirectory(named: "empty_dir", in: tempDir)
        let node = try svc.loadDirectory(at: sub)
        XCTAssertEqual(node.children?.count ?? 0, 0)
    }

    func testLoadDirectoryOnlyFiles() throws {
        let svc = FileSystemService.shared
        _ = try svc.createFile(named: "f1.txt", in: tempDir)
        _ = try svc.createFile(named: "f2.txt", in: tempDir)
        let root = try svc.loadDirectory(at: tempDir)
        XCTAssertEqual(root.children?.count, 2)
        XCTAssertTrue(root.children?.allSatisfy { $0.type == .file } ?? false)
    }

    func testLoadDirectoryOnlyDirs() throws {
        let svc = FileSystemService.shared
        _ = try svc.createDirectory(named: "d1", in: tempDir)
        _ = try svc.createDirectory(named: "d2", in: tempDir)
        let root = try svc.loadDirectory(at: tempDir)
        XCTAssertEqual(root.children?.count, 2)
        XCTAssertTrue(root.children?.allSatisfy { $0.type == .directory } ?? false)
    }

    func testAttributesSizeAccurate() throws {
        let content = "hello world"  // 11 bytes
        let url = try FileSystemService.shared.createFile(named: "sized.txt", in: tempDir, content: content)
        let meta = try FileSystemService.shared.attributes(at: url)
        XCTAssertEqual(meta.size, Int64(content.utf8.count))
    }

    func testFileURLSetOnLoading() throws {
        _ = try FileSystemService.shared.createFile(named: "a.swift", in: tempDir)
        let root = try FileSystemService.shared.loadDirectory(at: tempDir)
        let child = root.children?.first
        XCTAssertNotNil(child?.fileURL)
    }
}

@MainActor
final class AppStateSortTests: XCTestCase {
    func testSortBySize() {
        let state = AppState()
        let small = FileNode(name: "small.txt", type: .file, path: "/small.txt")
        small.metadata = FileMetadata(size: 100, createdDate: nil, modifiedDate: nil, isReadable: true, isWritable: true)
        let large = FileNode(name: "large.txt", type: .file, path: "/large.txt")
        large.metadata = FileMetadata(size: 9999, createdDate: nil, modifiedDate: nil, isReadable: true, isWritable: true)
        let parent = FileNode(name: "root", type: .directory, path: "/", children: [small, large])
        state.sortOrder = .size
        state.sortChildren(of: parent)
        XCTAssertEqual(parent.children?.first?.name, "large.txt")
    }

    func testSortByDateModified() {
        let state = AppState()
        let old = FileNode(name: "old.txt", type: .file, path: "/old.txt")
        old.metadata = FileMetadata(size: 0, createdDate: nil, modifiedDate: Date(timeIntervalSince1970: 0), isReadable: true, isWritable: true)
        let new = FileNode(name: "new.txt", type: .file, path: "/new.txt")
        new.metadata = FileMetadata(size: 0, createdDate: nil, modifiedDate: Date(), isReadable: true, isWritable: true)
        let parent = FileNode(name: "root", type: .directory, path: "/", children: [old, new])
        state.sortOrder = .dateModified
        state.sortChildren(of: parent)
        XCTAssertEqual(parent.children?.first?.name, "new.txt")
    }

    func testSortStable() {
        let state = AppState()
        let files = (1...10).map { i in
            FileNode(name: "file\(i).txt", type: .file, path: "/file\(i).txt")
        }
        let parent = FileNode(name: "root", type: .directory, path: "/", children: files)
        state.sortOrder = .nameAscending
        state.sortChildren(of: parent)
        let names = parent.children?.map(\.name) ?? []
        XCTAssertEqual(names, names.sorted())
    }

    func testSortEmptyChildren() {
        let state = AppState()
        let parent = FileNode(name: "root", type: .directory, path: "/", children: [])
        // Should not crash
        state.sortOrder = .nameAscending
        state.sortChildren(of: parent)
        XCTAssertEqual(parent.children?.count, 0)
    }

    func testSortNilChildren() {
        let state = AppState()
        let parent = FileNode(name: "root", type: .directory, path: "/")
        state.sortChildren(of: parent)
        XCTAssertNil(parent.children)
    }
}

@MainActor
final class iCloudServiceTests: XCTestCase {
    func testIsAvailableDoesNotCrash() {
        // Should not crash regardless of iCloud availability
        let available = iCloudService.shared.isAvailable
        XCTAssertTrue(available == true || available == false)
    }

    func testDocumentsURLNilWhenUnavailable() {
        // In simulator, iCloud is typically not available
        if !iCloudService.shared.isAvailable {
            XCTAssertNil(iCloudService.shared.documentsURL)
        }
    }

    func testICloudRootNilWhenUnavailable() {
        if !iCloudService.shared.isAvailable {
            XCTAssertNil(iCloudService.shared.iCloudRoot())
        }
    }

    func testIsDownloadedLocalFile() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("local.txt")
        FileManager.default.createFile(atPath: url.path, contents: Data())
        // Local files are not ubiquitous
        XCTAssertFalse(iCloudService.shared.isInCloud(url: url))
        try? FileManager.default.removeItem(at: url)
    }
}

@MainActor
final class FileNodeURLTests: XCTestCase {
    func testFileNodeURLInitiallyNil() {
        let node = FileNode(name: "test.swift", type: .file, path: "/test.swift")
        XCTAssertNil(node.url)
    }

    func testFileNodeURLSetViaInit() {
        let url = URL(fileURLWithPath: "/tmp/test.swift")
        let node = FileNode(name: "test.swift", type: .file, path: "/tmp/test.swift", url: url)
        XCTAssertEqual(node.url, url)
    }

    func testFileNodeMetadataNilByDefault() {
        let node = FileNode(name: "test.txt", type: .file, path: "/test.txt")
        XCTAssertNil(node.metadata)
    }

    func testFileNodeMetadataAssignable() {
        let node = FileNode(name: "test.txt", type: .file, path: "/test.txt")
        node.metadata = FileMetadata(size: 512, createdDate: nil, modifiedDate: nil, isReadable: true, isWritable: true)
        XCTAssertEqual(node.metadata?.size, 512)
    }

    func testIsDirtyInitiallyFalse() {
        let node = FileNode(name: "f.swift", type: .file, path: "/f.swift")
        XCTAssertFalse(node.isDirty)
    }
}
