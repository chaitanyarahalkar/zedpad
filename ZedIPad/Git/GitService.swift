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

private struct StoredGitState: Codable {
    var commits: [StoredGitCommit] = []
    var stagedPaths: [String] = []
}

private struct StoredGitCommit: Codable {
    let hash: String
    let parentHash: String?
    let branch: String
    let author: String
    let date: String
    let message: String
    let snapshot: [String: String]
}

private struct GitStatusBuckets {
    var staged: [GitStatusEntry] = []
    var unstaged: [GitStatusEntry] = []
    var untracked: [GitStatusEntry] = []

    var all: [GitStatusEntry] {
        staged + unstaged + untracked
    }
}

// MARK: - Git Service (lightweight filesystem-backed Git simulator)

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

    // MARK: - Read status

    func readStatus(at url: URL) -> [GitStatusEntry] {
        statusBuckets(at: url).all
    }

    private func statusBuckets(at url: URL) -> GitStatusBuckets {
        let state = loadState(at: url)
        let staged = Set(state.stagedPaths)
        let headSnapshot = headCommit(at: url, in: state)?.snapshot ?? [:]
        let workingSnapshot = workingTreeSnapshot(at: url)
        let trackedPaths = Set(headSnapshot.keys)
        let workingPaths = Set(workingSnapshot.keys)
        let changedPaths = trackedPaths.union(workingPaths).sorted()
        var buckets = GitStatusBuckets()

        for path in changedPaths {
            let headContent = headSnapshot[path]
            let workingContent = workingSnapshot[path]
            let status: GitFileStatus?
            if headContent == nil, workingContent != nil {
                status = .untracked
            } else if headContent != nil, workingContent == nil {
                status = .deleted
            } else if headContent != workingContent {
                status = .modified
            } else {
                status = nil
            }

            guard let status else { continue }
            let entry = GitStatusEntry(path: path, status: status == .untracked && staged.contains(path) ? .added : status)
            if staged.contains(path) {
                buckets.staged.append(entry)
            } else if status == .untracked {
                buckets.untracked.append(entry)
            } else {
                buckets.unstaged.append(entry)
            }
        }

        return buckets
    }

    private func untrackedFiles(at url: URL) -> [GitStatusEntry] {
        guard let enumerator = FileManager.default.enumerator(at: url,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]) else { return [] }
        var entries: [GitStatusEntry] = []
        for case let fileURL as URL in enumerator {
            let name = fileURL.lastPathComponent
            if name == ".git" {
                enumerator.skipDescendants()
                continue
            }
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
        let state = loadState(at: url)
        if let commit = headCommit(at: url, in: state) {
            return Array(commit.snapshot.keys).sorted()
        }

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
        for subdir in ["objects/pack", "refs/heads", "refs/tags", "zedipad"] {
            try FileManager.default.createDirectory(at: gitDir.appendingPathComponent(subdir), withIntermediateDirectories: true)
        }
        let headContent = "ref: refs/heads/main\n"
        try headContent.write(to: gitDir.appendingPathComponent("HEAD"), atomically: true, encoding: .utf8)
        try "".write(to: gitDir.appendingPathComponent("refs/heads/main"), atomically: true, encoding: .utf8)
        let config = "[core]\n\trepositoryformatversion = 0\n\tfilemode = true\n\tbare = false\n"
        try config.write(to: gitDir.appendingPathComponent("config"), atomically: true, encoding: .utf8)
        try saveState(StoredGitState(), at: url)
        isRepo = true
        currentBranch = "main"
        branches = [GitBranch(name: "main", isCurrent: true, isRemote: false)]
        statusEntries = readStatus(at: url)
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
            guard isRepo, let url = repoURL else { return ANSI.red("fatal: not a git repository") }
            refresh(at: url)
            return branches.map { b in
                b.isCurrent ? ANSI.green("* \(b.name)") : "  \(b.name)"
            }.joined(separator: "\n")
        case "log":
            guard isRepo, let url = repoURL else { return ANSI.red("fatal: not a git repository") }
            return formatLog(at: url)
        case "add":
            guard isRepo, let url = repoURL else { return ANSI.red("fatal: not a git repository") }
            let files = Array(args.dropFirst())
            return stage(files, at: url)
        case "commit":
            guard isRepo, let url = repoURL else { return ANSI.red("fatal: not a git repository") }
            if let msgIdx = args.firstIndex(of: "-m"), msgIdx + 1 < args.count {
                return commit(message: args[msgIdx + 1], at: url)
            }
            return ANSI.red("git commit: use -m <message>")
        case "diff":
            guard isRepo, let url = repoURL else { return ANSI.red("fatal: not a git repository") }
            refresh(at: url)
            return formatDiff(at: url)
        case "checkout":
            guard isRepo, let url = repoURL, args.count > 1 else { return ANSI.red("git checkout: missing branch name") }
            return checkout(branch: args[1], at: url)
        default:
            return ANSI.red("git: '\(cmd)' is not a git command. See 'git help'.")
        }
    }

    private func formatStatus() -> String {
        guard let url = repoURL else { return ANSI.red("fatal: not a git repository") }
        let buckets = statusBuckets(at: url)
        var lines: [String] = []
        lines.append("On branch \(ANSI.green(currentBranch))")
        if buckets.all.isEmpty {
            lines.append("nothing to commit, working tree clean")
        } else {
            if !buckets.staged.isEmpty {
                lines.append("\nChanges to be committed:")
                lines.append(ANSI.grey("  (use \"git reset <file>...\" to unstage)"))
                buckets.staged.forEach { entry in
                    lines.append("  \(ANSI.green("\(statusLabel(entry.status)):   \(entry.path)"))")
                }
            }
            if !buckets.unstaged.isEmpty {
                lines.append("\nChanges not staged for commit:")
                lines.append(ANSI.grey("  (use \"git add <file>...\" to update what will be committed)"))
                buckets.unstaged.forEach { entry in
                    lines.append("  \(ANSI.red("\(statusLabel(entry.status)):   \(entry.path)"))")
                }
            }
            if !buckets.untracked.isEmpty {
                lines.append("\nUntracked files:")
                lines.append(ANSI.grey("  (use \"git add <file>...\" to include in what will be committed)"))
                buckets.untracked.forEach { lines.append("  \(ANSI.grey($0.path))") }
            }
        }
        return lines.joined(separator: "\n")
    }

    private func statusLabel(_ status: GitFileStatus) -> String {
        switch status {
        case .added: return "new file"
        case .modified: return "modified"
        case .deleted: return "deleted"
        case .untracked: return "new file"
        case .renamed: return "renamed"
        case .unmodified: return "unmodified"
        }
    }

    private func formatDiff(at url: URL) -> String {
        let buckets = statusBuckets(at: url)
        guard !buckets.unstaged.isEmpty else { return "" }
        let state = loadState(at: url)
        let headSnapshot = headCommit(at: url, in: state)?.snapshot ?? [:]
        let workingSnapshot = workingTreeSnapshot(at: url)
        return buckets.unstaged.map { entry -> String in
            let oldText = headSnapshot[entry.path].flatMap { Data(base64Encoded: $0) }.flatMap { String(data: $0, encoding: .utf8) } ?? ""
            let newText = workingSnapshot[entry.path].flatMap { Data(base64Encoded: $0) }.flatMap { String(data: $0, encoding: .utf8) } ?? ""
            return "\(ANSI.bold("diff --git a/\(entry.path) b/\(entry.path)"))\n" +
            "\(ANSI.grey("--- a/\(entry.path)"))\n" +
            "\(ANSI.grey("+++ b/\(entry.path)"))\n" +
            simpleDiff(oldText: oldText, newText: newText)
        }.joined(separator: "\n\n")
    }

    private func simpleDiff(oldText: String, newText: String) -> String {
        let oldLines = oldText.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let newLines = newText.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        if oldLines.isEmpty && newLines.isEmpty { return "" }
        var lines = ["@@ -1,\(oldLines.count) +1,\(newLines.count) @@"]
        oldLines.prefix(20).forEach { lines.append(ANSI.red("-\($0)")) }
        newLines.prefix(20).forEach { lines.append(ANSI.green("+\($0)")) }
        return lines.joined(separator: "\n")
    }

    private func stage(_ args: [String], at url: URL) -> String {
        guard !args.isEmpty else { return ANSI.red("git add: nothing specified") }
        var state = loadState(at: url)
        let buckets = statusBuckets(at: url)
        let changedPaths = Set(buckets.all.map(\.path))
        var pathsToStage = Set<String>()

        for arg in args {
            if arg == "." || arg == "-A" || arg == "--all" {
                pathsToStage.formUnion(changedPaths)
                continue
            }
            let normalized = normalizePath(arg)
            if changedPaths.contains(normalized) {
                pathsToStage.insert(normalized)
            } else if FileManager.default.fileExists(atPath: url.appendingPathComponent(normalized).path) {
                pathsToStage.insert(normalized)
            }
        }

        guard !pathsToStage.isEmpty else {
            return ANSI.grey("No changes matched \(args.joined(separator: ", "))")
        }

        state.stagedPaths = Array(Set(state.stagedPaths).union(pathsToStage)).sorted()
        do {
            try saveState(state, at: url)
            refresh(at: url)
            return ANSI.grey("Staged: \(Array(pathsToStage).sorted().joined(separator: ", "))")
        } catch {
            return ANSI.red("git add: \(error.localizedDescription)")
        }
    }

    private func commit(message: String, at url: URL) -> String {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return ANSI.red("git commit: message must not be empty") }

        var state = loadState(at: url)
        let buckets = statusBuckets(at: url)
        let stagedChangedPaths = Set(buckets.staged.map(\.path))
        guard !stagedChangedPaths.isEmpty else { return ANSI.red("nothing to commit") }

        let parent = readHEADSha(at: url).nilIfEmpty
        let snapshot = workingTreeSnapshot(at: url)
        let date = ISO8601DateFormatter().string(from: Date())
        let hash = makeCommitHash(message: trimmed, parent: parent, branch: currentBranch, date: date, snapshot: snapshot)
        let commit = StoredGitCommit(
            hash: hash,
            parentHash: parent,
            branch: currentBranch,
            author: "Zed iPad",
            date: date,
            message: trimmed,
            snapshot: snapshot
        )
        state.commits.append(commit)
        state.stagedPaths = []

        do {
            try saveState(state, at: url)
            try writeBranchRef(hash, branch: currentBranch, at: url)
            refresh(at: url)
            return ANSI.green("[\(currentBranch) \(String(hash.prefix(7)))] \(trimmed)")
        } catch {
            return ANSI.red("git commit: \(error.localizedDescription)")
        }
    }

    private func checkout(branch: String, at url: URL) -> String {
        let normalized = normalizeBranchName(branch)
        guard !normalized.isEmpty else { return ANSI.red("git checkout: missing branch name") }

        do {
            let headSha = readHEADSha(at: url)
            let branchRef = url.appendingPathComponent(".git/refs/heads/\(normalized)")
            if !FileManager.default.fileExists(atPath: branchRef.path) {
                try FileManager.default.createDirectory(at: branchRef.deletingLastPathComponent(), withIntermediateDirectories: true)
                try headSha.write(to: branchRef, atomically: true, encoding: .utf8)
            }
            try "ref: refs/heads/\(normalized)\n".write(to: url.appendingPathComponent(".git/HEAD"), atomically: true, encoding: .utf8)
            refresh(at: url)
            return ANSI.green("Switched to branch '\(normalized)'")
        } catch {
            return ANSI.red("git checkout: \(error.localizedDescription)")
        }
    }

    private func formatLog(at url: URL) -> String {
        let state = loadState(at: url)
        let commitsByHash = Dictionary(uniqueKeysWithValues: state.commits.map { ($0.hash, $0) })
        var cursor = readHEADSha(at: url).nilIfEmpty
        var commits: [StoredGitCommit] = []

        while let hash = cursor, let commit = commitsByHash[hash] {
            commits.append(commit)
            cursor = commit.parentHash
        }

        guard !commits.isEmpty else {
            return ANSI.grey("(no commits yet — use 'git commit' to create the first commit)")
        }

        return commits.map { commit in
            GitCommit(
                hash: commit.hash,
                shortHash: String(commit.hash.prefix(7)),
                author: commit.author,
                date: commit.date,
                message: commit.message
            ).oneline
        }.joined(separator: "\n")
    }

    private func zedStateURL(at url: URL) -> URL {
        url.appendingPathComponent(".git/zedipad/state.json")
    }

    private func loadState(at url: URL) -> StoredGitState {
        let stateURL = zedStateURL(at: url)
        guard let data = try? Data(contentsOf: stateURL),
              let state = try? JSONDecoder().decode(StoredGitState.self, from: data) else {
            return StoredGitState()
        }
        return state
    }

    private func saveState(_ state: StoredGitState, at url: URL) throws {
        let stateURL = zedStateURL(at: url)
        try FileManager.default.createDirectory(at: stateURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(state)
        try data.write(to: stateURL, options: .atomic)
    }

    private func headCommit(at url: URL, in state: StoredGitState) -> StoredGitCommit? {
        let headSha = readHEADSha(at: url)
        guard !headSha.isEmpty else { return nil }
        return state.commits.last { $0.hash == headSha }
    }

    private func workingTreeSnapshot(at url: URL) -> [String: String] {
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: []
        ) else { return [:] }

        var snapshot: [String: String] = [:]
        for case let fileURL as URL in enumerator {
            let relativePath = normalizePath(fileURL.path.replacingOccurrences(of: url.path + "/", with: ""))
            if relativePath == ".git" || relativePath.hasPrefix(".git/") {
                enumerator.skipDescendants()
                continue
            }
            var isDirectory: ObjCBool = false
            FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDirectory)
            if isDirectory.boolValue {
                continue
            }
            if let data = try? Data(contentsOf: fileURL) {
                snapshot[relativePath] = data.base64EncodedString()
            }
        }
        return snapshot
    }

    private func writeBranchRef(_ hash: String, branch: String, at url: URL) throws {
        let branchRef = url.appendingPathComponent(".git/refs/heads/\(branch)")
        try FileManager.default.createDirectory(at: branchRef.deletingLastPathComponent(), withIntermediateDirectories: true)
        try "\(hash)\n".write(to: branchRef, atomically: true, encoding: .utf8)
    }

    private func normalizePath(_ path: String) -> String {
        path.replacingOccurrences(of: "\\", with: "/")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            .replacingOccurrences(of: "^\\./", with: "", options: .regularExpression)
    }

    private func normalizeBranchName(_ branch: String) -> String {
        branch.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "refs/heads/", with: "")
            .replacingOccurrences(of: "/", with: "-")
    }

    private func makeCommitHash(message: String, parent: String?, branch: String, date: String, snapshot: [String: String]) -> String {
        let payload = ([message, parent ?? "", branch, date] + snapshot.keys.sorted().flatMap { [$0, snapshot[$0] ?? ""] })
            .joined(separator: "\u{0}")
        let data = Data(payload.utf8)
        return data.stableHexDigest
    }
}

// MARK: - Data SHA1 helper

extension Data {
    var sha1Hex: String {
        withUnsafeBytes { ptr in
            // CC_SHA1 not available without CommonCrypto import
            // Use a simple CRC-based approximation for comparison purposes
        }
        // Fallback: use base64 as a proxy hash for comparison
        return base64EncodedString()
    }

    var stableHexDigest: String {
        let bytes = [UInt8](self)
        var hash1: UInt64 = 0xcbf29ce484222325
        var hash2: UInt64 = 0x84222325cbf29ce4
        for byte in bytes {
            hash1 ^= UInt64(byte)
            hash1 &*= 0x100000001b3
            hash2 = (hash2 &<< 5) &+ hash2 &+ UInt64(byte)
        }
        return String(format: "%016llx%016llx%08llx", hash1, hash2, UInt64(bytes.count))
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
