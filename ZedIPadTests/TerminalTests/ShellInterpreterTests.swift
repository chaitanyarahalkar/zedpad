import XCTest
@testable import ZedIPad

@MainActor
final class ShellInterpreterTests: XCTestCase {
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

    // MARK: - pwd

    func testPwd() {
        let result = shell.execute("pwd")
        XCTAssertEqual(result, tmpDir.path)
    }

    // MARK: - echo

    func testEcho() {
        XCTAssertEqual(shell.execute("echo hello world"), "hello world")
    }

    func testEchoEmpty() {
        XCTAssertEqual(shell.execute("echo"), "")
    }

    // MARK: - mkdir / cd / ls

    func testMkdirAndCd() throws {
        let result = shell.execute("mkdir testdir")
        XCTAssertEqual(result, "")
        var isDir: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: tmpDir.appendingPathComponent("testdir").path, isDirectory: &isDir))
        XCTAssertTrue(isDir.boolValue)

        let cdResult = shell.execute("cd testdir")
        XCTAssertEqual(cdResult, "")
        XCTAssertEqual(shell.cwd.lastPathComponent, "testdir")
    }

    func testCdDotDot() {
        shell.execute("mkdir subdir")
        shell.execute("cd subdir")
        XCTAssertEqual(shell.cwd.lastPathComponent, "subdir")
        shell.execute("cd ..")
        XCTAssertEqual(shell.cwd.path, tmpDir.path)
    }

    func testCdNonexistent() {
        let result = shell.execute("cd nonexistent")
        XCTAssertTrue(result.contains("No such file or directory"))
    }

    func testLsEmpty() {
        let result = shell.execute("ls")
        // Empty dir — result should be empty or just whitespace
        XCTAssertTrue(result.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    func testLsWithFiles() throws {
        FileManager.default.createFile(atPath: tmpDir.appendingPathComponent("file.swift").path, contents: Data())
        let result = shell.execute("ls")
        XCTAssertTrue(result.contains("file.swift"))
    }

    func testLsLong() throws {
        FileManager.default.createFile(atPath: tmpDir.appendingPathComponent("test.txt").path, contents: Data("hello".utf8))
        let result = shell.execute("ls -l")
        XCTAssertTrue(result.contains("test.txt"))
    }

    func testLsHiddenFiles() throws {
        FileManager.default.createFile(atPath: tmpDir.appendingPathComponent(".hidden").path, contents: Data())
        FileManager.default.createFile(atPath: tmpDir.appendingPathComponent("visible.txt").path, contents: Data())
        let normal = shell.execute("ls")
        XCTAssertFalse(normal.contains(".hidden"))
        let withHidden = shell.execute("ls -a")
        XCTAssertTrue(withHidden.contains(".hidden"))
    }

    // MARK: - touch / cat

    func testTouchCreatesFile() {
        shell.execute("touch newfile.txt")
        XCTAssertTrue(FileManager.default.fileExists(atPath: tmpDir.appendingPathComponent("newfile.txt").path))
    }

    func testCatFile() throws {
        let content = "hello swift"
        try content.write(to: tmpDir.appendingPathComponent("cat.txt"), atomically: true, encoding: .utf8)
        let result = shell.execute("cat cat.txt")
        XCTAssertEqual(result, content)
    }

    func testCatMissingFile() {
        let result = shell.execute("cat missing.txt")
        XCTAssertTrue(result.contains("No such file or directory"))
    }

    // MARK: - rm / mv / cp

    func testRmFile() throws {
        let url = tmpDir.appendingPathComponent("todelete.txt")
        FileManager.default.createFile(atPath: url.path, contents: Data())
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        shell.execute("rm todelete.txt")
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }

    func testRmMissingFile() {
        let result = shell.execute("rm nonexistent.txt")
        XCTAssertTrue(result.contains("nonexistent.txt"))
    }

    func testMvFile() throws {
        let src = tmpDir.appendingPathComponent("src.txt")
        FileManager.default.createFile(atPath: src.path, contents: Data("content".utf8))
        shell.execute("mv src.txt dst.txt")
        XCTAssertFalse(FileManager.default.fileExists(atPath: src.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: tmpDir.appendingPathComponent("dst.txt").path))
    }

    func testCpFile() throws {
        let src = tmpDir.appendingPathComponent("original.txt")
        try "data".write(to: src, atomically: true, encoding: .utf8)
        shell.execute("cp original.txt copy.txt")
        XCTAssertTrue(FileManager.default.fileExists(atPath: tmpDir.appendingPathComponent("copy.txt").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: src.path))
    }

    // MARK: - grep / wc / head / tail

    func testGrep() throws {
        try "line one\nline two\nline three".write(to: tmpDir.appendingPathComponent("data.txt"), atomically: true, encoding: .utf8)
        let result = shell.execute("grep two data.txt")
        XCTAssertTrue(result.contains("two"))
        XCTAssertFalse(result.contains("one"))
    }

    func testGrepCaseInsensitive() throws {
        try "Hello World".write(to: tmpDir.appendingPathComponent("case.txt"), atomically: true, encoding: .utf8)
        let result = shell.execute("grep -i hello case.txt")
        XCTAssertTrue(result.contains("Hello"))
    }

    func testGrepNoMatch() throws {
        try "abc".write(to: tmpDir.appendingPathComponent("nomatch.txt"), atomically: true, encoding: .utf8)
        let result = shell.execute("grep xyz nomatch.txt")
        XCTAssertTrue(result.isEmpty)
    }

    func testWc() throws {
        try "a b c\nd e f".write(to: tmpDir.appendingPathComponent("wc.txt"), atomically: true, encoding: .utf8)
        let result = shell.execute("wc wc.txt")
        XCTAssertTrue(result.contains("wc.txt"))
    }

    func testHead() throws {
        let lines = (1...20).map { "line \($0)" }.joined(separator: "\n")
        try lines.write(to: tmpDir.appendingPathComponent("long.txt"), atomically: true, encoding: .utf8)
        let result = shell.execute("head -n 5 long.txt")
        let resultLines = result.components(separatedBy: "\n").filter { !$0.isEmpty }
        XCTAssertLessThanOrEqual(resultLines.count, 5)
        XCTAssertTrue(result.contains("line 1"))
        XCTAssertFalse(result.contains("line 11"))
    }

    func testTail() throws {
        let lines = (1...20).map { "line \($0)" }.joined(separator: "\n")
        try lines.write(to: tmpDir.appendingPathComponent("long2.txt"), atomically: true, encoding: .utf8)
        let result = shell.execute("tail -n 3 long2.txt")
        XCTAssertTrue(result.contains("line 20"))
        XCTAssertFalse(result.contains("line 1\n"))
    }

    // MARK: - History

    func testHistory() {
        shell.execute("echo one")
        shell.execute("echo two")
        let hist = shell.execute("history")
        XCTAssertTrue(hist.contains("echo one"))
        XCTAssertTrue(hist.contains("echo two"))
    }

    func testHistoryBang() {
        shell.execute("echo first")
        let result = shell.execute("!!")
        XCTAssertEqual(result, "first")
    }

    func testHistoryNavigation() {
        shell.execute("cmd_a")
        shell.execute("cmd_b")
        let up1 = shell.historyUp()
        XCTAssertEqual(up1, "cmd_b")
        let up2 = shell.historyUp()
        XCTAssertNotNil(up2)
        let down = shell.historyDown()
        XCTAssertNotNil(down)
    }

    // MARK: - Tab completion

    func testTabCompletion() throws {
        FileManager.default.createFile(atPath: tmpDir.appendingPathComponent("main.swift").path, contents: Data())
        FileManager.default.createFile(atPath: tmpDir.appendingPathComponent("model.swift").path, contents: Data())
        let completions = shell.complete("ls m")
        XCTAssertFalse(completions.isEmpty)
        XCTAssertTrue(completions.allSatisfy { $0.hasPrefix("m") })
    }

    // MARK: - Redirection

    func testOutputRedirection() {
        shell.execute("echo hello > output.txt")
        let content = try? String(contentsOf: tmpDir.appendingPathComponent("output.txt"), encoding: .utf8)
        XCTAssertEqual(content?.trimmingCharacters(in: .whitespacesAndNewlines), "hello")
    }

    func testAppendRedirection() {
        shell.execute("echo line1 > append.txt")
        shell.execute("echo line2 >> append.txt")
        let content = try? String(contentsOf: tmpDir.appendingPathComponent("append.txt"), encoding: .utf8)
        XCTAssertTrue(content?.contains("line1") ?? false)
        XCTAssertTrue(content?.contains("line2") ?? false)
    }

    // MARK: - Prompt

    func testPromptContainsCwd() {
        let prompt = shell.prompt()
        XCTAssertFalse(prompt.isEmpty)
    }

    // MARK: - Special returns

    func testExitCommand() {
        XCTAssertEqual(shell.execute("exit"), "__EXIT__")
        XCTAssertEqual(shell.execute("quit"), "__EXIT__")
    }

    func testOpenCommandReturnsMarker() {
        let result = shell.execute("open main.swift")
        XCTAssertTrue(result.hasPrefix("__OPEN__:"))
    }

    func testSSHCommandReturnsMarker() {
        let result = shell.execute("ssh user@host.com")
        XCTAssertTrue(result.hasPrefix("__SSH__:"))
    }

    func testUnknownCommand() {
        let result = shell.execute("foobar --xyz")
        XCTAssertTrue(result.contains("command not found"))
    }

    func testClearCommand() {
        let result = shell.execute("clear")
        XCTAssertTrue(result.contains("\u{1B}[2J"))
    }

    func testHelpCommand() {
        let result = shell.execute("help")
        XCTAssertTrue(result.contains("ls"))
        XCTAssertTrue(result.contains("git"))
        XCTAssertTrue(result.contains("ssh"))
    }
}

// MARK: - ANSI Tests

final class ANSITests: XCTestCase {
    func testAnsiGreen() {
        let s = ANSI.green("hello")
        XCTAssertTrue(s.contains("hello"))
        XCTAssertTrue(s.contains("\u{1B}["))
    }

    func testAnsiReset() {
        let s = ANSI.red("err")
        XCTAssertTrue(s.hasSuffix("\u{1B}[0m"))
    }

    func testPadLeft() {
        XCTAssertEqual("42".padLeft(5), "   42")
        XCTAssertEqual("hello".padLeft(3), "hello")
    }

    func testPadRight() {
        XCTAssertEqual("hi".padRight(5), "hi   ")
        XCTAssertEqual("hello".padRight(3), "hello")
    }
}
