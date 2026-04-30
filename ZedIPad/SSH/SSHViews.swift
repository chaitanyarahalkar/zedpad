import SwiftUI

// MARK: - Server List View

struct ServerListView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var store = ServerStore()
    @State private var showingAdd = false
    @State private var editingConnection: SSHConnection?

    var body: some View {
        NavigationView {
            List {
                if store.connections.isEmpty {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "network")
                                .font(.system(size: 32))
                                .foregroundColor(appState.theme.secondaryText)
                            Text("No SSH Connections")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(appState.theme.primaryText)
                            Text("Add a server to connect via SSH")
                                .font(.system(size: 13))
                                .foregroundColor(appState.theme.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    }
                    .listRowBackground(appState.theme.editorBackground)
                }

                ForEach(store.connections) { conn in
                    ServerRow(connection: conn, store: store)
                        .listRowBackground(appState.theme.sidebarBackground)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                store.delete(conn)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button {
                                editingConnection = conn
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(appState.theme.accentColor)
                        }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(appState.theme.editorBackground)
            .navigationTitle("SSH Servers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { appState.showingSSHConnect = false }
                        .foregroundColor(appState.theme.accentColor)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(appState.theme.accentColor)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddServerView(store: store)
        }
        .sheet(item: $editingConnection) { conn in
            AddServerView(store: store, editing: conn)
        }
    }
}

struct ServerRow: View {
    @EnvironmentObject private var appState: AppState
    let connection: SSHConnection
    @ObservedObject var store: ServerStore

    private var state: SSHConnectionState {
        store.connectionStates[connection.id] ?? .disconnected
    }

    var body: some View {
        HStack(spacing: 12) {
            // Status dot
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(connection.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(appState.theme.primaryText)
                Text("\(connection.username)@\(connection.host):\(connection.port)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(appState.theme.secondaryText)
            }

            Spacer()

            // Auth badge
            Text(connection.authMethod == .password ? "PW" : "KEY")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(appState.theme.accentColor)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(appState.theme.accentColor, lineWidth: 1))

            // Connect button
            Button {
                connectToServer()
            } label: {
                Image(systemName: state.isConnected ? "xmark.circle" : "arrow.right.circle")
                    .font(.system(size: 16))
                    .foregroundColor(state.isConnected ? .red : appState.theme.accentColor)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private var statusColor: Color {
        switch state {
        case .connected:    return .green
        case .connecting:   return .yellow
        case .failed:       return .red
        case .disconnected: return appState.theme.secondaryText
        }
    }

    private func connectToServer() {
        // Opens an SSH terminal session in the terminal panel
        appState.showTerminal = true
        appState.showingSSHConnect = false
        store.setState(.connecting, for: connection.id)
        // Simulate connection for now (real SSH via Citadel when available)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            store.setState(.connected, for: connection.id)
        }
    }
}

// MARK: - Add / Edit Server

struct AddServerView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: ServerStore

    var editing: SSHConnection?

    @State private var name = ""
    @State private var host = ""
    @State private var port = "22"
    @State private var username = ""
    @State private var useKey = false
    @State private var password = ""
    @State private var publicKeyText = ""
    @State private var isGeneratingKey = false
    @State private var keyGenError: String?

    var body: some View {
        NavigationView {
            Form {
                Section("Server") {
                    FormField("Name (optional)", text: $name, placeholder: "My Server")
                    FormField("Host", text: $host, placeholder: "192.168.1.1 or hostname")
                    FormField("Port", text: $port, placeholder: "22")
                        .keyboardType(.numberPad)
                    FormField("Username", text: $username, placeholder: "root")
                }
                .listRowBackground(appState.theme.sidebarBackground)

                Section("Authentication") {
                    Toggle("Use SSH Key", isOn: $useKey)
                        .tint(appState.theme.accentColor)
                        .foregroundColor(appState.theme.primaryText)

                    if useKey {
                        if publicKeyText.isEmpty {
                            Button {
                                generateKey()
                            } label: {
                                if isGeneratingKey {
                                    HStack {
                                        ProgressView().scaleEffect(0.8)
                                        Text("Generating…")
                                    }
                                } else {
                                    Label("Generate Ed25519 Key Pair", systemImage: "key.fill")
                                }
                            }
                            .foregroundColor(appState.theme.accentColor)
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Public Key (add to ~/.ssh/authorized_keys):")
                                    .font(.system(size: 11))
                                    .foregroundColor(appState.theme.secondaryText)
                                Text(publicKeyText)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(appState.theme.primaryText)
                                    .lineLimit(3)
                                Button {
                                    UIPasteboard.general.string = publicKeyText
                                } label: {
                                    Label("Copy Public Key", systemImage: "doc.on.doc")
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(appState.theme.accentColor)
                            }
                        }
                        if let err = keyGenError {
                            Text(err).foregroundColor(.red).font(.system(size: 12))
                        }
                    } else {
                        SecureField("Password", text: $password)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(appState.theme.primaryText)
                    }
                }
                .listRowBackground(appState.theme.sidebarBackground)
            }
            .scrollContentBackground(.hidden)
            .background(appState.theme.editorBackground)
            .navigationTitle(editing == nil ? "Add Server" : "Edit Server")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(appState.theme.accentColor)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                        .foregroundColor(appState.theme.accentColor)
                        .disabled(!isValid)
                }
            }
        }
        .onAppear { populateIfEditing() }
    }

    private var isValid: Bool {
        !host.isEmpty && !username.isEmpty && (Int(port) ?? 0) > 0
    }

    private func populateIfEditing() {
        guard let conn = editing else { return }
        name = conn.name
        host = conn.host
        port = "\(conn.port)"
        username = conn.username
        if case .keyPair(let pk) = conn.authMethod {
            useKey = true
            publicKeyText = pk
        }
    }

    private func generateKey() {
        isGeneratingKey = true
        keyGenError = nil
        Task {
            do {
                let (_, pub) = try SSHKeyManager.generateKeyPair()
                await MainActor.run {
                    publicKeyText = pub
                    isGeneratingKey = false
                }
            } catch {
                await MainActor.run {
                    keyGenError = error.localizedDescription
                    isGeneratingKey = false
                }
            }
        }
    }

    private func save() {
        let authMethod: SSHAuthMethod = useKey ? .keyPair(publicKey: publicKeyText) : .password
        var conn = SSHConnection(
            name: name,
            host: host,
            port: Int(port) ?? 22,
            username: username,
            authMethod: authMethod
        )
        if let existing = editing { conn.id = existing.id }
        if !useKey && !password.isEmpty {
            SSHPasswordStore.save(password: password, for: conn.id)
        }
        if editing != nil { store.update(conn) } else { store.add(conn) }
        dismiss()
    }
}

struct FormField: View {
    @EnvironmentObject private var appState: AppState
    let label: String
    @Binding var text: String
    let placeholder: String

    init(_ label: String, text: Binding<String>, placeholder: String) {
        self.label = label
        _text = text
        self.placeholder = placeholder
    }

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(appState.theme.secondaryText)
                .frame(width: 120, alignment: .leading)
            TextField(placeholder, text: $text)
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(appState.theme.primaryText)
                .autocorrectionDisabled()
                .autocapitalization(.none)
        }
    }
}
