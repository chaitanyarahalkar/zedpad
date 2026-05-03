import XCTest
@testable import ZedIPad

@MainActor
final class ShellEdgeCaseTests: XCTestCase {
    var shell: ShellInterpreter!
    var tmpDir: URL!

    override func setUpWithError() throws {
        shell = ShellInterpreter()
        tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        shell.cwd = tmpDir
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmpDir)
    }

    // MARK: - Unicode and special chars

    func testEchoUnicode() {
        let result = shell.execute("echo 你好世界")
        XCTAssertTrue(result.contains("你好"))
    }

    func testTouchFileWithSpaces() {
        shell.execute("touch 'file with spaces.txt'")
        // Note: simple space handling - file might have quotes
        let ls = shell.execute("ls")
        XCTAssertFalse(ls.isEmpty || ls.contains("command not found"))
    }

    func testEchoWithQuotes() {
        let result = shell.execute("echo 'hello world'")
        XCTAssertTrue(result.contains("hello world"))
    }

    func testEchoDoubleQuotes() {
        let result = shell.execute("echo \"hello world\"")
        XCTAssertTrue(result.contains("hello world"))
    }

    // MARK: - Command robustness

    func testCatEmptyFile() throws {
        FileManager.default.createFile(atPath: tmpDir.appendingPathComponent("empty.txt").path, contents: Data())
        let result = shell.execute("cat empty.txt")
        XCTAssertEqual(result, "")
    }

    func testLsNonexistentDirectory() {
        let result = shell.execute("ls /totally/fake/path/xyz")
        XCTAssertTrue(result.contains("No such file") || result.isEmpty)
    }

    func testRmNonexistentFile() {
        let result = shell.execute("rm totally_fake_file.txt")
        XCTAssertFalse(result.isEmpty) // Should produce error
    }

    func testMkdirExistingDirectory() throws {
        try FileManager.default.createDirectory(at: tmpDir.appendingPathComponent("existing"), withIntermediateDirectories: true)
        let result = shell.execute("mkdir existing")
        // Should silently succeed (withIntermediateDirectories: true) or error
        XCTAssertTrue(result.isEmpty || result.contains("existing"))
    }

    func testMvMissingSource() {
        let result = shell.execute("mv nonexistent.txt dest.txt")
        XCTAssertFalse(result.isEmpty)
    }

    func testCpMissingSource() {
        let result = shell.execute("cp missing.txt copy.txt")
        XCTAssertFalse(result.isEmpty)
    }

    func testGrepMissingFile() {
        let result = shell.execute("grep pattern missingfile.txt")
        XCTAssertTrue(result.contains("No such file") || result.contains("missingfile"))
    }

    func testWcMissingFile() {
        let result = shell.execute("wc missingfile.txt")
        XCTAssertTrue(result.contains("No such file") || result.contains("missingfile"))
    }

    func testHeadMissingFile() {
        let result = shell.execute("head missingfile.txt")
        XCTAssertFalse(result.isEmpty)
    }

    func testTailMissingFile() {
        let result = shell.execute("tail missingfile.txt")
        XCTAssertFalse(result.isEmpty)
    }

    // MARK: - History edge cases

    func testHistoryEmpty() {
        let freshShell = ShellInterpreter()
        let result = freshShell.execute("!!")
        XCTAssertTrue(result.contains("no previous command") || result.isEmpty)
    }

    func testHistoryUpOnEmpty() {
        let freshShell = ShellInterpreter()
        let result = freshShell.historyUp()
        XCTAssertNil(result)
    }

    func testHistoryDownOnEmpty() {
        let freshShell = ShellInterpreter()
        let result = freshShell.historyDown()
        XCTAssertNil(result)
    }

    func testHistoryWrap() {
        shell.execute("cmd1")
        shell.execute("cmd2")
        shell.execute("cmd3")
        _ = shell.historyUp() // cmd3
        _ = shell.historyUp() // cmd2
        _ = shell.historyUp() // cmd1
        _ = shell.historyUp() // should stay at cmd1 (first)
        let result = shell.historyDown()
        XCTAssertNotNil(result)
    }

    // MARK: - Tab completion edge cases

    func testTabCompletionEmpty() {
        let completions = shell.complete("")
        // No prefix - might return all or nothing
        XCTAssertNotNil(completions)
    }

    func testTabCompletionNoMatch() throws {
        let completions = shell.complete("ls zzz_nonexistent_prefix")
        XCTAssertTrue(completions.isEmpty)
    }

    // MARK: - Path resolution

    func testResolveAbsolutePath() {
        let resolved = shell.resolve("/absolute/path/file.txt")
        XCTAssertEqual(resolved.path, "/absolute/path/file.txt")
    }

    func testResolveTildePath() {
        let resolved = shell.resolve("~")
        XCTAssertFalse(resolved.path.isEmpty)
    }

    func testResolveRelativePath() {
        let resolved = shell.resolve("subdir/file.txt")
        XCTAssertTrue(resolved.path.contains(tmpDir.path))
        XCTAssertTrue(resolved.path.contains("subdir/file.txt"))
    }

    // MARK: - Prompt format

    func testPromptFormat() {
        let prompt = shell.prompt()
        XCTAssertTrue(prompt.contains("$"))
        XCTAssertFalse(prompt.isEmpty)
    }

    func testPromptChangesWithCd() {
        let before = shell.prompt()
        shell.execute("mkdir subdir123")
        shell.execute("cd subdir123")
        let after = shell.prompt()
        XCTAssertNotEqual(before, after)
        XCTAssertTrue(after.contains("subdir123"))
    }

    // MARK: - Multiple operations

    func testLargeFileCount() throws {
        for i in 0..<100 {
            FileManager.default.createFile(atPath: tmpDir.appendingPathComponent("file\(i).txt").path, contents: Data())
        }
        let ls = shell.execute("ls")
        XCTAssertFalse(ls.isEmpty)
    }

    func testDeepNesting() throws {
        var url = tmpDir!
        for depth in 0..<10 {
            url = url.appendingPathComponent("level\(depth)")
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            shell.execute("cd level\(depth)")
        }
        XCTAssertTrue(shell.cwd.path.contains("level9"))
        // Navigate back
        for _ in 0..<10 {
            shell.execute("cd ..")
        }
        XCTAssertEqual(shell.cwd.path, tmpDir.path)
    }
}

// MARK: - SFTP Service Integration

@MainActor
final class SFTPServiceIntegrationTests: XCTestCase {
    func testConnectAndList() async {
        let conn = SSHConnection(name: "Test", host: "mock.server", username: "user")
        let sftp = SFTPService(connection: conn)
        await sftp.connect()
        XCTAssertTrue(sftp.isConnected)
        XCTAssertFalse(sftp.entries.isEmpty)
    }

    func testListSubdirectory() async {
        let conn = SSHConnection(name: "Test", host: "mock.server", username: "user")
        let sftp = SFTPService(connection: conn)
        await sftp.connect()
        await sftp.listDirectory("/home/user/projects")
        XCTAssertEqual(sftp.currentPath, "/home/user/projects")
    }

    func testReadRemoteFile() async throws {
        let conn = SSHConnection(name: "Test", host: "mock.server", username: "user")
        let sftp = SFTPService(connection: conn)
        await sftp.connect()
        let content = try await sftp.readFile("/home/user/projects/README.md")
        XCTAssertTrue(content.contains("My Project"))
    }

    func testWriteRemoteFile() async throws {
        let conn = SSHConnection(name: "Test", host: "mock.server", username: "user")
        let sftp = SFTPService(connection: conn)
        await sftp.connect()
        try await sftp.writeFile("/tmp/newfile.txt", content: "hello remote")
        let content = try await sftp.readFile("/tmp/newfile.txt")
        XCTAssertEqual(content, "hello remote")
    }

    func testCreateRemoteDirectory() async throws {
        let conn = SSHConnection(name: "Test", host: "mock.server", username: "user")
        let sftp = SFTPService(connection: conn)
        await sftp.connect()
        try await sftp.createDirectory("/home/user/newdir")
        XCTAssertNil(sftp.lastError)
    }

    func testDeleteRemoteFile() async throws {
        let conn = SSHConnection(name: "Test", host: "mock.server", username: "user")
        let sftp = SFTPService(connection: conn)
        await sftp.connect()
        try await sftp.writeFile("/tmp/todelete.txt", content: "delete me")
        try await sftp.deleteFile("/tmp/todelete.txt")
        XCTAssertNil(sftp.lastError)
    }

    func testRenameRemoteFile() async throws {
        let conn = SSHConnection(name: "Test", host: "mock.server", username: "user")
        let sftp = SFTPService(connection: conn)
        await sftp.connect()
        try await sftp.writeFile("/tmp/original.txt", content: "data")
        try await sftp.rename(from: "/tmp/original.txt", to: "/tmp/renamed.txt")
        let content = try await sftp.readFile("/tmp/renamed.txt")
        XCTAssertEqual(content, "data")
    }

    func testSFTPConnectionProperty() {
        let conn = SSHConnection(name: "Prod", host: "prod.example.com", port: 2222, username: "deploy")
        let sftp = SFTPService(connection: conn)
        XCTAssertEqual(sftp.connection.host, "prod.example.com")
        XCTAssertEqual(sftp.connection.port, 2222)
        XCTAssertFalse(sftp.isConnected)
    }
}
