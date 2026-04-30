import SwiftUI

struct CommandPaletteView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""
    @FocusState private var isFocused: Bool

    private var filteredCommands: [PaletteCommand] {
        if query.isEmpty { return PaletteCommand.allCommands }
        return PaletteCommand.allCommands.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.subtitle.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13))
                        .foregroundColor(appState.theme.accentColor)

                    TextField("Type a command...", text: $query)
                        .font(.system(size: 15, design: .monospaced))
                        .foregroundColor(appState.theme.primaryText)
                        .focused($isFocused)
                        .autocorrectionDisabled()
                        .accessibilityLabel("Command input")
                }
                .padding(14)
                .background(appState.theme.editorBackground)

                Divider().background(appState.theme.borderColor)

                List(filteredCommands) { command in
                    PaletteCommandRow(command: command)
                        .listRowBackground(appState.theme.editorBackground)
                        .onTapGesture {
                            command.action(appState)
                            dismiss()
                        }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(appState.theme.editorBackground)
            }
            .background(appState.theme.editorBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(appState.theme.accentColor)
                }
            }
        }
        .onAppear { isFocused = true }
    }
}

struct PaletteCommandRow: View {
    @EnvironmentObject private var appState: AppState
    let command: PaletteCommand

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: command.icon)
                .font(.system(size: 14))
                .foregroundColor(appState.theme.accentColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(command.title)
                    .font(.system(size: 14))
                    .foregroundColor(appState.theme.primaryText)
                if !command.subtitle.isEmpty {
                    Text(command.subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(appState.theme.secondaryText)
                }
            }

            Spacer()

            if let shortcut = command.shortcut {
                Text(shortcut)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(appState.theme.secondaryText)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(appState.theme.sidebarBackground)
                    .cornerRadius(3)
                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(appState.theme.borderColor, lineWidth: 1))
            }
        }
        .padding(.vertical, 4)
    }
}

@MainActor
struct PaletteCommand: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let shortcut: String?
    let action: (AppState) -> Void

    static let allCommands: [PaletteCommand] = [
        PaletteCommand(
            title: "Toggle Theme",
            subtitle: "Switch between dark and light",
            icon: "circle.lefthalf.filled",
            shortcut: "⌘⇧T",
            action: { state in state.toggleTheme() }
        ),
        PaletteCommand(
            title: "Open File",
            subtitle: "Browse and open a file",
            icon: "doc.badge.plus",
            shortcut: "⌘O",
            action: { _ in }
        ),
        PaletteCommand(
            title: "Close File",
            subtitle: "Close the active editor tab",
            icon: "xmark.doc",
            shortcut: "⌘W",
            action: { state in
                if let file = state.activeFile { state.closeFile(file) }
            }
        ),
        PaletteCommand(
            title: "Dark Theme",
            subtitle: "Zed Dark",
            icon: "moon.fill",
            shortcut: nil,
            action: { state in state.theme = .dark }
        ),
        PaletteCommand(
            title: "Light Theme",
            subtitle: "Zed Light",
            icon: "sun.max.fill",
            shortcut: nil,
            action: { state in state.theme = .light }
        ),
        PaletteCommand(
            title: "One Dark Theme",
            subtitle: "Atom One Dark",
            icon: "circle.fill",
            shortcut: nil,
            action: { state in state.theme = .oneDark }
        ),
        PaletteCommand(
            title: "Solarized Dark Theme",
            subtitle: "Solarized Dark",
            icon: "sun.haze.fill",
            shortcut: nil,
            action: { state in state.theme = .solarizedDark }
        ),
        PaletteCommand(
            title: "Increase Font Size",
            subtitle: "Make text larger",
            icon: "textformat.size.larger",
            shortcut: "⌘+",
            action: { state in state.increaseFontSize() }
        ),
        PaletteCommand(
            title: "Decrease Font Size",
            subtitle: "Make text smaller",
            icon: "textformat.size.smaller",
            shortcut: "⌘-",
            action: { state in state.decreaseFontSize() }
        ),
        PaletteCommand(
            title: "Reset Font Size",
            subtitle: "Reset to default (13pt)",
            icon: "textformat.size",
            shortcut: nil,
            action: { state in state.fontSize = 13 }
        ),
        PaletteCommand(
            title: "Toggle Word Wrap",
            subtitle: "Enable or disable line wrapping",
            icon: "text.alignleft",
            shortcut: nil,
            action: { state in state.wordWrap.toggle() }
        ),
        PaletteCommand(
            title: "Tab Size: 2 Spaces",
            subtitle: "Set indentation to 2 spaces",
            icon: "increase.indent",
            shortcut: nil,
            action: { state in state.tabSize = 2 }
        ),
        PaletteCommand(
            title: "Tab Size: 4 Spaces",
            subtitle: "Set indentation to 4 spaces",
            icon: "increase.indent",
            shortcut: nil,
            action: { state in state.tabSize = 4 }
        ),
        PaletteCommand(
            title: "Tab Size: 8 Spaces",
            subtitle: "Set indentation to 8 spaces",
            icon: "increase.indent",
            shortcut: nil,
            action: { state in state.tabSize = 8 }
        ),
    ]
}

struct ThemeToggleButton: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                appState.toggleTheme()
            }
        } label: {
            Image(systemName: appState.theme == .light ? "moon.fill" : "sun.max.fill")
                .foregroundColor(appState.theme.primaryText)
        }
        .accessibilityLabel("Toggle theme")
    }
}

struct CommandPaletteButton: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Button {
            appState.showingCommandPalette = true
        } label: {
            Image(systemName: "terminal")
                .foregroundColor(appState.theme.primaryText)
        }
        .accessibilityLabel("Open command palette")
    }
}

struct TerminalToggleButton: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                appState.showTerminal.toggle()
            }
        } label: {
            Image(systemName: "apple.terminal")
                .foregroundColor(appState.showTerminal ? appState.theme.accentColor : appState.theme.primaryText)
        }
        .accessibilityLabel("Toggle terminal")
        .keyboardShortcut("`", modifiers: .command)
    }
}
