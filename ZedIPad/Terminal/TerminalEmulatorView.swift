import SwiftUI
import SwiftTerm

// MARK: - SwiftTerm UIViewRepresentable bridge

struct TerminalEmulatorView: UIViewRepresentable {
    let theme: ZedTheme
    @Binding var input: String
    var onOutput: ((String) -> Void)?
    var onReady: ((TerminalView) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> TerminalView {
        let tv = TerminalView(frame: .zero)
        tv.accessibilityIdentifier = "Terminal emulator"
        tv.isAccessibilityElement = true
        tv.accessibilityLabel = "Terminal emulator"
        tv.terminalDelegate = context.coordinator
        tv.nativeForegroundColor = UIColor(theme.primaryText)
        tv.nativeBackgroundColor = UIColor(theme.editorBackground)
        tv.font = UIFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        context.coordinator.terminalView = tv
        onReady?(tv)
        return tv
    }

    func updateUIView(_ tv: TerminalView, context: Context) {
        context.coordinator.parent = self
        // Apply theme changes live
        tv.nativeForegroundColor = UIColor(theme.primaryText)
        tv.nativeBackgroundColor = UIColor(theme.editorBackground)
        // Feed new input if any
        if !input.isEmpty {
            let data = ArraySlice(input.utf8)
            tv.feed(byteArray: data)
            DispatchQueue.main.async {
                context.coordinator.parent.input = ""
            }
        }
    }

    class Coordinator: NSObject, TerminalViewDelegate {
        var parent: TerminalEmulatorView
        weak var terminalView: TerminalView?

        init(_ parent: TerminalEmulatorView) {
            self.parent = parent
        }

        func sizeChanged(source: TerminalView, newCols: Int, newRows: Int) {}
        func setTerminalTitle(source: TerminalView, title: String) {}
        func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}
        func bell(source: TerminalView) {}
        func requestOpenLink(source: TerminalView, link: String, params: [String: String]) {}
        func rangeChanged(source: TerminalView, startY: Int, endY: Int) {}

        func send(source: TerminalView, data: ArraySlice<UInt8>) {
            let str = String(bytes: data, encoding: .utf8) ?? ""
            parent.onOutput?(str)
        }

        func scrolled(source: TerminalView, position: Double) {}
        func clipboardCopy(source: TerminalView, content: Data) {}
        func iTermContent(source: TerminalView, content: Data) {}
    }
}
