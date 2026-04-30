import SwiftUI
import SwiftTerm

// MARK: - Terminal Session

@MainActor
class TerminalSession: ObservableObject, Identifiable {
    let id = UUID()
    let name: String
    let isSSH: Bool
    @Published var inputBuffer: String = ""
    @Published var currentLine: String = ""
    weak var terminalView: TerminalView?

    private(set) var shell: ShellInterpreter?
    var onOpenFile: ((String) -> Void)?

    init(name: String, isSSH: Bool = false, shell: ShellInterpreter? = nil) {
        self.name = name
        self.isSSH = isSSH
        self.shell = shell
    }

    func writeOutput(_ text: String) {
        let data = ArraySlice((text + "\r\n").utf8)
        terminalView?.feed(byteArray: data)
    }

    func showPrompt() {
        guard let shell else { return }
        let prompt = shell.prompt()
        let data = ArraySlice(prompt.utf8)
        terminalView?.feed(byteArray: data)
    }

    func handleInput(_ text: String) {
        guard let shell else { return }
        // Echo input + newline
        let echoData = ArraySlice((text + "\r\n").utf8)
        terminalView?.feed(byteArray: echoData)

        let result = shell.execute(text)
        if result == "__EXIT__" {
            writeOutput(ANSI.yellow("Session ended."))
            return
        }
        if result.hasPrefix("__OPEN__:") {
            let path = String(result.dropFirst("__OPEN__:".count))
            onOpenFile?(path)
        } else if !result.isEmpty {
            writeOutput(result)
        }
        showPrompt()
    }
}

// MARK: - TerminalPanel

struct TerminalPanel: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var manager = TerminalPanelManager()
    @State private var panelHeight: CGFloat = 260
    @State private var dragStart: CGFloat = 0
    @GestureState private var isDragging = false

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            dragHandle

            // Tab bar
            terminalTabBar

            Divider().background(appState.theme.borderColor)

            // Active terminal
            if let session = manager.activeSession {
                TerminalSessionView(session: session)
                    .background(appState.theme.editorBackground)
            }
        }
        .frame(height: panelHeight)
        .background(appState.theme.editorBackground)
        .overlay(Rectangle().fill(appState.theme.borderColor).frame(height: 1), alignment: .top)
        .onAppear {
            if manager.sessions.isEmpty {
                manager.addLocalSession(shell: ShellInterpreter())
            }
            manager.sessions.forEach { $0.onOpenFile = { path in
                // Tell AppState to open this file
                let node = FileNode(name: URL(fileURLWithPath: path).lastPathComponent,
                                   type: .file, path: path,
                                   url: URL(fileURLWithPath: path))
                if let content = try? String(contentsOf: URL(fileURLWithPath: path), encoding: .utf8) {
                    node.content = content
                }
                appState.openFile(node)
            }}
        }
    }

    private var dragHandle: some View {
        HStack {
            Spacer()
            RoundedRectangle(cornerRadius: 2)
                .fill(appState.theme.borderColor)
                .frame(width: 40, height: 4)
            Spacer()
        }
        .padding(.vertical, 6)
        .background(appState.theme.tabBarBackground)
        .gesture(
            DragGesture()
                .onChanged { value in
                    let delta = value.location.y - value.startLocation.y
                    panelHeight = max(120, min(600, panelHeight - delta))
                }
        )
    }

    private var terminalTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(manager.sessions) { session in
                    TerminalTabButton(
                        session: session,
                        isActive: session.id == manager.activeSession?.id,
                        onTap: { manager.activeSession = session },
                        onClose: { manager.removeSession(session) }
                    )
                }
                // New local tab
                Button {
                    manager.addLocalSession(shell: ShellInterpreter())
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 11))
                        .foregroundColor(appState.theme.secondaryText)
                        .padding(.horizontal, 10)
                        .frame(height: 30)
                }
                .buttonStyle(.plain)

                // SSH connect button
                Button {
                    appState.showingSSHConnect = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "network")
                            .font(.system(size: 11))
                        Text("SSH")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(appState.theme.accentColor)
                    .padding(.horizontal, 10)
                    .frame(height: 30)
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
        .background(appState.theme.tabBarBackground)
        .frame(height: 30)
    }
}

struct TerminalTabButton: View {
    @EnvironmentObject private var appState: AppState
    let session: TerminalSession
    let isActive: Bool
    let onTap: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: session.isSSH ? "network" : "terminal")
                .font(.system(size: 10))
                .foregroundColor(isActive ? appState.theme.accentColor : appState.theme.secondaryText)
            Text(session.name)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(isActive ? appState.theme.primaryText : appState.theme.secondaryText)
            if !session.isSSH || true {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9))
                        .foregroundColor(appState.theme.secondaryText)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 30)
        .background(isActive ? appState.theme.activeTabBackground : Color.clear)
        .overlay(Rectangle().fill(isActive ? appState.theme.accentColor : Color.clear).frame(height: 1), alignment: .bottom)
        .onTapGesture(perform: onTap)
    }
}

// MARK: - Terminal Session View

struct TerminalSessionView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var session: TerminalSession
    @State private var inputText: String = ""
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // SwiftTerm view
            TerminalEmulatorView(
                theme: appState.theme,
                input: $session.inputBuffer,
                onOutput: nil,
                onReady: { tv in
                    session.terminalView = tv
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        let banner = ANSI.cyan(ANSI.bold("ZedIPad Terminal")) + " — type 'help' for commands\r\n"
                        session.terminalView?.feed(byteArray: ArraySlice(banner.utf8))
                        session.showPrompt()
                    }
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Input bar
            HStack(spacing: 8) {
                Text(session.shell?.prompt() ?? "$ ")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(appState.theme.accentColor)
                    .lineLimit(1)

                TextField("", text: $inputText)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(appState.theme.primaryText)
                    .focused($inputFocused)
                    .autocorrectionDisabled()
                    .autocapitalization(.none)
                    .onSubmit {
                        let cmd = inputText
                        inputText = ""
                        session.handleInput(cmd)
                    }
                    .accessibilityLabel("Terminal input")
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(appState.theme.sidebarBackground)
            .overlay(Rectangle().fill(appState.theme.borderColor).frame(height: 1), alignment: .top)
        }
    }
}

// MARK: - Panel Manager

@MainActor
class TerminalPanelManager: ObservableObject {
    @Published var sessions: [TerminalSession] = []
    @Published var activeSession: TerminalSession?

    private var localCount = 0

    func addLocalSession(shell: ShellInterpreter) {
        localCount += 1
        let session = TerminalSession(name: "Terminal \(localCount)", isSSH: false, shell: shell)
        sessions.append(session)
        activeSession = session
    }

    func addSSHSession(name: String) {
        let session = TerminalSession(name: "SSH: \(name)", isSSH: true)
        sessions.append(session)
        activeSession = session
    }

    func removeSession(_ session: TerminalSession) {
        sessions.removeAll { $0.id == session.id }
        if activeSession?.id == session.id {
            activeSession = sessions.last
        }
    }
}
