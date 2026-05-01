import SwiftUI

struct CodexInputBar: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var session: CodexSession
    var fileContent: String?
    var fileName: String?

    @State private var inputText = ""
    @State private var includeFile = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            if includeFile, let name = fileName {
                HStack(spacing: 6) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 11))
                    Text("Including: \(name)")
                        .font(.system(size: 11))
                    Spacer()
                }
                .foregroundColor(appState.theme.accentColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(appState.theme.accentColor.opacity(0.1))
            }

            HStack(alignment: .bottom, spacing: 8) {
                // Connection dot
                Circle()
                    .fill(session.isConnected ? Color.green : Color.red)
                    .frame(width: 7, height: 7)

                // Text input
                TextField("Ask Codex…", text: $inputText, axis: .vertical)
                    .font(.system(size: 13))
                    .foregroundColor(appState.theme.primaryText)
                    .focused($focused)
                    .lineLimit(1...5)
                    .onSubmit { sendIfReady() }

                // File context toggle
                if fileContent != nil {
                    Button {
                        includeFile.toggle()
                    } label: {
                        Image(systemName: includeFile ? "doc.fill" : "doc")
                            .font(.system(size: 13))
                            .foregroundColor(includeFile ? appState.theme.accentColor : appState.theme.secondaryText)
                    }
                    .buttonStyle(.plain)
                    .help("Include current file as context")
                }

                // Stop button while thinking
                if session.isThinking {
                    Button {
                        Task { await session.stopTurn() }
                    } label: {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                } else {
                    // Send button
                    Button {
                        sendIfReady()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(canSend ? appState.theme.accentColor : appState.theme.secondaryText)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSend)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(appState.theme.tabBarBackground)
    }

    private var canSend: Bool {
        session.isConnected && !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !session.isThinking
    }

    private func sendIfReady() {
        guard canSend else { return }
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        inputText = ""
        var context: String? = nil
        if includeFile, let content = fileContent, let name = fileName {
            context = "# File: \(name)\n\n```\n\(content)\n```"
        }
        Task { await session.sendMessage(text, context: context) }
    }
}
