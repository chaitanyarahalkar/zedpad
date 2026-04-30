import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {
    @Published var activeFile: FileNode?
    @Published var openFiles: [FileNode] = []
    @Published var theme: ZedTheme = ZedTheme.dark
    @Published var showingCommandPalette: Bool = false
    @Published var rootDirectory: FileNode?

    init() {
        rootDirectory = FileNode.sampleRoot()
    }

    func openFile(_ file: FileNode) {
        guard file.type == .file else { return }
        activeFile = file
        if !openFiles.contains(where: { $0.id == file.id }) {
            openFiles.append(file)
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
}
