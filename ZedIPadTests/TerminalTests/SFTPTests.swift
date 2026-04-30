import XCTest
@testable import ZedIPad

final class SFTPTests: XCTestCase {
    func testMockListDirectory() async throws {
        let sftp = MockSFTPSession()
        let entries = try await sftp.listDirectory("/home/user")
        XCTAssertFalse(entries.isEmpty)
    }

    func testMockListRoot() async throws {
        let sftp = MockSFTPSession()
        let entries = try await sftp.listDirectory("/")
        XCTAssertFalse(entries.isEmpty)
    }

    func testMockReadFile() async throws {
        let sftp = MockSFTPSession()
        let data = try await sftp.readFile("/home/user/projects/README.md")
        let text = String(data: data, encoding: .utf8)
        XCTAssertNotNil(text)
        XCTAssertTrue(text!.contains("My Project"))
    }

    func testMockReadMissingFile() async throws {
        let sftp = MockSFTPSession()
        do {
            _ = try await sftp.readFile("/nonexistent/path/file.txt")
            XCTFail("Should throw")
        } catch SFTPError.fileNotFound(let path) {
            XCTAssertTrue(path.contains("nonexistent"))
        }
    }

    func testMockWriteAndRead() async throws {
        let sftp = MockSFTPSession()
        let content = "test content 12345"
        try await sftp.writeFile("/tmp/test.txt", data: Data(content.utf8))
        let read = try await sftp.readFile("/tmp/test.txt")
        XCTAssertEqual(String(data: read, encoding: .utf8), content)
    }

    func testMockCreateDirectory() async throws {
        let sftp = MockSFTPSession()
        try await sftp.createDirectory("/home/user/newdir")
        let exists = try await sftp.fileExists("/home/user/newdir")
        XCTAssertTrue(exists)
    }

    func testMockDeleteFile() async throws {
        let sftp = MockSFTPSession()
        try await sftp.deleteFile("/home/user/projects/README.md")
        let exists = try await sftp.fileExists("/home/user/projects/README.md")
        XCTAssertFalse(exists)
    }

    func testMockDeleteMissing() async throws {
        let sftp = MockSFTPSession()
        do {
            try await sftp.deleteFile("/nonexistent.txt")
            XCTFail("Should throw")
        } catch SFTPError.fileNotFound {
            // Expected
        }
    }

    func testMockRename() async throws {
        let sftp = MockSFTPSession()
        try await sftp.rename(from: "/home/user/projects/README.md", to: "/home/user/projects/DOCS.md")
        let oldExists = try await sftp.fileExists("/home/user/projects/README.md")
        let newExists = try await sftp.fileExists("/home/user/projects/DOCS.md")
        XCTAssertFalse(oldExists)
        XCTAssertTrue(newExists)
    }

    func testMockFileExists() async throws {
        let sftp = MockSFTPSession()
        let exists = try await sftp.fileExists("/home/user/projects/main.py")
        XCTAssertTrue(exists)
        let notExists = try await sftp.fileExists("/totally/fake/path.xyz")
        XCTAssertFalse(notExists)
    }

    func testRemoteFileEntryProperties() {
        let entry = RemoteFileEntry(name: "main.py", path: "/home/user/main.py",
            isDirectory: false, size: 1024, modifiedDate: Date(), permissions: "-rwxr-xr-x")
        XCTAssertEqual(entry.name, "main.py")
        XCTAssertEqual(entry.fileExtension, "py")
        XCTAssertFalse(entry.isDirectory)
        XCTAssertEqual(entry.size, 1024)
    }

    func testRemoteFileEntryDirectory() {
        let entry = RemoteFileEntry(name: "projects", path: "/home/user/projects",
            isDirectory: true, size: 0, modifiedDate: Date(), permissions: "drwxr-xr-x")
        XCTAssertTrue(entry.isDirectory)
        XCTAssertEqual(entry.fileExtension, "")
    }

    func testSFTPErrorDescriptions() {
        XCTAssertNotNil(SFTPError.notConnected.errorDescription)
        XCTAssertNotNil(SFTPError.permissionDenied("/path").errorDescription)
        XCTAssertNotNil(SFTPError.fileNotFound("/path").errorDescription)
        XCTAssertNotNil(SFTPError.connectionLost.errorDescription)
        XCTAssertNotNil(SFTPError.transferFailed("msg").errorDescription)
    }

    func testSFTPErrorContainsPath() {
        let err = SFTPError.fileNotFound("/home/user/missing.txt")
        XCTAssertTrue(err.errorDescription!.contains("missing.txt"))
        let permErr = SFTPError.permissionDenied("/etc/shadow")
        XCTAssertTrue(permErr.errorDescription!.contains("shadow"))
    }
}

final class KnownHostsManagerTests: XCTestCase {
    override func setUp() {
        UserDefaults.standard.removeObject(forKey: "zedipad.knownhosts")
    }

    func testTrustAndCheck() async {
        let manager = await KnownHostsManager()
        let fp = "AB:CD:EF:12"
        await manager.trust(host: "example.com", port: 22, fingerprint: fp)
        let result = await manager.check(host: "example.com", port: 22, fingerprint: fp)
        if case .trusted = result { } else { XCTFail("Expected trusted") }
    }

    func testUnknownHost() async {
        let manager = await KnownHostsManager()
        let result = await manager.check(host: "unknown.host", port: 22, fingerprint: "FF:FF")
        if case .unknown(let fp) = result {
            XCTAssertEqual(fp, "FF:FF")
        } else {
            XCTFail("Expected unknown")
        }
    }

    func testFingerprintMismatch() async {
        let manager = await KnownHostsManager()
        await manager.trust(host: "server.com", port: 22, fingerprint: "AA:BB")
        let result = await manager.check(host: "server.com", port: 22, fingerprint: "CC:DD")
        if case .mismatch(let expected, let actual) = result {
            XCTAssertEqual(expected, "AA:BB")
            XCTAssertEqual(actual, "CC:DD")
        } else {
            XCTFail("Expected mismatch")
        }
    }

    func testRemoveHost() async {
        let manager = await KnownHostsManager()
        await manager.trust(host: "toremove.com", port: 22, fingerprint: "XX")
        await manager.remove(host: "toremove.com", port: 22)
        let result = await manager.check(host: "toremove.com", port: 22, fingerprint: "XX")
        if case .unknown = result { } else { XCTFail("Expected unknown after removal") }
    }

    func testAllHosts() async {
        let manager = await KnownHostsManager()
        await manager.trust(host: "host1.com", port: 22, fingerprint: "A")
        await manager.trust(host: "host2.com", port: 22, fingerprint: "B")
        let all = await manager.allHosts()
        XCTAssertGreaterThanOrEqual(all.count, 2)
    }

    func testSimulateFingerprint() async {
        let fp1 = await KnownHostsManager.simulateFingerprint(for: "host1.com")
        let fp2 = await KnownHostsManager.simulateFingerprint(for: "host1.com")
        let fp3 = await KnownHostsManager.simulateFingerprint(for: "host2.com")
        XCTAssertEqual(fp1, fp2, "Same host should produce same fingerprint")
        XCTAssertNotEqual(fp1, fp3, "Different hosts should produce different fingerprints")
    }

    func testKnownHostProperties() {
        let host = KnownHost(hostname: "test.com", port: 22, fingerprint: "AB:CD", addedDate: Date())
        XCTAssertEqual(host.key, "test.com:22")
        XCTAssertEqual(host.hostname, "test.com")
        XCTAssertEqual(host.port, 22)
    }
}
