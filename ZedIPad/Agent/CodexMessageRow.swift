import SwiftUI

struct CodexMessageRow: View {
    @EnvironmentObject private var appState: AppState
    let message: CodexMessage
    @ObservedObject var session: CodexSession

    var body: some View {
        VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 6) {
            switch message.role {
            case .user:
                userBubble
            case .agent:
                agentContent
            case .system:
                systemLine
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }

    // MARK: - User bubble

    private var userBubble: some View {
        Text(message.content)
            .font(.system(size: 13))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(appState.theme.accentColor)
            .cornerRadius(12)
            .frame(maxWidth: 300, alignment: .trailing)
    }

    // MARK: - Agent content

    private var agentContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !message.content.isEmpty {
                renderedAgentText(message.content)
            }
            if message.isStreaming && message.content.isEmpty {
                ThinkingDots()
            }
            if let cmd = message.commandText {
                commandBlock(cmd, output: message.commandOutput)
            }
            ForEach(message.fileChanges) { change in
                InlineDiffView(change: change, session: session)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - System line

    private var systemLine: some View {
        Text(message.content)
            .font(.system(size: 11))
            .foregroundColor(appState.theme.secondaryText)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 2)
    }

    // MARK: - Rendered agent text (code block detection)

    @ViewBuilder
    private func renderedAgentText(_ text: String) -> some View {
        let blocks = parseBlocks(text)
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                switch block {
                case .prose(let s):
                    Text(s)
                        .font(.system(size: 13))
                        .foregroundColor(appState.theme.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                case .code(let lang, let code):
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text(lang.isEmpty ? "code" : lang)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(appState.theme.secondaryText)
                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .padding(.top, 6)
                        .background(appState.theme.sidebarBackground)

                        Text(code)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(appState.theme.primaryText)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(appState.theme.sidebarBackground)
                    }
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(appState.theme.borderColor, lineWidth: 1))
                }
            }
        }
    }

    private func commandBlock(_ cmd: String, output: String?) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "terminal")
                    .font(.system(size: 11))
                    .foregroundColor(appState.theme.accentColor)
                Text(cmd)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(appState.theme.primaryText)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(appState.theme.sidebarBackground)

            if let out = output, !out.isEmpty {
                Text(out)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(appState.theme.secondaryText)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(appState.theme.editorBackground)
            }
        }
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(appState.theme.borderColor, lineWidth: 1))
    }

    // MARK: - Block parser

    enum TextBlock { case prose(String), code(String, String) }

    private func parseBlocks(_ text: String) -> [TextBlock] {
        var blocks: [TextBlock] = []
        let lines = text.components(separatedBy: "\n")
        var i = 0
        var prose: [String] = []

        while i < lines.count {
            let line = lines[i]
            if line.hasPrefix("```") {
                if !prose.isEmpty {
                    blocks.append(.prose(prose.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)))
                    prose = []
                }
                let lang = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                i += 1
                var code: [String] = []
                while i < lines.count && !lines[i].hasPrefix("```") {
                    code.append(lines[i]); i += 1
                }
                blocks.append(.code(lang, code.joined(separator: "\n")))
            } else {
                prose.append(line)
            }
            i += 1
        }
        if !prose.isEmpty {
            blocks.append(.prose(prose.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)))
        }
        return blocks
    }
}

// MARK: - Inline diff view

struct InlineDiffView: View {
    @EnvironmentObject private var appState: AppState
    let change: FileChangeDiff
    @ObservedObject var session: CodexSession

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "doc.text")
                    .font(.system(size: 11))
                Text(change.path)
                    .font(.system(size: 11, design: .monospaced))
                Spacer()
                decisionBadge
            }
            .foregroundColor(appState.theme.primaryText)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(appState.theme.sidebarBackground)

            diffLines
        }
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(appState.theme.borderColor, lineWidth: 1))
    }

    @ViewBuilder private var decisionBadge: some View {
        switch change.decision {
        case .accepted:
            Label("Accepted", systemImage: "checkmark.circle.fill")
                .font(.system(size: 10)).foregroundColor(.green)
        case .declined:
            Label("Declined", systemImage: "xmark.circle.fill")
                .font(.system(size: 10)).foregroundColor(.red)
        case .pending:
            EmptyView()
        }
    }

    private var diffLines: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(change.diff.components(separatedBy: "\n").enumerated()), id: \.offset) { _, line in
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(lineColor(line).opacity(0.3))
                        .frame(width: 3)
                    Text(line.isEmpty ? " " : line)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(lineTextColor(line))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 1)
                        .background(lineColor(line).opacity(0.08))
                }
            }
        }
        .background(appState.theme.editorBackground)
    }

    private func lineColor(_ line: String) -> Color {
        if line.hasPrefix("+") { return .green }
        if line.hasPrefix("-") { return .red }
        return .clear
    }

    private func lineTextColor(_ line: String) -> Color {
        if line.hasPrefix("+") { return Color(hex: "#a6e3a1") }
        if line.hasPrefix("-") { return Color(hex: "#f38ba8") }
        return appState.theme.secondaryText
    }
}

// MARK: - Thinking dots

struct ThinkingDots: View {
    @State private var phase = 0
    let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(Color.gray)
                    .frame(width: 6, height: 6)
                    .opacity(phase == i ? 1 : 0.3)
            }
        }
        .onReceive(timer) { _ in phase = (phase + 1) % 3 }
    }
}
