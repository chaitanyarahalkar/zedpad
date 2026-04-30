import SwiftUI

@MainActor
class GoToLineState: ObservableObject {
    @Published var lineNumber: String = ""
    @Published var isVisible: Bool = false

    var parsedLine: Int? {
        guard let n = Int(lineNumber), n > 0 else { return nil }
        return n
    }

    func show() {
        lineNumber = ""
        isVisible = true
    }

    func hide() {
        isVisible = false
        lineNumber = ""
    }
}

struct GoToLineView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var state: GoToLineState
    let totalLines: Int
    let onJump: (Int) -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.right.to.line")
                .font(.system(size: 13))
                .foregroundColor(appState.theme.accentColor)

            Text("Go to Line:")
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(appState.theme.secondaryText)

            TextField("1–\(totalLines)", text: $state.lineNumber)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(appState.theme.primaryText)
                .keyboardType(.numberPad)
                .focused($isFocused)
                .frame(width: 80)
                .onSubmit { jump() }
                .accessibilityLabel("Line number input")

            Button("Jump") { jump() }
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(appState.theme.accentColor)
                .disabled(state.parsedLine == nil)
                .buttonStyle(.plain)
                .accessibilityLabel("Jump to line")

            Spacer()

            Button { state.hide() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11))
                    .foregroundColor(appState.theme.secondaryText)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(appState.theme.tabBarBackground)
        .overlay(Rectangle().fill(appState.theme.borderColor).frame(height: 1), alignment: .top)
        .onAppear { isFocused = true }
    }

    private func jump() {
        guard let line = state.parsedLine else { return }
        let clamped = max(1, min(line, totalLines))
        onJump(clamped)
        state.hide()
    }
}
