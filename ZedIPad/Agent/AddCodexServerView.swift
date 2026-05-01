import SwiftUI

struct AddCodexServerView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var wsURL = "ws://192.168.1.100:4500"
    @State private var token = ""
    @State private var model = "codex-mini-latest"
    @State private var isTesting = false
    @State private var testResult: Bool? = nil
    @State private var onConnect: ((CodexServerConfig, String) -> Void)?

    var onAdd: ((CodexServerConfig, String) -> Void)?

    private let models = ["codex-mini-latest", "o4-mini", "o3", "gpt-4o"]

    var body: some View {
        NavigationView {
            Form {
                Section("Server") {
                    TextField("Name", text: $name)
                        .autocorrectionDisabled()
                    TextField("WebSocket URL", text: $wsURL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.asciiCapable)
                    SecureField("Auth Token", text: $token)
                }

                Section("Model") {
                    Picker("Model", selection: $model) {
                        ForEach(models, id: \.self) { Text($0).tag($0) }
                    }
                }

                Section {
                    Button {
                        testConnection()
                    } label: {
                        HStack {
                            if isTesting {
                                ProgressView().scaleEffect(0.8)
                            } else {
                                Image(systemName: "network")
                            }
                            Text("Test Connection")
                            Spacer()
                            if let result = testResult {
                                Image(systemName: result ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(result ? .green : .red)
                            }
                        }
                    }
                    .disabled(wsURL.isEmpty || token.isEmpty || isTesting)
                }

                if testResult == false {
                    Section {
                        Text("Connection failed. Make sure the Codex app-server is running:\ncodex app-server --listen \(wsURL)")
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Add Codex Server")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Connect") {
                        let config = CodexServerConfig(name: name.isEmpty ? wsURL : name, wsURL: wsURL, model: model)
                        appState.codexServerStore.add(config, token: token)
                        onAdd?(config, token)
                        dismiss()
                    }
                    .disabled(wsURL.isEmpty || token.isEmpty)
                }
            }
        }
    }

    private func testConnection() {
        isTesting = true
        testResult = nil
        Task {
            let ok = await appState.codexServerStore.testConnection(wsURL: wsURL, token: token)
            isTesting = false
            testResult = ok
        }
    }
}
