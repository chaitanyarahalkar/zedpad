import Foundation
import CryptoKit

// MARK: - Known Host Entry

struct KnownHost: Codable, Equatable {
    var hostname: String
    var port: Int
    var fingerprint: String
    var addedDate: Date

    var key: String { "\(hostname):\(port)" }
}

// MARK: - Manager

@MainActor
class KnownHostsManager {
    static let shared = KnownHostsManager()
    private let userDefaultsKey = "zedipad.knownhosts"
    private var hosts: [String: KnownHost] = [:]

    init() { load() }

    enum TrustResult {
        case trusted
        case unknown(fingerprint: String)
        case mismatch(expected: String, actual: String)
    }

    func check(host: String, port: Int = 22, fingerprint: String) -> TrustResult {
        let key = "\(host):\(port)"
        if let known = hosts[key] {
            return known.fingerprint == fingerprint
                ? .trusted
                : .mismatch(expected: known.fingerprint, actual: fingerprint)
        }
        return .unknown(fingerprint: fingerprint)
    }

    func trust(host: String, port: Int = 22, fingerprint: String) {
        let key = "\(host):\(port)"
        hosts[key] = KnownHost(hostname: host, port: port, fingerprint: fingerprint, addedDate: Date())
        save()
    }

    func remove(host: String, port: Int = 22) {
        hosts.removeValue(forKey: "\(host):\(port)")
        save()
    }

    func allHosts() -> [KnownHost] {
        Array(hosts.values).sorted { $0.hostname < $1.hostname }
    }

    func fingerprintFor(host: String, port: Int = 22) -> String? {
        hosts["\(host):\(port)"]?.fingerprint
    }

    static func simulateFingerprint(for host: String) -> String {
        // Deterministic mock fingerprint for testing
        let data = Data((host + "zedipad").utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02X", $0) }.joined(separator: ":")
    }

    private func save() {
        if let data = try? JSONEncoder().encode(Array(hosts.values)) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([KnownHost].self, from: data) else { return }
        hosts = Dictionary(uniqueKeysWithValues: decoded.map { ($0.key, $0) })
    }
}
