import SwiftUI
import SwiftTerm

// MARK: - Terminal Session

@MainActor
class TerminalSession: ObservableObject, Identifiable {
    let id = UUID()
    let name: String
    let isSSH: Bool
    @Published var inputBuffer: String = ""
    weak var terminalView: TerminalView?

    private(set) var shell: ShellInterpreter?
    var onOpenFile: ((String) -> Void)?

    init(name: String, isSSH: Bool = false, shell: ShellInterpreter? = nil) {
        self.name = name
        self.isSSH = isSSH
        self.shell = shell
    }

    func writeOutput(_ text: String) {
        // Normalize bare \n → \r\n so every line returns to column 0 on VT100
        let normalized = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\n", with: "\r\n")
        let data = ArraySlice((normalized + "\r\n").utf8)
        terminalView?.feed(byteArray: data)
    }

    func showPrompt() {
        guard let shell else { return }
        let prompt = shell.prompt()
        terminalView?.feed(byteArray: ArraySlice(prompt.utf8))
    }

    // Called by SwiftTerm delegate for each keystroke
    private var lineBuffer: String = ""

    func handleKeystroke(_ text: String) {
        for char in text {
            switch char {
            case "\r", "\n":
                let cmd = lineBuffer
                lineBuffer = ""
                handleInput(cmd)
            case "\u{7F}", "\u{08}": // backspace / DEL
                if !lineBuffer.isEmpty {
                    lineBuffer.removeLast()
                    // Erase one char on screen: move back, space, move back
                    terminalView?.feed(byteArray: ArraySlice("\u{08} \u{08}".utf8))
                }
            default:
                lineBuffer.append(char)
                // Echo the character to the terminal
                terminalView?.feed(byteArray: ArraySlice(String(char).utf8))
            }
        }
    }

    func handleInput(_ text: String) {
        guard let shell else { return }
        // Characters were already echoed one-by-one in handleKeystroke — just move to next line
        terminalView?.feed(byteArray: ArraySlice("\r\n".utf8))
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
    @State private var panelHeight: CGFloat = max(280, UIScreen.main.bounds.height * 0.35)
    @State private var showingAddCodex = false

    var body: some View {
        VStack(spacing: 0) {
            dragHandle
            terminalTabBar
            Divider().background(appState.theme.borderColor)
            // Show either terminal session or codex agent tab
            if let codexSession = manager.activeCodexSession {
                CodexAgentTab(session: codexSession)
            } else if let session = manager.activeSession {
                TerminalSessionView(session: session)
                    .background(appState.theme.editorBackground)
            }
        }
        .frame(height: panelHeight)
        .background(appState.theme.editorBackground)
        .overlay(Rectangle().fill(appState.theme.borderColor).frame(height: 1), alignment: .top)
        .sheet(isPresented: $showingAddCodex) {
            AddCodexServerView(onAdd: { config, token in
                manager.addCodexSession(config: config)
            })
        }
        .onAppear {
            if manager.sessions.isEmpty {
                manager.addLocalSession(shell: ShellInterpreter())
            }
            manager.sessions.forEach { session in
                session.onOpenFile = { path in
                    let node = FileNode(name: URL(fileURLWithPath: path).lastPathComponent,
                                       type: .file, path: path,
                                       url: URL(fileURLWithPath: path))
                    if let content = try? String(contentsOf: URL(fileURLWithPath: path), encoding: .utf8) {
                        node.content = content
                    }
                    appState.openFile(node)
                }
            }
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

                Button {
                    appState.showingSSHConnect = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "network").font(.system(size: 11))
                        Text("SSH").font(.system(size: 11))
                    }
                    .foregroundColor(appState.theme.accentColor)
                    .padding(.horizontal, 10)
                    .frame(height: 30)
                }
                .buttonStyle(.plain)

                // Codex agent tabs
                ForEach(manager.codexSessions) { codex in
                    CodexTabButton(
                        session: codex,
                        isActive: manager.activeCodexSession?.id == codex.id,
                        onTap: { manager.activeCodexSession = codex; manager.activeSession = nil },
                        onClose: { manager.removeCodexSession(codex) }
                    )
                }

                Button {
                    showingAddCodex = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles").font(.system(size: 11))
                        Text("Agent").font(.system(size: 11))
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
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 9))
                    .foregroundColor(appState.theme.secondaryText)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .frame(height: 30)
        .background(isActive ? appState.theme.activeTabBackground : Color.clear)
        .overlay(Rectangle().fill(isActive ? appState.theme.accentColor : Color.clear).frame(height: 1), alignment: .bottom)
        .onTapGesture(perform: onTap)
    }
}

// MARK: - Terminal Session View (SwiftTerm-only, no separate input bar)

struct TerminalSessionView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var session: TerminalSession

    var body: some View {
        TerminalEmulatorView(
            theme: appState.theme,
            input: $session.inputBuffer,
            onOutput: { keystroke in
                // SwiftTerm sends keystrokes here via its delegate
                // Accumulate until newline, then dispatch to shell
                session.handleKeystroke(keystroke)
            },
            onReady: { tv in
                session.terminalView = tv
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    let banner = ANSI.cyan(ANSI.bold("ZedIPad Terminal")) + " — type 'help' for commands\r\n"
                    tv.feed(byteArray: ArraySlice(banner.utf8))
                    session.showPrompt()
                    tv.becomeFirstResponder()
                }
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onTapGesture {
            session.terminalView?.becomeFirstResponder()
        }
    }
}

// MARK: - Codex tab button

struct CodexTabButton: View {
    @EnvironmentObject private var appState: AppState
    let session: CodexSession
    let isActive: Bool
    let onTap: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.system(size: 10))
                .foregroundColor(isActive ? appState.theme.accentColor : appState.theme.secondaryText)
            Text(session.config.name)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(isActive ? appState.theme.primaryText : appState.theme.secondaryText)
            Circle()
                .fill(session.isConnected ? Color.green : Color.red)
                .frame(width: 5, height: 5)
            Button(action: onClose) {
                Image(systemName: "xmark").font(.system(size: 9))
                    .foregroundColor(appState.theme.secondaryText)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .frame(height: 30)
        .background(isActive ? appState.theme.activeTabBackground : Color.clear)
        .overlay(Rectangle().fill(isActive ? appState.theme.accentColor : Color.clear).frame(height: 1), alignment: .bottom)
        .onTapGesture(perform: onTap)
    }
}

// MARK: - Panel Manager

@MainActor
class TerminalPanelManager: ObservableObject {
    @Published var sessions: [TerminalSession] = []
    @Published var activeSession: TerminalSession?
    @Published var codexSessions: [CodexSession] = []
    @Published var activeCodexSession: CodexSession?
    private var localCount = 0

    func addLocalSession(shell: ShellInterpreter) {
        localCount += 1
        let session = TerminalSession(name: "Terminal \(localCount)", isSSH: false, shell: shell)
        sessions.append(session)
        activeSession = session
        activeCodexSession = nil
    }

    func addSSHSession(name: String) {
        let session = TerminalSession(name: "SSH: \(name)", isSSH: true)
        sessions.append(session)
        activeSession = session
        activeCodexSession = nil
    }

    func removeSession(_ session: TerminalSession) {
        sessions.removeAll { $0.id == session.id }
        if activeSession?.id == session.id { activeSession = sessions.last }
    }

    func addCodexSession(config: CodexServerConfig, token: String = "") {
        let session = CodexSession(config: config)
        session.token = token
        codexSessions.append(session)
        activeCodexSession = session
        activeSession = nil
    }

    func removeCodexSession(_ session: CodexSession) {
        session.disconnect()
        codexSessions.removeAll { $0.id == session.id }
        if activeCodexSession?.id == session.id {
            activeCodexSession = codexSessions.last
            if activeCodexSession == nil { activeSession = sessions.last }
        }
    }
}
