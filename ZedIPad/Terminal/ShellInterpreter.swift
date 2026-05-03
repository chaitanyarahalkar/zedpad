import Foundation

// ANSI color helpers
enum ANSI {
    static func color(_ code: Int, _ text: String) -> String { "\u{1B}[\(code)m\(text)\u{1B}[0m" }
    static func bold(_ text: String) -> String { "\u{1B}[1m\(text)\u{1B}[0m" }
    static let reset = "\u{1B}[0m"
    // Foreground colors
    static func black(_ s: String) -> String { color(30, s) }
    static func red(_ s: String) -> String { color(31, s) }
    static func green(_ s: String) -> String { color(32, s) }
    static func yellow(_ s: String) -> String { color(33, s) }
    static func blue(_ s: String) -> String { color(34, s) }
    static func magenta(_ s: String) -> String { color(35, s) }
    static func cyan(_ s: String) -> String { color(36, s) }
    static func white(_ s: String) -> String { color(37, s) }
    static func grey(_ s: String) -> String { color(90, s) }
}

@MainActor
class ShellInterpreter: ObservableObject {
    @Published var cwd: URL
    private var history: [String] = []
    private var historyIndex: Int = -1
    private let fm = FileManager.default

    private var docsRoot: URL {
        fm.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: "/")
    }

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: "/")
        self.cwd = docs
    }

    // Main entry point
    func execute(_ line: String) -> String {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return "" }

        // History
        if trimmed != history.last {
            history.append(trimmed)
        }
        historyIndex = -1

        // Handle !! (repeat last command)
        if trimmed == "!!" {
            guard history.count >= 2 else { return ANSI.red("zsh: no previous command") }
            return execute(history[history.count - 2])
        }

        let parts = parseArgs(trimmed)
        guard let cmd = parts.first else { return "" }
        let args = Array(parts.dropFirst())

        // Output redirection
        if let redirectIdx = parts.firstIndex(of: ">") {
            return handleRedirect(parts: parts, append: false)
        }
        if let redirectIdx = parts.firstIndex(of: ">>") {
            return handleRedirect(parts: parts, append: true)
        }

        switch cmd {
        case "ls":           return cmdLs(args)
        case "cd":           return cmdCd(args)
        case "pwd":          return cwd.path
        case "cat":          return cmdCat(args)
        case "echo":         return args.joined(separator: " ")
        case "mkdir":        return cmdMkdir(args)
        case "rm":           return cmdRm(args)
        case "mv":           return cmdMv(args)
        case "cp":           return cmdCp(args)
        case "touch":        return cmdTouch(args)
        case "clear":        return "\u{1B}[2J\u{1B}[H"
        case "history":      return history.enumerated().map { "  \(ANSI.grey("\($0.offset + 1)"))\t\($0.element)" }.joined(separator: "\n")
        case "grep":         return cmdGrep(args)
        case "find":         return cmdFind(args)
        case "wc":           return cmdWc(args)
        case "head":         return cmdHeadTail(args, head: true)
        case "tail":         return cmdHeadTail(args, head: false)
        case "open":         return cmdOpen(args)
        case "git":          return cmdGit(args)
        case "ssh":          return cmdSSH(args)
        case "help":         return helpText
        case "exit", "quit": return "__EXIT__"
        default:
            return ANSI.red("\(cmd): command not found") + "\n" + ANSI.grey("Type 'help' to see available commands.")
        }
    }

    // MARK: - Commands

    private func cmdLs(_ args: [String]) -> String {
        let longFormat = args.contains("-l") || args.contains("-la") || args.contains("-al")
        let showHidden = args.contains("-a") || args.contains("-la") || args.contains("-al")
        let targetArg = args.filter { !$0.hasPrefix("-") }.first
        let targetURL = targetArg.map { resolve($0) } ?? cwd

        guard let items = try? fm.contentsOfDirectory(at: targetURL, includingPropertiesForKeys: [
            .isDirectoryKey, .fileSizeKey, .contentModificationDateKey, .isHiddenKey
        ]) else {
            return ANSI.red("ls: \(targetURL.lastPathComponent): No such file or directory")
        }

        var entries = items.filter { showHidden || !$0.lastPathComponent.hasPrefix(".") }
        entries.sort { $0.lastPathComponent < $1.lastPathComponent }

        if longFormat {
            return entries.map { url -> String in
                let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                let date = (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date()
                let dateStr = DateFormatter.shortDate.string(from: date)
                let sizeStr = formatSize(size)
                let name = isDir ? ANSI.blue(url.lastPathComponent + "/") : url.lastPathComponent
                let prefix = isDir ? "d" : "-"
                return "\(prefix)rw-r--r--  \(ANSI.grey(sizeStr.padLeft(8)))  \(ANSI.grey(dateStr))  \(name)"
            }.joined(separator: "\n")
        } else {
            return entries.map { url -> String in
                let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                return isDir ? ANSI.blue(url.lastPathComponent + "/") : url.lastPathComponent
            }.joined(separator: "  ")
        }
    }

    private func cmdCd(_ args: [String]) -> String {
        if args.isEmpty {
            cwd = canonicalDirectoryURL(docsRoot)
            return ""
        }
        let target = args[0]
        let newURL = canonicalDirectoryURL(target == ".." ? cwd.deletingLastPathComponent() : resolve(target))
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: newURL.path, isDirectory: &isDir), isDir.boolValue else {
            return ANSI.red("cd: \(target): No such file or directory")
        }
        cwd = newURL
        return ""
    }

    private func cmdCat(_ args: [String]) -> String {
        guard let file = args.first else { return ANSI.red("cat: missing operand") }
        let url = resolve(file)
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            return ANSI.red("cat: \(file): No such file or directory")
        }
        return content
    }

    private func cmdMkdir(_ args: [String]) -> String {
        let targets = args.filter { !$0.hasPrefix("-") }
        guard let name = targets.first else { return ANSI.red("mkdir: missing operand") }
        let url = resolve(name)
        let createParents = args.contains("-p")
        do {
            try fm.createDirectory(at: url, withIntermediateDirectories: createParents)
            return ""
        } catch {
            return ANSI.red("mkdir: \(name): \(error.localizedDescription)")
        }
    }

    private func cmdRm(_ args: [String]) -> String {
        let flags = args.filter { $0.hasPrefix("-") }
        let targets = args.filter { !$0.hasPrefix("-") }
        guard !targets.isEmpty else { return ANSI.red("rm: missing operand") }
        var output: [String] = []
        for t in targets {
            let url = resolve(t)
            do {
                try fm.removeItem(at: url)
            } catch {
                output.append(ANSI.red("rm: \(t): \(error.localizedDescription)"))
            }
        }
        return output.joined(separator: "\n")
    }

    private func cmdMv(_ args: [String]) -> String {
        guard args.count >= 2 else { return ANSI.red("mv: missing operand") }
        let src = resolve(args[0])
        let dst = resolve(args[1])
        do {
            try fm.moveItem(at: src, to: dst)
            return ""
        } catch {
            return ANSI.red("mv: \(error.localizedDescription)")
        }
    }

    private func cmdCp(_ args: [String]) -> String {
        guard args.count >= 2 else { return ANSI.red("cp: missing operand") }
        let src = resolve(args[0])
        let dst = resolve(args[1])
        do {
            try fm.copyItem(at: src, to: dst)
            return ""
        } catch {
            return ANSI.red("cp: \(error.localizedDescription)")
        }
    }

    private func cmdTouch(_ args: [String]) -> String {
        guard !args.isEmpty else { return ANSI.red("touch: missing operand") }
        var output: [String] = []
        for name in args {
            let url = resolve(name)
            if fm.fileExists(atPath: url.path) {
                // update modification date
                try? fm.setAttributes([.modificationDate: Date()], ofItemAtPath: url.path)
            } else {
                fm.createFile(atPath: url.path, contents: Data())
            }
        }
        return output.joined(separator: "\n")
    }

    private func cmdGrep(_ args: [String]) -> String {
        let ignoreCase = args.contains("-i")
        let lineNumbers = args.contains("-n")
        let targets = args.filter { !$0.hasPrefix("-") }
        guard targets.count >= 2 else { return ANSI.red("grep: usage: grep [flags] pattern file") }
        let pattern = targets[0]
        let file = targets[1]
        let url = resolve(file)
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            return ANSI.red("grep: \(file): No such file or directory")
        }
        let lines = content.components(separatedBy: "\n")
        let matched = lines.enumerated().filter {
            ignoreCase ? $0.element.localizedCaseInsensitiveContains(pattern) : $0.element.contains(pattern)
        }
        if matched.isEmpty { return "" }
        return matched.map { idx, line -> String in
            let highlighted = ignoreCase
                ? line
                : line.replacingOccurrences(of: pattern, with: ANSI.red(ANSI.bold(pattern)))
            return lineNumbers ? "\(ANSI.grey("\(idx+1)")):\(highlighted)" : highlighted
        }.joined(separator: "\n")
    }

    private func cmdFind(_ args: [String]) -> String {
        let nameArg = args.firstIndex(of: "-name").map { idx -> String? in
            idx + 1 < args.count ? args[idx + 1] : nil
        } ?? nil
        let searchDir = args.first(where: { !$0.hasPrefix("-") && $0 != nameArg }).map { resolve($0) } ?? cwd
        guard let enumerator = fm.enumerator(at: searchDir, includingPropertiesForKeys: nil) else {
            return ANSI.red("find: \(searchDir.path): No such file or directory")
        }
        var results: [String] = []
        for case let url as URL in enumerator {
            if let pattern = nameArg {
                let cleanPattern = pattern.trimmingCharacters(in: CharacterSet(charactersIn: "*"))
                if url.lastPathComponent.contains(cleanPattern) {
                    results.append(url.path)
                }
            } else {
                results.append(url.path)
            }
        }
        return results.isEmpty ? "" : results.joined(separator: "\n")
    }

    private func cmdWc(_ args: [String]) -> String {
        guard let file = args.last, !file.hasPrefix("-") else { return ANSI.red("wc: missing operand") }
        let url = resolve(file)
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            return ANSI.red("wc: \(file): No such file or directory")
        }
        let lines = content.components(separatedBy: "\n").count
        let words = content.components(separatedBy: .whitespaces).filter { !$0.isEmpty }.count
        let chars = content.count
        return "\(ANSI.cyan("\(lines)"))\t\(ANSI.cyan("\(words)"))\t\(ANSI.cyan("\(chars)"))\t\(file)"
    }

    private func cmdHeadTail(_ args: [String], head: Bool) -> String {
        var n = 10
        var file: String?
        var i = 0
        while i < args.count {
            if args[i] == "-n", i + 1 < args.count {
                n = Int(args[i+1]) ?? 10; i += 2
            } else {
                file = args[i]; i += 1
            }
        }
        guard let f = file else { return ANSI.red("\(head ? "head" : "tail"): missing operand") }
        let url = resolve(f)
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            return ANSI.red("\(head ? "head" : "tail"): \(f): No such file or directory")
        }
        let lines = content.components(separatedBy: "\n")
        let selected = head ? Array(lines.prefix(n)) : Array(lines.suffix(n))
        return selected.joined(separator: "\n")
    }

    private func cmdGit(_ args: [String]) -> String {
        let git = GitService(repoURL: cwd)
        return git.handleGitCommand(args)
    }

    private func cmdSSH(_ args: [String]) -> String {
        guard let target = args.first else { return ANSI.red("ssh: missing host argument") }
        return "__SSH__:\(target)"
    }

    private func cmdOpen(_ args: [String]) -> String {
        guard let file = args.first else { return ANSI.red("open: missing operand") }
        // Returns a special marker that the terminal panel can intercept
        return "__OPEN__:\(resolve(file).path)"
    }

    // MARK: - Redirection

    private func handleRedirect(parts: [String], append: Bool) -> String {
        let op = append ? ">>" : ">"
        guard let idx = parts.firstIndex(of: op), idx > 0, idx + 1 < parts.count else {
            return ANSI.red("syntax error near unexpected token '\(op)'")
        }
        let cmdParts = Array(parts[0..<idx])
        let destFile = parts[idx + 1]
        let output = execute(cmdParts.joined(separator: " "))
        let url = resolve(destFile)
        if append {
            let existing = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
            try? (existing + output + "\n").write(to: url, atomically: true, encoding: .utf8)
        } else {
            try? (output + "\n").write(to: url, atomically: true, encoding: .utf8)
        }
        return ""
    }

    // MARK: - History navigation

    func historyUp() -> String? {
        guard !history.isEmpty else { return nil }
        if historyIndex == -1 { historyIndex = history.count - 1 }
        else if historyIndex > 0 { historyIndex -= 1 }
        return history[historyIndex]
    }

    func historyDown() -> String? {
        guard historyIndex >= 0 else { return nil }
        historyIndex += 1
        if historyIndex >= history.count { historyIndex = -1; return "" }
        return history[historyIndex]
    }

    // MARK: - Tab completion

    func complete(_ prefix: String) -> [String] {
        let parts = prefix.components(separatedBy: " ")
        let lastPart = parts.last ?? ""
        let baseURL = lastPart.contains("/")
            ? resolve(String(lastPart.prefix(while: { $0 != "/" })))
            : cwd
        guard let items = try? fm.contentsOfDirectory(at: baseURL, includingPropertiesForKeys: [.isDirectoryKey]) else {
            return []
        }
        let fileName = lastPart.contains("/") ? String(lastPart.split(separator: "/").last ?? "") : lastPart
        return items.filter { $0.lastPathComponent.hasPrefix(fileName) }.map { url in
            let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            return url.lastPathComponent + (isDir ? "/" : "")
        }
    }

    // MARK: - Helpers

    func resolve(_ path: String) -> URL {
        if path.hasPrefix("/") { return URL(fileURLWithPath: URL(fileURLWithPath: path).standardized.path) }
        if path == "~" { return canonicalDirectoryURL(docsRoot) }
        if path.hasPrefix("~/") { return URL(fileURLWithPath: docsRoot.appendingPathComponent(String(path.dropFirst(2))).standardized.path) }
        return URL(fileURLWithPath: cwd.appendingPathComponent(path).standardized.path)
    }

    private func canonicalDirectoryURL(_ url: URL) -> URL {
        URL(fileURLWithPath: url.standardized.path)
    }

    func prompt() -> String {
        let home = docsRoot.path
        let path = cwd.path.hasPrefix(home)
            ? "~" + cwd.path.dropFirst(home.count)
            : cwd.path
        return "\(ANSI.green(path)) \(ANSI.grey("$")) "
    }

    private func parseArgs(_ line: String) -> [String] {
        var args: [String] = []
        var current = ""
        var inQuote = false
        var quoteChar: Character = "\""
        for ch in line {
            if inQuote {
                if ch == quoteChar { inQuote = false } else { current.append(ch) }
            } else if ch == "\"" || ch == "'" {
                inQuote = true; quoteChar = ch
            } else if ch == " " {
                if !current.isEmpty { args.append(current); current = "" }
            } else {
                current.append(ch)
            }
        }
        if !current.isEmpty { args.append(current) }
        return args
    }

    private func formatSize(_ bytes: Int?) -> String {
        guard let b = bytes else { return "-" }
        if b < 1024 { return "\(b)B" }
        if b < 1024 * 1024 { return "\(b / 1024)K" }
        return "\(b / (1024*1024))M"
    }

    private var helpText: String {
        let cmds = [
            ("ls [-l] [-a]", "list directory contents"),
            ("cd [dir]",     "change directory"),
            ("pwd",          "print working directory"),
            ("cat <file>",   "print file contents"),
            ("echo <text>",  "print text (supports > and >>)"),
            ("mkdir <dir>",  "create directory"),
            ("rm [-rf] <file>", "remove file/directory"),
            ("mv <src> <dst>",  "move/rename"),
            ("cp <src> <dst>",  "copy"),
            ("touch <file>",    "create/update file"),
            ("grep [-i] [-n] <pat> <file>", "search in file"),
            ("find [dir] [-name <pat>]",    "find files"),
            ("wc <file>",       "word count"),
            ("head/tail [-n N] <file>", "first/last lines"),
            ("open <file>",     "open file in editor"),
            ("history",         "command history"),
            ("clear",           "clear terminal"),
            ("help",            "show this help"),
            ("git <cmd>",       "git operations"),
            ("ssh <user@host>", "SSH to remote server"),
        ]
        let header = ANSI.bold(ANSI.cyan("ZedIPad Shell")) + " — available commands:\n"
        return header + cmds.map { "  \(ANSI.green($0.0.padRight(32))) \(ANSI.grey($0.1))" }.joined(separator: "\n")
    }
}

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "MMM dd HH:mm"
        return df
    }()
}

extension String {
    func padLeft(_ n: Int) -> String {
        count >= n ? self : String(repeating: " ", count: n - count) + self
    }
    func padRight(_ n: Int) -> String {
        count >= n ? self : self + String(repeating: " ", count: n - count)
    }
}
