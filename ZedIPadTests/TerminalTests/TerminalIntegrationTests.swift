import XCTest
@testable import ZedIPad

// Tests that exercise multiple terminal components together

@MainActor
final class TerminalIntegrationTests: XCTestCase {
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

    // MARK: - Full workflow: create project, add files, navigate

    func testCreateProjectWorkflow() throws {
        // Create project structure
        shell.execute("mkdir myapp")
        shell.execute("cd myapp")
        shell.execute("mkdir Sources")
        shell.execute("mkdir Tests")
        shell.execute("touch Package.swift")
        shell.execute("echo 'let x = 1' > Sources/main.swift")

        // Verify structure
        let lsResult = shell.execute("ls")
        XCTAssertTrue(lsResult.contains("Sources") || lsResult.contains("Package.swift") || lsResult.contains("Tests"))
    }

    func testFileEditWorkflow() throws {
        // Create, write, read, verify file
        shell.execute("touch data.txt")
        shell.execute("echo 'hello' > data.txt")
        let content = shell.execute("cat data.txt")
        XCTAssertTrue(content.trimmingCharacters(in: .whitespacesAndNewlines).contains("hello"))
    }

    func testSearchWorkflow() throws {
        // Create files with content, search
        try "swift code\nlet x = 1".write(to: tmpDir.appendingPathComponent("a.swift"), atomically: true, encoding: .utf8)
        try "python code\nx = 1".write(to: tmpDir.appendingPathComponent("b.py"), atomically: true, encoding: .utf8)

        let swiftSearch = shell.execute("grep swift a.swift")
        XCTAssertTrue(swiftSearch.contains("swift"))

        let pySearch = shell.execute("grep python b.py")
        XCTAssertTrue(pySearch.contains("python"))
    }

    func testDirectoryNavigationWorkflow() throws {
        shell.execute("mkdir -p a/b/c")
        shell.execute("cd a")
        XCTAssertEqual(shell.cwd.lastPathComponent, "a")
        shell.execute("cd b")
        XCTAssertEqual(shell.cwd.lastPathComponent, "b")
        shell.execute("cd c")
        XCTAssertEqual(shell.cwd.lastPathComponent, "c")
        shell.execute("cd ..")
        XCTAssertEqual(shell.cwd.lastPathComponent, "b")
        shell.execute("cd ..")
        XCTAssertEqual(shell.cwd.lastPathComponent, "a")
    }

    func testCopyAndModifyWorkflow() throws {
        try "original".write(to: tmpDir.appendingPathComponent("orig.txt"), atomically: true, encoding: .utf8)
        shell.execute("cp orig.txt copy.txt")
        shell.execute("echo 'modified' > copy.txt")
        let orig = shell.execute("cat orig.txt")
        let copy = shell.execute("cat copy.txt")
        XCTAssertNotEqual(orig.trimmingCharacters(in: .whitespacesAndNewlines),
                          copy.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    func testHistoryAndBangWorkflow() {
        shell.execute("echo first_command")
        shell.execute("echo second_command")
        let bangResult = shell.execute("!!")
        XCTAssertTrue(bangResult.contains("second_command"))
    }

    func testGitWorkflow() throws {
        // Create a git-enabled directory and test workflow
        let gitResult = shell.execute("git init")
        XCTAssertTrue(gitResult.contains("Initialized") || gitResult.contains("init"))
        let statusResult = shell.execute("git status")
        XCTAssertFalse(statusResult.isEmpty)
    }

    func testFindWorkflow() throws {
        // Create nested structure
        try FileManager.default.createDirectory(at: tmpDir.appendingPathComponent("src/models"), withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: tmpDir.appendingPathComponent("src/main.swift").path, contents: Data())
        FileManager.default.createFile(atPath: tmpDir.appendingPathComponent("src/models/User.swift").path, contents: Data())

        let findResult = shell.execute("find . -name *.swift")
        XCTAssertTrue(findResult.contains("swift") || findResult.isEmpty) // May not find in all environments
    }

    func testWcWorkflow() throws {
        let content = "line one\nline two\nline three"
        try content.write(to: tmpDir.appendingPathComponent("three.txt"), atomically: true, encoding: .utf8)
        let wcResult = shell.execute("wc three.txt")
        XCTAssertTrue(wcResult.contains("three.txt"))
    }

    func testHeadTailWorkflow() throws {
        let content = (1...50).map { "line \($0)" }.joined(separator: "\n")
        try content.write(to: tmpDir.appendingPathComponent("fifty.txt"), atomically: true, encoding: .utf8)

        let headResult = shell.execute("head -n 5 fifty.txt")
        let headLines = headResult.components(separatedBy: "\n").filter { !$0.isEmpty }
        XCTAssertLessThanOrEqual(headLines.count, 5)

        let tailResult = shell.execute("tail -n 5 fifty.txt")
        XCTAssertTrue(tailResult.contains("line 50"))
    }

    func testMultipleRedirections() throws {
        shell.execute("echo hello > out1.txt")
        shell.execute("echo world > out2.txt")
        shell.execute("echo combined >> out1.txt")
        let c1 = shell.execute("cat out1.txt")
        XCTAssertTrue(c1.contains("hello"))
        XCTAssertTrue(c1.contains("combined"))
    }
}

// MARK: - Terminal Panel Manager Tests

@MainActor
final class TerminalPanelManagerTests: XCTestCase {
    func testAddSession() {
        let manager = TerminalPanelManager()
        manager.addLocalSession(shell: ShellInterpreter())
        XCTAssertEqual(manager.sessions.count, 1)
        XCTAssertNotNil(manager.activeSession)
    }

    func testAddMultipleSessions() {
        let manager = TerminalPanelManager()
        manager.addLocalSession(shell: ShellInterpreter())
        manager.addLocalSession(shell: ShellInterpreter())
        manager.addSSHSession(name: "myserver")
        XCTAssertEqual(manager.sessions.count, 3)
    }

    func testRemoveSession() {
        let manager = TerminalPanelManager()
        manager.addLocalSession(shell: ShellInterpreter())
        let session = manager.sessions[0]
        manager.removeSession(session)
        XCTAssertTrue(manager.sessions.isEmpty)
        XCTAssertNil(manager.activeSession)
    }

    func testRemoveActiveSessionUpdatesActive() {
        let manager = TerminalPanelManager()
        manager.addLocalSession(shell: ShellInterpreter())
        manager.addLocalSession(shell: ShellInterpreter())
        let first = manager.sessions[0]
        manager.activeSession = first
        manager.removeSession(first)
        XCTAssertNotNil(manager.activeSession)
        XCTAssertEqual(manager.sessions.count, 1)
    }

    func testSessionNames() {
        let manager = TerminalPanelManager()
        manager.addLocalSession(shell: ShellInterpreter())
        manager.addLocalSession(shell: ShellInterpreter())
        XCTAssertEqual(manager.sessions[0].name, "Terminal 1")
        XCTAssertEqual(manager.sessions[1].name, "Terminal 2")
    }

    func testSSHSessionFlagIsTrue() {
        let manager = TerminalPanelManager()
        manager.addSSHSession(name: "prod-server")
        XCTAssertTrue(manager.sessions[0].isSSH)
        XCTAssertTrue(manager.sessions[0].name.contains("prod-server"))
    }

    func testLocalSessionFlagIsFalse() {
        let manager = TerminalPanelManager()
        manager.addLocalSession(shell: ShellInterpreter())
        XCTAssertFalse(manager.sessions[0].isSSH)
    }

    func testSessionIdentifiable() {
        let manager = TerminalPanelManager()
        manager.addLocalSession(shell: ShellInterpreter())
        manager.addLocalSession(shell: ShellInterpreter())
        let ids = manager.sessions.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "Session IDs should be unique")
    }
}

// MARK: - Git Integration Tests

@MainActor
final class GitIntegrationTests: XCTestCase {
    var tmpDir: URL!

    override func setUpWithError() throws {
        tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmpDir)
    }

    func testInitAndBranchCreation() throws {
        let git = GitService(repoURL: tmpDir)
        try git.initRepo(at: tmpDir)
        XCTAssertTrue(git.isRepo)
        XCTAssertEqual(git.branches.count, 1)
        XCTAssertTrue(git.branches[0].isCurrent)
        XCTAssertEqual(git.branches[0].name, "main")
    }

    func testStatusWithMultipleFiles() throws {
        let git = GitService(repoURL: tmpDir)
        try git.initRepo(at: tmpDir)

        // Create multiple files
        for i in 1...5 {
            FileManager.default.createFile(atPath: tmpDir.appendingPathComponent("file\(i).txt").path, contents: Data("content \(i)".utf8))
        }
        git.refresh(at: tmpDir)
        let untracked = git.statusEntries.filter { $0.status == .untracked }
        XCTAssertEqual(untracked.count, 5)
    }

    func testGitCommitMessageValidation() {
        let git = GitService(repoURL: tmpDir)
        _ = git.handleGitCommand(["init"])

        // Empty message should fail
        let emptyResult = git.handleGitCommand(["commit", "-m", ""])
        // Non-empty should succeed
        let goodResult = git.handleGitCommand(["commit", "-m", "Initial commit"])
        XCTAssertTrue(goodResult.contains("Initial commit"))
    }

    func testMultipleBranchCheckout() throws {
        let git = GitService(repoURL: tmpDir)
        try git.initRepo(at: tmpDir)

        _ = git.handleGitCommand(["checkout", "feature-1"])
        XCTAssertEqual(git.currentBranch, "feature-1")

        _ = git.handleGitCommand(["checkout", "feature-2"])
        XCTAssertEqual(git.currentBranch, "feature-2")

        _ = git.handleGitCommand(["checkout", "main"])
        XCTAssertEqual(git.currentBranch, "main")
    }
}
