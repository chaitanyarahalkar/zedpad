import SwiftUI

struct CodexApprovalCard: View {
    @EnvironmentObject private var appState: AppState
    let approval: CodexApproval
    @ObservedObject var session: CodexSession

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: approval.type == .fileChange ? "doc.badge.gearshape" : "terminal")
                    .foregroundColor(appState.theme.accentColor)
                Text(approval.type == .fileChange ? "File Change Request" : "Command Execution Request")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(appState.theme.primaryText)
                Spacer()
            }

            if approval.type == .fileChange {
                if let path = approval.path {
                    Text(path)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(appState.theme.accentColor)
                }
                if let diff = approval.diff {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(diff.components(separatedBy: "\n").prefix(20).enumerated()), id: \.offset) { _, line in
                                Text(line.isEmpty ? " " : line)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(diffColor(line))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(diffBg(line))
                                    .padding(.horizontal, 8)
                            }
                        }
                    }
                    .frame(maxHeight: 120)
                    .background(appState.theme.editorBackground)
                    .cornerRadius(6)
                }
            } else if let cmd = approval.command {
                HStack {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11))
                        .foregroundColor(appState.theme.accentColor)
                    Text(cmd)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(appState.theme.primaryText)
                }
                .padding(10)
                .background(appState.theme.editorBackground)
                .cornerRadius(6)
            }

            HStack(spacing: 8) {
                Button("Accept") {
                    Task { await session.approve(approval, decision: "accept") }
                }
                .buttonStyle(CodexApprovalButtonStyle(color: appState.theme.accentColor, isPrimary: true))

                Button("Accept Always") {
                    Task { await session.approve(approval, decision: "acceptForSession") }
                }
                .buttonStyle(CodexApprovalButtonStyle(color: .orange, isPrimary: false))

                Spacer()

                Button("Decline") {
                    Task { await session.approve(approval, decision: "decline") }
                }
                .buttonStyle(CodexApprovalButtonStyle(color: .red, isPrimary: false))
            }
        }
        .padding(12)
        .background(appState.theme.tabBarBackground)
        .overlay(Rectangle().fill(appState.theme.accentColor).frame(height: 2), alignment: .top)
    }

    private func diffColor(_ line: String) -> Color {
        if line.hasPrefix("+") { return Color(hex: "#a6e3a1") }
        if line.hasPrefix("-") { return Color(hex: "#f38ba8") }
        return appState.theme.secondaryText
    }

    private func diffBg(_ line: String) -> Color {
        if line.hasPrefix("+") { return Color.green.opacity(0.08) }
        if line.hasPrefix("-") { return Color.red.opacity(0.08) }
        return .clear
    }
}

struct CodexApprovalButtonStyle: ButtonStyle {
    let color: Color
    let isPrimary: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(isPrimary ? .white : color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isPrimary ? color : color.opacity(0.15))
            .cornerRadius(6)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
