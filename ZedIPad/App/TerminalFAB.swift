import SwiftUI

struct TerminalFAB: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                appState.showTerminal.toggle()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(appState.showTerminal
                        ? appState.theme.accentColor
                        : appState.theme.sidebarBackground)
                    .frame(width: 48, height: 48)
                    .shadow(color: appState.showTerminal
                        ? appState.theme.accentColor.opacity(0.4)
                        : .black.opacity(0.3),
                        radius: 12, x: 0, y: 4)
                    .overlay(
                        Circle()
                            .stroke(appState.showTerminal
                                ? Color.clear
                                : appState.theme.borderColor,
                                lineWidth: 1)
                    )

                Image(systemName: "terminal.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(appState.showTerminal
                        ? Color(hex: "#1e2124")
                        : appState.theme.primaryText)
            }
        }
        .buttonStyle(.plain)
        .padding(.trailing, 20)
        .padding(.bottom, 20)
        .accessibilityLabel("Toggle terminal")
        .keyboardShortcut("`", modifiers: .command)
    }
}
