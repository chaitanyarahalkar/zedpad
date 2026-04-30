import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarContainerView()
                .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
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

struct SidebarContainerView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedTab: SidebarTab = .files

    enum SidebarTab: Hashable { case files, search }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach([SidebarTab.files, .search], id: \.self) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: tab == .files ? "folder" : "magnifyingglass")
                                .font(.system(size: 13))
                            Text(tab == .files ? "Files" : "Search")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(selectedTab == tab ? appState.theme.accentColor : appState.theme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(appState.theme.tabBarBackground)
            .overlay(Rectangle().fill(appState.theme.borderColor).frame(height: 1), alignment: .bottom)

            Group {
                if selectedTab == .files {
                    FileTreeView()
                } else {
                    GlobalSearchView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle(selectedTab == .files ? "Files" : "Search")
        .navigationBarTitleDisplayMode(.inline)
    }
}
