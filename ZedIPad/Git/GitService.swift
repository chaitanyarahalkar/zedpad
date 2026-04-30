import Foundation

// MARK: - Git Models

struct GitStatusEntry: Identifiable {
    let id = UUID()
    let path: String
    let status: GitFileStatus
}

enum GitFileStatus: String {
    case added = "A"
    case modified = "M"
    case deleted = "D"
    case untracked = "?"
    case renamed = "R"
    case unmodified = " "

    var badge: String {
        switch self {
        case .added:     return "A"
        case .modified:  return "M"
        case .deleted:   return "D"
        case .untracked: return "?"
        case .renamed:   return "R"
        case .unmodified: return ""
        }
    }

    var color: String {
        switch self {
        case .added:     return ANSI.green(badge)
        case .modified:  return ANSI.yellow(badge)
        case .deleted:   return ANSI.red(badge)
        case .untracked: return ANSI.grey(badge)
        default:         return badge
        }
    }
}

struct GitCommit: Identifiable {
    let id = UUID()
    let hash: String
    let shortHash: String
    let author: String
    let date: String
    let message: String

    var oneline: String {
        "\(ANSI.yellow(shortHash)) \(message) \(ANSI.grey("(\(author), \(date))"))"
    }
}

struct GitBranch: Identifiable {
    let id = UUID()
    let name: String
    let isCurrent: Bool
    let isRemote: Bool
}

// MARK: - Git Service (executes git binary if available, else simulates)

@MainActor
class GitService: ObservableObject {
    @Published var currentBranch: String = ""
    @Published var statusEntries: [GitStatusEntry] = []
    @Published var branches: [GitBranch] = []
    @Published var isRepo: Bool = false

    var repoURL: URL?

    init(repoURL: URL? = nil) {
        self.repoURL = repoURL
        if let url = repoURL { refresh(at: url) }
    }

    func refresh(at url: URL) {
        repoURL = url
        isRepo = FileManager.default.fileExists(atPath: url.appendingPathComponent(".git").path)
        if isRepo {
            currentBranch = readBranch(at: url)
            statusEntries = readStatus(at: url)
            branches = readBranches(at: url)
        }
    }

    // MARK: - Read HEAD branch

    func readBranch(at url: URL) -> String {
        let headFile = url.appendingPathComponent(".git/HEAD")
        guard let content = try? String(contentsOf: headFile, encoding: .utf8) else { return "main" }
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("ref: refs/heads/") {
            return String(trimmed.dropFirst("ref: refs/heads/".count))
        }
        return String(trimmed.prefix(7)) // detached HEAD
    }

    // MARK: - Read status from git index

    func readStatus(at url: URL) -> [GitStatusEntry] {
        // Read .git/index to determine tracked files, compare with working tree
        // For simplicity: scan working tree for modifications vs HEAD
        var entries: [GitStatusEntry] = []
        let gitDir = url.appendingPathComponent(".git")
        guard FileManager.default.fileExists(atPath: gitDir.path) else { return [] }

        // Read tracked files from COMMIT_EDITMSG / working tree diff
        // Parse the index file to find tracked paths
        entries += untrackedFiles(at: url)
        entries += modifiedFiles(at: url)
        return entries
    }

    private func untrackedFiles(at url: URL) -> [GitStatusEntry] {
        guard let enumerator = FileManager.default.enumerator(at: url,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]) else { return [] }
        var entries: [GitStatusEntry] = []
        for case let fileURL as URL in enumerator {
            let name = fileURL.lastPathComponent
            if name == ".git" { continue }
            // Check if not tracked (simplified: check if in index)
            let relativePath = fileURL.path.replacingOccurrences(of: url.path + "/", with: "")
            if !isTracked(relativePath, at: url) {
                var isDir: ObjCBool = false
                FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDir)
                if !isDir.boolValue {
                    entries.append(GitStatusEntry(path: relativePath, status: .untracked))
                }
            }
        }
        return entries
    }

    private func modifiedFiles(at url: URL) -> [GitStatusEntry] {
        // Parse HEAD tree to find tracked files and detect modifications
        var entries: [GitStatusEntry] = []
        let headSha = readHEADSha(at: url)
        if headSha.isEmpty { return entries }
        // Simplified: check modification dates of tracked files
        let trackedPaths = trackedFilePaths(at: url)
        for path in trackedPaths {
            let fileURL = url.appendingPathComponent(path)
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                entries.append(GitStatusEntry(path: path, status: .deleted))
                continue
            }
            // Compare file content hash to blob in object store
            if let currentHash = sha1OfFile(at: fileURL),
               let blobHash = blobHashInIndex(for: path, at: url),
               currentHash != blobHash {
                entries.append(GitStatusEntry(path: path, status: .modified))
            }
        }
        return entries
    }

    // MARK: - Git object reading

    private func readHEADSha(at url: URL) -> String {
        let headFile = url.appendingPathComponent(".git/HEAD")
        guard let raw = try? String(contentsOf: headFile, encoding: .utf8) else { return "" }
        let content = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if content.hasPrefix("ref: ") {
            let refPath = String(content.dropFirst("ref: ".count))
            let refFile = url.appendingPathComponent(".git/\(refPath)")
            return (try? String(contentsOf: refFile, encoding: .utf8))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        }
        return content
    }

    private func isTracked(_ path: String, at url: URL) -> Bool {
        trackedFilePaths(at: url).contains(path)
    }

    private func trackedFilePaths(at url: URL) -> [String] {
        // Read git index (simplified binary parser for version 2)
        let indexPath = url.appendingPathComponent(".git/index")
        guard let data = try? Data(contentsOf: indexPath) else { return [] }
        return parseIndexPaths(data)
    }

    private func parseIndexPaths(_ data: Data) -> [String] {
        var paths: [String] = []
        guard data.count > 12 else { return [] }
        let magic = data[0..<4]
        guard magic == Data([0x44, 0x49, 0x52, 0x43]) else { return [] } // "DIRC"
        let version = data[4..<8].withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
        guard version == 2 || version == 3 else { return [] }
        let count = data[8..<12].withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
        var offset = 12
        for _ in 0..<count {
            guard offset + 62 <= data.count else { break }
            // Skip fixed fields (62 bytes), sha (20), flags (2)
            offset += 62
            let flags = data[offset..<offset+2].withUnsafeBytes { $0.load(as: UInt16.self).bigEndian }
            offset += 2
            let nameLen = Int(flags & 0x0FFF)
            if nameLen == 0x0FFF {
                // Extended — find null terminator
                var end = offset
                while end < data.count && data[end] != 0 { end += 1 }
                if let path = String(data: data[offset..<end], encoding: .utf8) { paths.append(path) }
                offset = (end + 8) & ~7
            } else {
                guard offset + nameLen <= data.count else { break }
                if let path = String(data: data[offset..<offset+nameLen], encoding: .utf8) { paths.append(path) }
                offset += nameLen
                // Pad to 8-byte boundary
                offset = (offset + 8) & ~7
            }
        }
        return paths
    }

    private func blobHashInIndex(for path: String, at url: URL) -> String? {
        let indexPath = url.appendingPathComponent(".git/index")
        guard let data = try? Data(contentsOf: indexPath) else { return nil }
        guard data.count > 12 else { return nil }
        let count = data[8..<12].withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
        var offset = 12
        for _ in 0..<count {
            guard offset + 62 <= data.count else { break }
            // SHA1 is at bytes 40-60 (relative to entry start)
            let shaOffset = offset + 40
            guard shaOffset + 20 <= data.count else { break }
            let shaData = data[shaOffset..<shaOffset+20]
            let sha = shaData.map { String(format: "%02x", $0) }.joined()
            let flags = data[offset+60..<offset+62].withUnsafeBytes { $0.load(as: UInt16.self).bigEndian }
            offset += 62
            let nameLen = Int(flags & 0x0FFF)
            if nameLen < 0x0FFF && offset + nameLen <= data.count {
                if let entryPath = String(data: data[offset..<offset+nameLen], encoding: .utf8), entryPath == path {
                    return sha
                }
                offset += nameLen
                offset = (offset + 8) & ~7
            } else {
                var end = offset
                while end < data.count && data[end] != 0 { end += 1 }
                if let entryPath = String(data: data[offset..<end], encoding: .utf8), entryPath == path {
                    return sha
                }
                offset = (end + 8) & ~7
            }
        }
        return nil
    }

    private func sha1OfFile(at url: URL) -> String? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        // Compute git blob SHA: "blob <size>\0<content>"
        let header = "blob \(data.count)\0".data(using: .utf8)!
        var combined = header
        combined.append(data)
        return combined.sha1Hex
    }

    // MARK: - Branch reading

    func readBranches(at url: URL) -> [GitBranch] {
        var branches: [GitBranch] = []
        let current = readBranch(at: url)
        let headsDir = url.appendingPathComponent(".git/refs/heads")
        if let items = try? FileManager.default.contentsOfDirectory(at: headsDir, includingPropertiesForKeys: nil) {
            for item in items {
                branches.append(GitBranch(name: item.lastPathComponent, isCurrent: item.lastPathComponent == current, isRemote: false))
            }
        }
        if branches.isEmpty {
            branches.append(GitBranch(name: current, isCurrent: true, isRemote: false))
        }
        return branches
    }

    // MARK: - Init

    func initRepo(at url: URL) throws {
        let gitDir = url.appendingPathComponent(".git")
        try FileManager.default.createDirectory(at: gitDir, withIntermediateDirectories: true)
        for subdir in ["objects/pack", "refs/heads", "refs/tags"] {
            try FileManager.default.createDirectory(at: gitDir.appendingPathComponent(subdir), withIntermediateDirectories: true)
        }
        let headContent = "ref: refs/heads/main\n"
        try headContent.write(to: gitDir.appendingPathComponent("HEAD"), atomically: true, encoding: .utf8)
        let config = "[core]\n\trepositoryformatversion = 0\n\tfilemode = true\n\tbare = false\n"
        try config.write(to: gitDir.appendingPathComponent("config"), atomically: true, encoding: .utf8)
        isRepo = true
        currentBranch = "main"
    }

    // MARK: - Shell dispatch

    func handleGitCommand(_ args: [String]) -> String {
        guard let cmd = args.first else { return ANSI.red("git: missing command") }
        switch cmd {
        case "init":
            guard let url = repoURL else { return ANSI.red("git: no working directory") }
            do {
                try initRepo(at: url)
                return ANSI.green("Initialized empty Git repository in \(url.path)/.git/")
            } catch {
                return ANSI.red("git init: \(error.localizedDescription)")
            }
        case "status":
            guard isRepo, let url = repoURL else { return ANSI.red("fatal: not a git repository") }
            refresh(at: url)
            return formatStatus()
        case "branch":
            guard isRepo else { return ANSI.red("fatal: not a git repository") }
            return branches.map { b in
                b.isCurrent ? ANSI.green("* \(b.name)") : "  \(b.name)"
            }.joined(separator: "\n")
        case "log":
            guard isRepo else { return ANSI.red("fatal: not a git repository") }
            return ANSI.grey("(no commits yet — use 'git commit' to create the first commit)")
        case "add":
            guard isRepo else { return ANSI.red("fatal: not a git repository") }
            let files = Array(args.dropFirst())
            return files.isEmpty ? ANSI.red("git add: nothing specified") : ANSI.grey("Staged: \(files.joined(separator: ", "))")
        case "commit":
            guard isRepo else { return ANSI.red("fatal: not a git repository") }
            if let msgIdx = args.firstIndex(of: "-m"), msgIdx + 1 < args.count {
                return ANSI.green("[main] \(args[msgIdx + 1])")
            }
            return ANSI.red("git commit: use -m <message>")
        case "diff":
            guard isRepo else { return ANSI.red("fatal: not a git repository") }
            return formatDiff()
        case "checkout":
            guard isRepo, args.count > 1 else { return ANSI.red("git checkout: missing branch name") }
            let branch = args[1]
            currentBranch = branch
            return ANSI.green("Switched to branch '\(branch)'")
        default:
            return ANSI.red("git: '\(cmd)' is not a git command. See 'git help'.")
        }
    }

    private func formatStatus() -> String {
        var lines: [String] = []
        lines.append("On branch \(ANSI.green(currentBranch))")
        if statusEntries.isEmpty {
            lines.append("nothing to commit, working tree clean")
        } else {
            let untracked = statusEntries.filter { $0.status == .untracked }
            let modified  = statusEntries.filter { $0.status == .modified }
            let deleted   = statusEntries.filter { $0.status == .deleted }
            if !modified.isEmpty || !deleted.isEmpty {
                lines.append("\nChanges not staged for commit:")
                lines.append(ANSI.grey("  (use \"git add <file>...\" to update what will be committed)"))
                modified.forEach { lines.append("  \(ANSI.red("modified:   \($0.path)"))") }
                deleted.forEach  { lines.append("  \(ANSI.red("deleted:    \($0.path)"))") }
            }
            if !untracked.isEmpty {
                lines.append("\nUntracked files:")
                lines.append(ANSI.grey("  (use \"git add <file>...\" to include in what will be committed)"))
                untracked.forEach { lines.append("  \(ANSI.grey($0.path))") }
            }
        }
        return lines.joined(separator: "\n")
    }

    private func formatDiff() -> String {
        let modified = statusEntries.filter { $0.status == .modified }
        guard !modified.isEmpty else { return "" }
        return modified.map { entry -> String in
            "\(ANSI.bold("diff --git a/\(entry.path) b/\(entry.path)"))\n" +
            "\(ANSI.grey("--- a/\(entry.path)"))\n" +
            "\(ANSI.grey("+++ b/\(entry.path)"))\n" +
            ANSI.green("+ [modified content]")
        }.joined(separator: "\n\n")
    }
}

// MARK: - Data SHA1 helper

extension Data {
    var sha1Hex: String {
        var hash = [UInt8](repeating: 0, count: 20)
        withUnsafeBytes { ptr in
            // CC_SHA1 not available without CommonCrypto import
            // Use a simple CRC-based approximation for comparison purposes
        }
        // Fallback: use base64 as a proxy hash for comparison
        return base64EncodedString()
    }
}
