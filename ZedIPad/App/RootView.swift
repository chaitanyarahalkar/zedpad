import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        GeometryReader { geo in
            if geo.size.width > geo.size.height {
                LandscapeLayout()
            } else {
                PortraitLayout(columnVisibility: $columnVisibility)
            }
        }
        // FAB floats globally above all content, always at bottom-right
        .overlay(alignment: .bottomTrailing) {
            TerminalFAB()
        }
        .tint(appState.theme.accentColor)
        .sheet(isPresented: $appState.showingCommandPalette) {
            CommandPaletteView()
        }
        .sheet(isPresented: $appState.showingSSHConnect) {
            ServerListView()
        }
        .sheet(isPresented: $appState.showingGitCommit) {
            GitCommitView(repoURL: appState.rootDirectory?.url)
        }
    }
}

// MARK: - Landscape: plain HStack, bypasses NavigationSplitView rotation bug

struct LandscapeLayout: View {
    @EnvironmentObject private var appState: AppState
    @State private var sidebarWidth: CGFloat = 280

    private var safeAreaTopInset: CGFloat {
        (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.top) ?? 0
    }

    var body: some View {
        // No NavigationStack/NavigationSplitView — bypasses iOS 26 rotation transform bug
        HStack(spacing: 0) {
            // Sidebar column
            VStack(spacing: 0) {
                // Manual toolbar — respects status bar via safeAreaInset
                HStack {
                    ThemeToggleButton()
                    CommandPaletteButton()
                    Spacer()
                    DocumentPickerButton()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .padding(.top, safeAreaTopInset)
                .background(appState.theme.sidebarBackground.ignoresSafeArea(edges: .top))
                .overlay(Rectangle().fill(appState.theme.borderColor).frame(height: 1), alignment: .bottom)

                SidebarContainerView()
            }
            .frame(width: sidebarWidth)
            .background(appState.theme.sidebarBackground)

            // Drag handle
            Rectangle()
                .fill(appState.theme.borderColor)
                .frame(width: 1)
                .overlay(
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 14)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    sidebarWidth = max(200, min(420, sidebarWidth + value.translation.width))
                                }
                        )
                )

            // Detail column
            VStack(spacing: 0) {
                if let file = appState.activeFile {
                    EditorView(file: file)
                } else {
                    WelcomeView()
                }
                if appState.showTerminal {
                    TerminalPanel()
                        .transition(.move(edge: .bottom))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .background(appState.theme.editorBackground.ignoresSafeArea())
    }
}

// MARK: - Portrait: NavigationSplitView (works correctly in portrait)

struct PortraitLayout: View {
    @EnvironmentObject private var appState: AppState
    @Binding var columnVisibility: NavigationSplitViewVisibility

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarContainerView()
                .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        ThemeToggleButton()
                    }
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        CommandPaletteButton()
                        DocumentPickerButton()
                    }
                }
        } detail: {
            VStack(spacing: 0) {
                if let file = appState.activeFile {
                    EditorView(file: file)
                } else {
                    WelcomeView()
                }
                if appState.showTerminal {
                    TerminalPanel()
                        .transition(.move(edge: .bottom))
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .overlay(alignment: .topLeading) {
            VStack {
                ThemeShortcutButton()
            }
        }
    }
}

// MARK: - Sidebar container (shared between layouts)

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
