import XCTest
@testable import ZedIPad

@MainActor
final class GitServiceTests: XCTestCase {
    var tmpDir: URL!

    override func setUpWithError() throws {
        tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmpDir)
    }

    func testInitRepo() throws {
        let git = GitService(repoURL: tmpDir)
        try git.initRepo(at: tmpDir)
        XCTAssertTrue(git.isRepo)
        XCTAssertEqual(git.currentBranch, "main")
        let gitDir = tmpDir.appendingPathComponent(".git")
        XCTAssertTrue(FileManager.default.fileExists(atPath: gitDir.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: gitDir.appendingPathComponent("HEAD").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: gitDir.appendingPathComponent("config").path))
    }

    func testReadBranchFromHead() throws {
        let git = GitService(repoURL: tmpDir)
        try git.initRepo(at: tmpDir)
        let branch = git.readBranch(at: tmpDir)
        XCTAssertEqual(branch, "main")
    }

    func testNotARepo() {
        let git = GitService(repoURL: tmpDir)
        XCTAssertFalse(git.isRepo)
        XCTAssertTrue(git.statusEntries.isEmpty)
    }

    func testStatusOnEmptyRepo() throws {
        let git = GitService(repoURL: tmpDir)
        try git.initRepo(at: tmpDir)
        git.refresh(at: tmpDir)
        XCTAssertTrue(git.isRepo)
    }

    func testStatusWithUntrackedFile() throws {
        let git = GitService(repoURL: tmpDir)
        try git.initRepo(at: tmpDir)
        let file = tmpDir.appendingPathComponent("new_file.swift")
        FileManager.default.createFile(atPath: file.path, contents: Data("let x = 1".utf8))
        git.refresh(at: tmpDir)
        let untracked = git.statusEntries.filter { $0.status == .untracked }
        XCTAssertFalse(untracked.isEmpty)
        XCTAssertTrue(untracked.map(\.path).contains("new_file.swift"))
    }

    func testGitInitCommand() throws {
        let git = GitService(repoURL: tmpDir)
        let result = git.handleGitCommand(["init"])
        XCTAssertTrue(result.contains("Initialized"))
        XCTAssertTrue(result.contains(tmpDir.path))
    }

    func testGitStatusNotRepo() {
        let git = GitService(repoURL: tmpDir)
        let result = git.handleGitCommand(["status"])
        XCTAssertTrue(result.contains("not a git repository"))
    }

    func testGitStatusInRepo() throws {
        let git = GitService(repoURL: tmpDir)
        _ = git.handleGitCommand(["init"])
        let result = git.handleGitCommand(["status"])
        XCTAssertTrue(result.contains("On branch"))
        XCTAssertTrue(result.contains("main"))
    }

    func testGitBranchCommand() throws {
        let git = GitService(repoURL: tmpDir)
        _ = git.handleGitCommand(["init"])
        let result = git.handleGitCommand(["branch"])
        XCTAssertTrue(result.contains("main"))
        XCTAssertTrue(result.contains("*"))
    }

    func testGitAddCommand() throws {
        let git = GitService(repoURL: tmpDir)
        _ = git.handleGitCommand(["init"])
        FileManager.default.createFile(atPath: tmpDir.appendingPathComponent("file.swift").path, contents: Data("let x = 1".utf8))
        let result = git.handleGitCommand(["add", "file.swift"])
        XCTAssertTrue(result.contains("Staged"))
        let status = git.handleGitCommand(["status"])
        XCTAssertTrue(status.contains("Changes to be committed"))
        XCTAssertTrue(status.contains("file.swift"))
    }

    func testGitAddNoFiles() throws {
        let git = GitService(repoURL: tmpDir)
        _ = git.handleGitCommand(["init"])
        let result = git.handleGitCommand(["add"])
        XCTAssertTrue(result.contains("nothing specified"))
    }

    func testGitCommitWithMessage() throws {
        let git = GitService(repoURL: tmpDir)
        _ = git.handleGitCommand(["init"])
        FileManager.default.createFile(atPath: tmpDir.appendingPathComponent("file.swift").path, contents: Data("let x = 1".utf8))
        _ = git.handleGitCommand(["add", "file.swift"])
        let result = git.handleGitCommand(["commit", "-m", "Initial commit"])
        XCTAssertTrue(result.contains("Initial commit"))
        XCTAssertTrue(git.handleGitCommand(["log"]).contains("Initial commit"))
        XCTAssertTrue(git.handleGitCommand(["status"]).contains("working tree clean"))
    }

    func testGitCommitRequiresStagedChanges() throws {
        let git = GitService(repoURL: tmpDir)
        _ = git.handleGitCommand(["init"])
        let result = git.handleGitCommand(["commit", "-m", "Initial commit"])
        XCTAssertTrue(result.contains("nothing to commit"))
    }

    func testGitCommitNoMessage() throws {
        let git = GitService(repoURL: tmpDir)
        _ = git.handleGitCommand(["init"])
        let result = git.handleGitCommand(["commit"])
        XCTAssertTrue(result.contains("-m"))
    }

    func testGitCheckout() throws {
        let git = GitService(repoURL: tmpDir)
        _ = git.handleGitCommand(["init"])
        let result = git.handleGitCommand(["checkout", "feature-branch"])
        XCTAssertTrue(result.contains("feature-branch"))
        XCTAssertEqual(git.currentBranch, "feature-branch")
        XCTAssertTrue(git.handleGitCommand(["branch"]).contains("* feature-branch"))
    }

    func testGitCheckoutNoArgs() throws {
        let git = GitService(repoURL: tmpDir)
        _ = git.handleGitCommand(["init"])
        let result = git.handleGitCommand(["checkout"])
        XCTAssertTrue(result.contains("missing branch name"))
    }

    func testGitUnknownSubcommand() throws {
        let git = GitService(repoURL: tmpDir)
        _ = git.handleGitCommand(["init"])
        let result = git.handleGitCommand(["frobnicate"])
        XCTAssertTrue(result.contains("not a git command"))
    }

    func testGitLogEmpty() throws {
        let git = GitService(repoURL: tmpDir)
        _ = git.handleGitCommand(["init"])
        let result = git.handleGitCommand(["log"])
        XCTAssertFalse(result.isEmpty)
    }

    func testGitDiffClean() throws {
        let git = GitService(repoURL: tmpDir)
        _ = git.handleGitCommand(["init"])
        let result = git.handleGitCommand(["diff"])
        // Empty repo = empty diff
        XCTAssertTrue(result.isEmpty)
    }

    func testGitAddCommitLogDiffStatusWorkflowPersistsAcrossInstances() throws {
        var git = GitService(repoURL: tmpDir)
        _ = git.handleGitCommand(["init"])

        let file = tmpDir.appendingPathComponent("Sources/App.swift")
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: file.path, contents: Data("let value = 1\n".utf8))

        let addResult = git.handleGitCommand(["add", "."])
        XCTAssertTrue(addResult.contains("Sources/App.swift"))
        let commitResult = git.handleGitCommand(["commit", "-m", "Add app source"])
        XCTAssertTrue(commitResult.contains("Add app source"))

        git = GitService(repoURL: tmpDir)
        XCTAssertTrue(git.handleGitCommand(["log"]).contains("Add app source"))
        XCTAssertTrue(git.handleGitCommand(["status"]).contains("working tree clean"))

        try "let value = 2\n".write(to: file, atomically: true, encoding: .utf8)
        let status = git.handleGitCommand(["status"])
        XCTAssertTrue(status.contains("modified"))
        XCTAssertTrue(status.contains("Sources/App.swift"))

        let diff = git.handleGitCommand(["diff"])
        XCTAssertTrue(diff.contains("diff --git a/Sources/App.swift b/Sources/App.swift"))
        XCTAssertTrue(diff.contains("-let value = 1"))
        XCTAssertTrue(diff.contains("+let value = 2"))

        _ = git.handleGitCommand(["add", "Sources/App.swift"])
        _ = git.handleGitCommand(["commit", "-m", "Update app source"])
        XCTAssertTrue(git.handleGitCommand(["log"]).contains("Update app source"))
        XCTAssertTrue(git.handleGitCommand(["status"]).contains("working tree clean"))
    }

    func testGitFileStatusValues() {
        XCTAssertEqual(GitFileStatus.added.badge, "A")
        XCTAssertEqual(GitFileStatus.modified.badge, "M")
        XCTAssertEqual(GitFileStatus.deleted.badge, "D")
        XCTAssertEqual(GitFileStatus.untracked.badge, "?")
        XCTAssertEqual(GitFileStatus.renamed.badge, "R")
    }

    func testGitStatusEntryIdentifiable() {
        let entry = GitStatusEntry(path: "file.swift", status: .modified)
        XCTAssertNotNil(entry.id)
        XCTAssertEqual(entry.path, "file.swift")
        XCTAssertEqual(entry.status, .modified)
    }

    func testReadBranchesEmptyRepo() throws {
        let git = GitService(repoURL: tmpDir)
        try git.initRepo(at: tmpDir)
        let branches = git.readBranches(at: tmpDir)
        XCTAssertFalse(branches.isEmpty)
        XCTAssertTrue(branches.contains(where: { $0.isCurrent }))
    }

    func testGitServiceInit() {
        let git = GitService(repoURL: nil)
        XCTAssertFalse(git.isRepo)
        XCTAssertNil(git.repoURL)
    }
}
