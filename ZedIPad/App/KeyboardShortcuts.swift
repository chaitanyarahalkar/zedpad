import SwiftUI

/// Attaches Zed-style keyboard shortcuts to the root view.
struct KeyboardShortcutsModifier: ViewModifier {
    @EnvironmentObject private var appState: AppState
    @Binding var showFind: Bool

    func body(content: Content) -> some View {
        content
            // ⌘P — command palette
            .keyboardShortcut("p", modifiers: [.command, .shift])
            // ⌘W — close active tab
            .onKeyPress(.init("w"), phases: .down) { _ in
                if let file = appState.activeFile {
                    appState.closeFile(file)
                    return .handled
                }
                return .ignored
            }
    }
}

extension View {
    func zedKeyboardShortcuts(showFind: Binding<Bool>) -> some View {
        modifier(KeyboardShortcutsModifier(showFind: showFind))
    }
}

/// Button that opens command palette via ⌘⇧P
struct CommandPaletteShortcutButton: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Button {
            appState.showingCommandPalette = true
        } label: {
            EmptyView()
        }
        .keyboardShortcut("p", modifiers: [.command, .shift])
        .accessibilityHidden(true)
        .frame(width: 0, height: 0)
    }
}

/// Invisible button wiring ⌘F to open find bar — placed in editor view
struct FindShortcutButton: View {
    @Binding var showFind: Bool

    var body: some View {
        Button {
            showFind = true
        } label: {
            EmptyView()
        }
        .keyboardShortcut("f", modifiers: .command)
        .accessibilityHidden(true)
        .frame(width: 0, height: 0)
    }
}

/// Invisible button wiring ⌘T to toggle theme
struct ThemeShortcutButton: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                appState.toggleTheme()
            }
        } label: {
            EmptyView()
        }
        .keyboardShortcut("t", modifiers: [.command, .shift])
        .accessibilityHidden(true)
        .frame(width: 0, height: 0)
    }
}
