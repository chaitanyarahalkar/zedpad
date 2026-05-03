import Foundation
import CryptoKit

// MARK: - Auth Method

enum SSHAuthMethod: Codable, Equatable {
    case password
    case keyPair(publicKey: String)

    enum CodingKeys: String, CodingKey { case type, publicKey }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let type = try c.decode(String.self, forKey: .type)
        switch type {
        case "keyPair":
            let pk = try c.decodeIfPresent(String.self, forKey: .publicKey) ?? ""
            self = .keyPair(publicKey: pk)
        default:
            self = .password
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .password:
            try c.encode("password", forKey: .type)
        case .keyPair(let pk):
            try c.encode("keyPair", forKey: .type)
            try c.encode(pk, forKey: .publicKey)
        }
    }
}

// MARK: - Connection Model

struct SSHConnection: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var host: String
    var port: Int = 22
    var username: String
    var authMethod: SSHAuthMethod = .password

    var displayName: String { name.isEmpty ? "\(username)@\(host)" : name }
    var isValid: Bool { !host.isEmpty && !username.isEmpty && port > 0 && port <= 65535 }
}

// MARK: - Connection State

enum SSHConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case failed(String)

    var isConnected: Bool { self == .connected }
    var description: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .connecting:   return "Connecting…"
        case .connected:    return "Connected"
        case .failed(let e): return "Failed: \(e)"
        }
    }
}

// MARK: - Server Store

@MainActor
class ServerStore: ObservableObject {
    @Published private(set) var connections: [SSHConnection] = []
    @Published var connectionStates: [UUID: SSHConnectionState] = [:]

    private let key = "zedipad.ssh.connections"

    init() { load() }

    func add(_ conn: SSHConnection) {
        connections.append(conn)
        save()
    }

    func update(_ conn: SSHConnection) {
        if let idx = connections.firstIndex(where: { $0.id == conn.id }) {
            connections[idx] = conn
            save()
        }
    }

    func delete(_ conn: SSHConnection) {
        connections.removeAll { $0.id == conn.id }
        connectionStates.removeValue(forKey: conn.id)
        SSHPasswordStore.delete(for: conn.id)
        save()
    }

    func setState(_ state: SSHConnectionState, for id: UUID) {
        connectionStates[id] = state
    }

    private func save() {
        if let data = try? JSONEncoder().encode(connections) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([SSHConnection].self, from: data) else { return }
        connections = decoded
    }
}

// MARK: - Password Keychain Store

enum SSHPasswordStore {
    private static let service = "com.zedipad.ssh.passwords"
    nonisolated(unsafe) private static var fallbackPasswords: [UUID: String] = [:]

    static func save(password: String, for id: UUID) {
        let data = password.data(using: .utf8) ?? Data()
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: id.uuidString,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        #if DEBUG
        if status != errSecSuccess {
            fallbackPasswords[id] = password
        }
        #endif
    }

    static func load(for id: UUID) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: id.uuidString,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else {
            #if DEBUG
            return fallbackPasswords[id]
            #else
            return nil
            #endif
        }
        return String(data: data, encoding: .utf8)
    }

    static func delete(for id: UUID) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: id.uuidString
        ]
        SecItemDelete(query as CFDictionary)
        #if DEBUG
        fallbackPasswords.removeValue(forKey: id)
        #endif
    }
}
