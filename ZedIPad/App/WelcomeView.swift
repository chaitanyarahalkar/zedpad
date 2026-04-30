import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 56, weight: .thin))
                    .foregroundColor(appState.theme.accentColor)

                Text("ZedIPad")
                    .font(.system(size: 32, weight: .light, design: .monospaced))
                    .foregroundColor(appState.theme.primaryText)

                Text("A Zed-inspired code editor for iPad")
                    .font(.system(size: 14))
                    .foregroundColor(appState.theme.secondaryText)
            }

            VStack(alignment: .leading, spacing: 12) {
                ShortcutHint(keys: "Select a file", description: "in the sidebar to start editing")
                ShortcutHint(keys: "⌘F", description: "Find in file")
                ShortcutHint(keys: "⌘⇧P", description: "Command palette")
                ShortcutHint(keys: "⌘⇧T", description: "Toggle theme")
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(appState.theme.editorBackground)
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
