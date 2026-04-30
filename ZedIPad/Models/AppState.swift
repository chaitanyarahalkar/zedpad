import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {
    @Published var activeFile: FileNode?
    @Published var openFiles: [FileNode] = []
    @Published var recentFiles: [FileNode] = []
    @Published var theme: ZedTheme = ZedTheme.dark
    @Published var showingCommandPalette: Bool = false
    @Published var showingSSHConnect: Bool = false
    @Published var showingDocumentPicker: Bool = false
    @Published var showingOnboarding: Bool = false
    @Published var showTerminal: Bool = false
    @Published var showingGitCommit: Bool = false
    @Published var rootDirectory: FileNode?
    @Published var fontSize: CGFloat = 13
    @Published var wordWrap: Bool = true
    @Published var tabSize: Int = 4
    @Published var findHighlightRanges: [NSRange] = []
    @Published var findScrollToRange: NSRange? = nil

    static let maxRecentFiles = 10
    @Published var lastError: String?
    @Published var filesystemRoot: FileNode?
    @Published var sortOrder: FileSortOrder = .nameAscending

    enum FileSortOrder: String, CaseIterable {
        case nameAscending = "Name ↑"
        case nameDescending = "Name ↓"
        case dateModified = "Date Modified"
        case size = "Size"
        case type = "Type"
    }

    init() {
        rootDirectory = FileNode.sampleRoot()
        loadDocumentsDirectory()
        restoreRecentFiles()
        restoreLastOpenFile()
        subscribeToMenuCommands()
    }

    private func subscribeToMenuCommands() {
        NotificationCenter.default.addObserver(forName: .showCommandPalette, object: nil, queue: .main) { [weak self] _ in
            self?.showingCommandPalette = true
        }
        NotificationCenter.default.addObserver(forName: .toggleTerminal, object: nil, queue: .main) { [weak self] _ in
            withAnimation { self?.showTerminal.toggle() }
        }
        NotificationCenter.default.addObserver(forName: .toggleTheme, object: nil, queue: .main) { [weak self] _ in
            withAnimation { self?.toggleTheme() }
        }
    }

    func loadDocumentsDirectory() {
        Task {
            do {
                let docsRoot = try FileSystemService.shared.loadDirectory(
                    at: FileSystemService.shared.documentsURL
                )
                filesystemRoot = docsRoot
                rootDirectory = docsRoot  // always use real FS, even if empty
            } catch {
                lastError = error.localizedDescription
            }
        }
    }

    func loadDirectory(at url: URL) {
        Task {
            do {
                let node = try FileSystemService.shared.loadDirectory(at: url)
                rootDirectory = node
                filesystemRoot = node
            } catch {
                lastError = error.localizedDescription
            }
        }
    }

    func createFile(named name: String, in parent: FileNode) {
        let parentURL = parent.fileURL ?? FileSystemService.shared.documentsURL
        do {
            let url = try FileSystemService.shared.createFile(named: name, in: parentURL)
            reloadChildren(of: parent)
            // Open the new file
            let node = FileNode(name: name, type: .file, path: url.path, url: url)
            openFile(node)
        } catch {
            lastError = error.localizedDescription
        }
    }

    func createDirectory(named name: String, in parent: FileNode) {
        let parentURL = parent.fileURL ?? FileSystemService.shared.documentsURL
        do {
            _ = try FileSystemService.shared.createDirectory(named: name, in: parentURL)
            reloadChildren(of: parent)
            parent.isExpanded = true
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Reloads a directory node's children from disk and expands it.
    func reloadChildren(of node: FileNode) {
        let url = node.fileURL ?? FileSystemService.shared.documentsURL
        Task {
            guard let fresh = try? FileSystemService.shared.loadDirectory(at: url) else { return }
            node.children = fresh.children
            node.isExpanded = true
            // If this is the root, keep rootDirectory in sync
            if node === rootDirectory || rootDirectory?.fileURL == url {
                rootDirectory = node
            }
        }
    }

    func deleteNode(_ node: FileNode, from parent: FileNode) {
        guard let url = node.fileURL else { return }
        do {
            try FileSystemService.shared.delete(at: url)
            parent.children?.removeAll { $0.id == node.id }
            closeFile(node)
        } catch {
            lastError = error.localizedDescription
        }
    }

    func renameNode(_ node: FileNode, to newName: String) {
        guard let url = node.fileURL else { return }
        do {
            let newURL = try FileSystemService.shared.rename(at: url, to: newName)
            node.fileURL = newURL
        } catch {
            lastError = error.localizedDescription
        }
    }

    func duplicateNode(_ node: FileNode, in parent: FileNode) {
        guard let url = node.fileURL, let parentURL = parent.fileURL else { return }
        let ext = url.pathExtension
        let base = url.deletingPathExtension().lastPathComponent
        let copyName = ext.isEmpty ? "\(base)_copy" : "\(base)_copy.\(ext)"
        let destURL = parentURL.appendingPathComponent(copyName)
        do {
            try FileSystemService.shared.copy(from: url, to: destURL)
            let copy = FileNode(name: copyName, type: node.type, path: destURL.path, url: destURL)
            parent.children?.append(copy)
            sortChildren(of: parent)
        } catch {
            lastError = error.localizedDescription
        }
    }

    func sortChildren(of node: FileNode) {
        guard var children = node.children else { return }
        switch sortOrder {
        case .nameAscending:
            children.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameDescending:
            children.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        case .dateModified:
            children.sort { ($0.metadata?.modifiedDate ?? .distantPast) > ($1.metadata?.modifiedDate ?? .distantPast) }
        case .size:
            children.sort { ($0.metadata?.size ?? 0) > ($1.metadata?.size ?? 0) }
        case .type:
            children.sort { $0.fileExtension.localizedCaseInsensitiveCompare($1.fileExtension) == .orderedAscending }
        }
        node.children = children
    }

    // MARK: - Persistence

    private let recentFilesKey = "recentFileBookmarks"
    private let lastOpenFileKey = "lastOpenFileBookmark"

    func persistRecentFiles() {
        let bookmarks = recentFiles.compactMap { file -> Data? in
            guard let url = file.fileURL else { return nil }
            return try? url.bookmarkData(options: .minimalBookmark)
        }
        UserDefaults.standard.set(bookmarks, forKey: recentFilesKey)
    }

    func restoreRecentFiles() {
        guard let bookmarks = UserDefaults.standard.array(forKey: recentFilesKey) as? [Data] else { return }
        for bookmark in bookmarks {
            var isStale = false
            guard let url = try? URL(resolvingBookmarkData: bookmark, bookmarkDataIsStale: &isStale),
                  !isStale else { continue }
            let node = FileNode(name: url.lastPathComponent, type: .file, path: url.path, url: url)
            if let content = try? FileSystemService.shared.readFile(at: url) {
                node.content = content
            }
            recentFiles.append(node)
        }
    }

    func persistLastOpenFile() {
        guard let url = activeFile?.fileURL,
              let bookmark = try? url.bookmarkData(options: .minimalBookmark) else { return }
        UserDefaults.standard.set(bookmark, forKey: lastOpenFileKey)
    }

    func restoreLastOpenFile() {
        guard let bookmark = UserDefaults.standard.data(forKey: lastOpenFileKey) else { return }
        var isStale = false
        guard let url = try? URL(resolvingBookmarkData: bookmark, bookmarkDataIsStale: &isStale),
              !isStale else { return }
        let node = FileNode(name: url.lastPathComponent, type: .file, path: url.path, url: url)
        if let content = try? FileSystemService.shared.readFile(at: url) {
            node.content = content
            openFile(node)
        }
    }

    func openFile(_ file: FileNode) {
        guard file.type == .file else { return }
        activeFile = file
        if !openFiles.contains(where: { $0.id == file.id }) {
            openFiles.append(file)
        }
        // Track recent files
        recentFiles.removeAll { $0.id == file.id }
        recentFiles.insert(file, at: 0)
        if recentFiles.count > Self.maxRecentFiles {
            recentFiles = Array(recentFiles.prefix(Self.maxRecentFiles))
        }
    }

    func closeFile(_ file: FileNode) {
        openFiles.removeAll { $0.id == file.id }
        if activeFile?.id == file.id {
            activeFile = openFiles.last
        }
    }

    func toggleTheme() {
        theme = theme == .dark ? .light : .dark
    }

    func increaseFontSize() {
        fontSize = min(fontSize + 1, 24)
    }

    func decreaseFontSize() {
        fontSize = max(fontSize - 1, 9)
    }
}
