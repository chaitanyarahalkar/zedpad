import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {
    @Published var activeFile: FileNode?
    @Published var openFiles: [FileNode] = []
    @Published var recentFiles: [FileNode] = []
    @Published var theme: ZedTheme = ZedTheme.dark
    @Published var showingCommandPalette: Bool = false
    @Published var rootDirectory: FileNode?
    @Published var fontSize: CGFloat = 13
    @Published var wordWrap: Bool = true
    @Published var tabSize: Int = 4

    static let maxRecentFiles = 10

    init() {
        rootDirectory = FileNode.sampleRoot()
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
