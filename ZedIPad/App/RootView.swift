import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            FileTreeView()
                .navigationTitle("Files")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        ThemeToggleButton()
                    }
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        DocumentPickerButton()
                        CommandPaletteButton()
                    }
                }
        } detail: {
            if let file = appState.activeFile {
                EditorView(file: file)
            } else {
                WelcomeView()
            }
        }
        .navigationSplitViewStyle(.balanced)
        .tint(appState.theme.accentColor)
        .sheet(isPresented: $appState.showingCommandPalette) {
            CommandPaletteView()
        }
        .overlay(alignment: .topLeading) {
            VStack {
                CommandPaletteShortcutButton()
                ThemeShortcutButton()
            }
        }
    }
}
