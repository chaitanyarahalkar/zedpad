import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 14) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .font(.system(size: 48, weight: .thin))
                        .foregroundColor(appState.theme.accentColor)

                    Text("ZedIPad")
                        .font(.system(size: 28, weight: .light, design: .monospaced))
                        .foregroundColor(appState.theme.primaryText)

                    Text("A Zed-inspired code editor for iPad")
                        .font(.system(size: 13))
                        .foregroundColor(appState.theme.secondaryText)
                }
                .padding(.top, 48)
                .padding(.bottom, 32)

                // Recent files
                if !appState.recentFiles.isEmpty {
                    WelcomeSectionHeader(title: "Recent Files", icon: "clock")
                    VStack(spacing: 0) {
                        ForEach(appState.recentFiles.prefix(5)) { file in
                            RecentFileRow(file: file)
                                .onTapGesture { appState.openFile(file) }
                        }
                    }
                    .background(appState.theme.sidebarBackground)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(appState.theme.borderColor, lineWidth: 1))
                    .padding(.horizontal, 40)
                    .padding(.bottom, 24)
                }

                // Shortcuts
                WelcomeSectionHeader(title: "Keyboard Shortcuts", icon: "keyboard")
                VStack(alignment: .leading, spacing: 8) {
                    ShortcutHint(keys: "⌘F", description: "Find in file")
                    ShortcutHint(keys: "⌘⇧P", description: "Command palette")
                    ShortcutHint(keys: "⌘⇧T", description: "Toggle theme")
                    ShortcutHint(keys: "⌘W", description: "Close active tab")
                    ShortcutHint(keys: "⌘+", description: "Increase font size")
                    ShortcutHint(keys: "⌘-", description: "Decrease font size")
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(appState.theme.editorBackground)
    }
}

struct WelcomeSectionHeader: View {
    @EnvironmentObject private var appState: AppState
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(appState.theme.accentColor)
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(appState.theme.secondaryText)
            Spacer()
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 8)
    }
}

struct RecentFileRow: View {
    @EnvironmentObject private var appState: AppState
    let file: FileNode

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: file.icon)
                .font(.system(size: 13))
                .foregroundColor(appState.theme.accentColor)
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(appState.theme.primaryText)
                Text(file.path)
                    .font(.system(size: 10))
                    .foregroundColor(appState.theme.secondaryText)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "arrow.right")
                .font(.system(size: 10))
                .foregroundColor(appState.theme.secondaryText.opacity(0.5))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

struct ShortcutHint: View {
    @EnvironmentObject private var appState: AppState
    let keys: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Text(keys)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(appState.theme.primaryText)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(appState.theme.sidebarBackground)
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(appState.theme.borderColor, lineWidth: 1)
                )

            Text(description)
                .font(.system(size: 13))
                .foregroundColor(appState.theme.secondaryText)
        }
    }
}
