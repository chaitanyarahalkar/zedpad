import SwiftUI

struct CodexAgentTab: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var session: CodexSession

    var body: some View {
        VStack(spacing: 0) {
            // Header bar
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .foregroundColor(appState.theme.accentColor)
                Text(session.config.name)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(appState.theme.primaryText)
                Circle()
                    .fill(session.isConnected ? Color.green : Color.red)
                    .frame(width: 6, height: 6)
                Spacer()
                if !session.isConnected {
                    Button("Reconnect") {
                        Task { await session.connect() }
                    }
                    .font(.system(size: 11))
                    .foregroundColor(appState.theme.accentColor)
                    .buttonStyle(.plain)
                }
                if session.isThinking {
                    Button("Stop") {
                        Task { await session.stopTurn() }
                    }
                    .font(.system(size: 11))
                    .foregroundColor(.red)
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(appState.theme.tabBarBackground)
            .overlay(Rectangle().fill(appState.theme.borderColor).frame(height: 1), alignment: .bottom)

            if let err = session.connectionError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(err)
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.1))
            }

            // Message list
            if session.messages.isEmpty && !session.isConnected {
                emptyState
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(session.messages) { msg in
                                CodexMessageRow(message: msg, session: session)
                                    .id(msg.id)
                            }
                            if session.isThinking && session.messages.last?.role != .agent {
                                HStack { ThinkingDots().padding(12) }
                                    .id("thinking")
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .onChange(of: session.messages.count) { _ in
                        withAnimation { proxy.scrollTo(session.messages.last?.id ?? "thinking", anchor: .bottom) }
                    }
                    .onChange(of: session.isThinking) { _ in
                        if session.isThinking { withAnimation { proxy.scrollTo("thinking", anchor: .bottom) } }
                    }
                }
            }

            // Approval card
            if let approval = session.pendingApproval {
                CodexApprovalCard(approval: approval, session: session)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Divider().background(appState.theme.borderColor)

            // Input
            CodexInputBar(
                session: session,
                fileContent: appState.activeFile?.content,
                fileName: appState.activeFile?.name
            )
        }
        .background(appState.theme.editorBackground)
        .task { if !session.isConnected { await session.connect() } }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 40, weight: .thin))
                .foregroundColor(appState.theme.accentColor)
            Text("Codex Agent")
                .font(.system(size: 20, weight: .light, design: .monospaced))
                .foregroundColor(appState.theme.primaryText)
            Text("Connecting to \(session.config.name)…")
                .font(.system(size: 13))
                .foregroundColor(appState.theme.secondaryText)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
