import XCTest
@testable import ZedIPad

// MARK: - Editor golden path

@MainActor
final class ComprehensiveEditorTests: XCTestCase {
    func testOpenFileUpdatesAppState() {
        let state = AppState()
        let file = FileNode(name: "test.swift", type: .file, path: "/test.swift", content: "let x = 1")
        state.openFile(file)
        XCTAssertEqual(state.activeFile?.id, file.id)
        XCTAssertEqual(state.openFiles.count, 1)
    }

    func testCloseFileRemovesFromOpenFiles() {
        let state = AppState()
        let file = FileNode(name: "test.swift", type: .file, path: "/test.swift")
        state.openFile(file)
        state.closeFile(file)
        XCTAssertTrue(state.openFiles.isEmpty)
        XCTAssertNil(state.activeFile)
    }

    func testSyntaxHighlightingTokensForSwift() {
        let highlighter = SyntaxHighlighter(theme: .dark)
        let code = "import Foundation\nlet x: Int = 42"
        let tokens = highlighter.highlight(code, language: .swift)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testFindStateCorrectlyCountsMatches() {
        let find = FindState()
        find.query = "let"
        let text = "let x = 1\nlet y = 2\nvar z = 3"
        let ranges = find.search(in: text)
        XCTAssertEqual(ranges.count, 2)
        XCTAssertEqual(find.matchCount, 2)
    }

    func testReplaceAllUpdatesText() {
        let find = FindState()
        find.query = "foo"
        find.replaceQuery = "bar"
        var text = "foo baz foo"
        let count = find.replaceAll(in: &text)
        XCTAssertEqual(count, 2)
        XCTAssertEqual(text, "bar baz bar")
    }

    func testFontSizeIncrease() {
        let state = AppState()
        let initial = state.fontSize
        state.increaseFontSize()
        XCTAssertEqual(state.fontSize, initial + 1)
    }

    func testFontSizeCappedAt24() {
        let state = AppState()
        state.fontSize = 24
        state.increaseFontSize()
        XCTAssertEqual(state.fontSize, 24)
    }

    func testFontSizeFloorAt9() {
        let state = AppState()
        state.fontSize = 9
        state.decreaseFontSize()
        XCTAssertEqual(state.fontSize, 9)
    }
}

// MARK: - Theme tests

@MainActor
final class ComprehensiveThemeTests: XCTestCase {
    func testAllFourThemesExist() {
        XCTAssertEqual(ZedTheme.allCases.count, 4)
    }

    func testDarkThemeColorScheme() {
        XCTAssertEqual(ZedTheme.dark.colorScheme, .dark)
        XCTAssertEqual(ZedTheme.oneDark.colorScheme, .dark)
        XCTAssertEqual(ZedTheme.solarizedDark.colorScheme, .dark)
    }

    func testLightThemeColorScheme() {
        XCTAssertEqual(ZedTheme.light.colorScheme, .light)
    }

    func testToggleThemeAlternates() {
        let state = AppState()
        XCTAssertEqual(state.theme, .dark)
        state.toggleTheme()
        XCTAssertEqual(state.theme, .light)
        state.toggleTheme()
        XCTAssertEqual(state.theme, .dark)
    }

    func testThemeColorsAreDifferentAcrossThemes() {
        XCTAssertNotEqual(ZedTheme.dark.background, ZedTheme.light.background)
        XCTAssertNotEqual(ZedTheme.dark.primaryText, ZedTheme.light.primaryText)
        XCTAssertNotEqual(ZedTheme.dark.accentColor, ZedTheme.solarizedDark.accentColor)
    }

    func testSyntaxColorsExistForAllThemes() {
        for theme in ZedTheme.allCases {
            XCTAssertNotNil(theme.syntaxKeyword)
            XCTAssertNotNil(theme.syntaxString)
            XCTAssertNotNil(theme.syntaxComment)
            XCTAssertNotNil(theme.syntaxFunction)
        }
    }
}

// MARK: - Find & Replace

@MainActor
final class ComprehensiveFindTests: XCTestCase {
    func testCaseSensitiveSearch() {
        let find = FindState()
        find.query = "Hello"
        find.isCaseSensitive = true
        let ranges = find.search(in: "hello Hello HELLO")
        XCTAssertEqual(ranges.count, 1)
    }

    func testCaseInsensitiveSearch() {
        let find = FindState()
        find.query = "hello"
        find.isCaseSensitive = false
        let ranges = find.search(in: "hello Hello HELLO")
        XCTAssertEqual(ranges.count, 3)
    }

    func testRegexSearch() {
        let find = FindState()
        find.query = "func \\w+"
        find.isRegex = true
        let ranges = find.search(in: "func main() {}\nfunc helper() {}")
        XCTAssertEqual(ranges.count, 2)
    }

    func testEmptyQueryReturnsZeroMatches() {
        let find = FindState()
        find.query = ""
        let ranges = find.search(in: "some text here")
        XCTAssertTrue(ranges.isEmpty)
        XCTAssertEqual(find.matchCount, 0)
    }

    func testNextMatchWraps() {
        let find = FindState()
        find.query = "x"
        let _ = find.search(in: "x x x")
        find.currentMatch = 2
        find.nextMatch()
        XCTAssertEqual(find.currentMatch, 0)
    }

    func testPrevMatchWraps() {
        let find = FindState()
        find.query = "x"
        let _ = find.search(in: "x x x")
        find.currentMatch = 0
        find.previousMatch()
        XCTAssertEqual(find.currentMatch, 2)
    }

    func testReplaceCurrentMatch() {
        let find = FindState()
        find.query = "foo"
        find.replaceQuery = "bar"
        var text = "foo hello foo"
        let _ = find.search(in: text)
        find.replace(in: &text, at: 0)
        XCTAssertTrue(text.contains("bar"))
    }
}

// MARK: - SSH models

@MainActor
final class ComprehensiveSSHTests: XCTestCase {
    func testSSHConnectionEncodesDecodes() throws {
        let conn = SSHConnection(name: "myserver", host: "192.168.1.1", port: 22,
                                 username: "admin", authMethod: .password)
        let data = try JSONEncoder().encode(conn)
        let decoded = try JSONDecoder().decode(SSHConnection.self, from: data)
        XCTAssertEqual(decoded.name, conn.name)
        XCTAssertEqual(decoded.host, conn.host)
        XCTAssertEqual(decoded.port, conn.port)
        XCTAssertEqual(decoded.username, conn.username)
    }

    func testSSHConnectionDefaultPort() {
        let conn = SSHConnection(name: "s", host: "h", port: 22, username: "u", authMethod: .password)
        XCTAssertEqual(conn.port, 22)
    }

    func testSSHAuthMethodPassword() {
        let auth = SSHAuthMethod.password
        XCTAssertEqual(auth, .password)
    }

    func testSSHAuthMethodKeyPair() {
        let auth = SSHAuthMethod.keyPair(publicKey: "ssh-ed25519 AAAA...")
        if case .keyPair(let pk) = auth {
            XCTAssertTrue(pk.hasPrefix("ssh-ed25519"))
        } else {
            XCTFail("Wrong auth method")
        }
    }

    func testSSHKeyManagerGeneratesKeys() throws {
        let result = try SSHKeyManager.generateKeyPair()
        XCTAssertFalse(result.privateKeyPEM.isEmpty)
        XCTAssertFalse(result.publicKeyOpenSSH.isEmpty)
        XCTAssertTrue(result.publicKeyOpenSSH.hasPrefix("ssh-ed25519 "), "Public key must have OpenSSH prefix")
    }

    func testServerStoreCRUD() {
        let store = ServerStore()
        let conn = SSHConnection(name: "test", host: "localhost", port: 22, username: "user", authMethod: .password)
        store.add(conn)
        XCTAssertTrue(store.connections.contains(where: { $0.id == conn.id }))
        store.delete(conn)
        XCTAssertFalse(store.connections.contains(where: { $0.id == conn.id }))
    }

    func testKnownHostsUnknownHost() {
        let manager = KnownHostsManager()
        let result = manager.check(host: "unknown-\(UUID().uuidString).example.com", fingerprint: "abc123")
        if case .unknown = result { } else { XCTFail("Expected .unknown, got \(result)") }
    }

    func testKnownHostsTrustThenVerify() {
        let manager = KnownHostsManager()
        let host = "known-\(UUID().uuidString).example.com"
        manager.trust(host: host, fingerprint: "abc123")
        let result = manager.check(host: host, fingerprint: "abc123")
        if case .trusted = result { } else { XCTFail("Expected .trusted, got \(result)") }
    }

    func testKnownHostsMismatch() {
        let manager = KnownHostsManager()
        let host = "mismatch-\(UUID().uuidString).example.com"
        manager.trust(host: host, fingerprint: "abc123")
        let result = manager.check(host: host, fingerprint: "different")
        if case .mismatch = result { } else { XCTFail("Expected .mismatch, got \(result)") }
    }
}

// MARK: - Filesystem operations

@MainActor
final class ComprehensiveFilesystemTests: XCTestCase {
    let fm = FileManager.default
    var tmpDir: URL!

    override func setUpWithError() throws {
        tmpDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fm.createDirectory(at: tmpDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? fm.removeItem(at: tmpDir)
    }

    func testCreateFile() throws {
        let url = try FileSystemService.shared.createFile(named: "test.txt", in: tmpDir)
        XCTAssertTrue(fm.fileExists(atPath: url.path))
    }

    func testDeleteFile() throws {
        let url = tmpDir.appendingPathComponent("del.txt")
        fm.createFile(atPath: url.path, contents: nil)
        try FileSystemService.shared.delete(at: url)
        XCTAssertFalse(fm.fileExists(atPath: url.path))
    }

    func testRenameFile() throws {
        let url = tmpDir.appendingPathComponent("old.txt")
        fm.createFile(atPath: url.path, contents: nil)
        let newURL = try FileSystemService.shared.rename(at: url, to: "new.txt")
        XCTAssertTrue(fm.fileExists(atPath: newURL.path))
        XCTAssertFalse(fm.fileExists(atPath: url.path))
    }

    func testCopyFile() throws {
        let url = tmpDir.appendingPathComponent("orig.txt")
        fm.createFile(atPath: url.path, contents: Data("hello".utf8))
        let copyURL = tmpDir.appendingPathComponent("copy.txt")
        try FileSystemService.shared.copy(from: url, to: copyURL)
        XCTAssertTrue(fm.fileExists(atPath: url.path))
        XCTAssertTrue(fm.fileExists(atPath: copyURL.path))
    }

    func testReadWriteFile() throws {
        let url = tmpDir.appendingPathComponent("rw.txt")
        try FileSystemService.shared.writeFile(at: url, content: "hello world")
        let content = try FileSystemService.shared.readFile(at: url)
        XCTAssertEqual(content, "hello world")
    }

    func testLoadDirectory() throws {
        let a = tmpDir.appendingPathComponent("a.swift")
        let b = tmpDir.appendingPathComponent("b.py")
        fm.createFile(atPath: a.path, contents: nil)
        fm.createFile(atPath: b.path, contents: nil)
        let node = try FileSystemService.shared.loadDirectory(at: tmpDir)
        XCTAssertEqual(node.type, .directory)
        XCTAssertEqual(node.children?.count, 2)
    }

    func testCreateDirectory() throws {
        let url = try FileSystemService.shared.createDirectory(named: "newdir", in: tmpDir)
        var isDir: ObjCBool = false
        XCTAssertTrue(fm.fileExists(atPath: url.path, isDirectory: &isDir))
        XCTAssertTrue(isDir.boolValue)
    }
}

// MARK: - AppState integrity

@MainActor
final class ComprehensiveAppStateTests: XCTestCase {
    func testOpenFileAddsToOpenFiles() {
        let state = AppState()
        let f = FileNode(name: "a.swift", type: .file, path: "/a.swift")
        state.openFile(f)
        XCTAssertEqual(state.openFiles.count, 1)
        XCTAssertEqual(state.activeFile?.id, f.id)
    }

    func testOpenFileTwiceNoDuplicate() {
        let state = AppState()
        let f = FileNode(name: "a.swift", type: .file, path: "/a.swift")
        state.openFile(f)
        state.openFile(f)
        XCTAssertEqual(state.openFiles.count, 1)
    }

    func testOpenDirectoryDoesNothing() {
        let state = AppState()
        let dir = FileNode(name: "src", type: .directory, path: "/src", children: [])
        state.openFile(dir)
        XCTAssertNil(state.activeFile)
    }

    func testCloseMiddleFileKeepsOthers() {
        let state = AppState()
        let a = FileNode(name: "a.swift", type: .file, path: "/a.swift")
        let b = FileNode(name: "b.swift", type: .file, path: "/b.swift")
        let c = FileNode(name: "c.swift", type: .file, path: "/c.swift")
        state.openFile(a); state.openFile(b); state.openFile(c)
        state.closeFile(b)
        XCTAssertEqual(state.openFiles.count, 2)
        XCTAssertTrue(state.openFiles.contains(where: { $0.id == a.id }))
        XCTAssertTrue(state.openFiles.contains(where: { $0.id == c.id }))
    }

    func testRecentFilesCappedAt10() {
        let state = AppState()
        for i in 0..<15 {
            let f = FileNode(name: "\(i).swift", type: .file, path: "/\(i).swift")
            state.openFile(f)
        }
        XCTAssertLessThanOrEqual(state.recentFiles.count, AppState.maxRecentFiles)
    }

    func testWordWrapDefaultTrue() {
        let state = AppState()
        XCTAssertTrue(state.wordWrap)
    }

    func testTabSizeDefault4() {
        let state = AppState()
        XCTAssertEqual(state.tabSize, 4)
    }
}

// MARK: - Language detection

@MainActor
final class ComprehensiveLanguageTests: XCTestCase {
    func testLanguageDetectionAllSupported() {
        let cases: [(String, Language)] = [
            ("swift", .swift), ("js", .javascript), ("ts", .typescript),
            ("py", .python), ("rs", .rust), ("md", .markdown), ("json", .json),
            ("yaml", .yaml), ("yml", .yaml), ("sh", .bash), ("bash", .bash),
            ("rb", .ruby), ("html", .html), ("htm", .html), ("css", .css),
            ("go", .go), ("kt", .kotlin), ("kts", .kotlin), ("c", .c),
            ("cpp", .cpp), ("sql", .sql), ("scala", .scala), ("lua", .lua),
            ("xyz", .unknown)
        ]
        for (ext, expected) in cases {
            XCTAssertEqual(Language.detect(from: ext), expected, "Failed for extension: \(ext)")
        }
    }

    func testHighlightEmptyStringAllLanguages() {
        let highlighter = SyntaxHighlighter(theme: .dark)
        for lang in [Language.swift, .python, .rust, .javascript, .go, .kotlin] {
            let tokens = highlighter.highlight("", language: lang)
            XCTAssertTrue(tokens.isEmpty, "Empty string should produce no tokens for \(lang)")
        }
    }

    func testHighlightUnknownLanguageReturnsEmpty() {
        let highlighter = SyntaxHighlighter(theme: .dark)
        let tokens = highlighter.highlight("some code", language: .unknown)
        XCTAssertTrue(tokens.isEmpty)
    }

    func testSwiftHighlightingHasKeywordTokens() {
        let highlighter = SyntaxHighlighter(theme: .dark)
        let tokens = highlighter.highlight("import SwiftUI\nstruct MyView: View {}", language: .swift)
        XCTAssertFalse(tokens.isEmpty)
        // Should have tokens for import, struct keywords
        XCTAssertGreaterThanOrEqual(tokens.count, 2)
    }
}

// MARK: - Performance

final class PerformanceTests: XCTestCase {
    func testHighlightPerformance1000Lines() {
        let lines = (0..<1000).map { "let variable\($0): String = \"value\($0)\"" }
        let code = lines.joined(separator: "\n")
        let highlighter = SyntaxHighlighter(theme: .dark)
        measure {
            let _ = highlighter.highlight(code, language: .swift)
        }
    }

    @MainActor func testFindSearchPerformance10kChars() {
        let text = String(repeating: "hello world foo bar baz\n", count: 435)
        let find = FindState()
        find.query = "foo"
        measure {
            let _ = find.search(in: text)
        }
    }

    func testFileNodeFilterPerformance() {
        let root = FileNode.sampleRoot()
        measure {
            let _ = root.filtered(by: "swift")
        }
    }
}
