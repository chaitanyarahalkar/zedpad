import Foundation
import Security
import SwiftUI

struct CodexServerConfig: Codable, Identifiable {
    let id: UUID
    var name: String
    var wsURL: String
    var model: String

    init(id: UUID = UUID(), name: String, wsURL: String, model: String) {
        self.id = id; self.name = name; self.wsURL = wsURL; self.model = model
    }
}

@MainActor
class CodexServerStore: ObservableObject {
    @Published var servers: [CodexServerConfig] = []
    private let configsKey = "codex_server_configs"

    init() { load() }

    // MARK: - CRUD

    func add(_ config: CodexServerConfig, token: String) {
        servers.append(config)
        saveToken(token, for: config.id)
        persist()
    }

    func remove(_ config: CodexServerConfig) {
        servers.removeAll { $0.id == config.id }
        deleteToken(for: config.id)
        persist()
    }

    func update(_ config: CodexServerConfig, token: String? = nil) {
        if let idx = servers.firstIndex(where: { $0.id == config.id }) {
            servers[idx] = config
        }
        if let token { saveToken(token, for: config.id) }
        persist()
    }

    func token(for config: CodexServerConfig) -> String {
        loadToken(for: config.id) ?? ""
    }

    // MARK: - Persistence

    private func persist() {
        if let data = try? JSONEncoder().encode(servers) {
            UserDefaults.standard.set(data, forKey: configsKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: configsKey),
              let decoded = try? JSONDecoder().decode([CodexServerConfig].self, from: data)
        else { return }
        servers = decoded
    }

    // MARK: - Keychain

    private func saveToken(_ token: String, for id: UUID) {
        let data = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.zedipad.codex",
            kSecAttrAccount as String: id.uuidString,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func loadToken(for id: UUID) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.zedipad.codex",
            kSecAttrAccount as String: id.uuidString,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func deleteToken(for id: UUID) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.zedipad.codex",
            kSecAttrAccount as String: id.uuidString
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Health check

    func testConnection(wsURL: String, token: String) async -> Bool {
        // Convert ws:// to http:// for /readyz check
        let httpURL = wsURL.replacingOccurrences(of: "ws://", with: "http://")
                          .replacingOccurrences(of: "wss://", with: "https://")
        guard let url = URL(string: httpURL + "/readyz") else { return false }
        var req = URLRequest(url: url, timeoutInterval: 5)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        do {
            let (_, response) = try await URLSession.shared.data(for: req)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch { return false }
    }
}
