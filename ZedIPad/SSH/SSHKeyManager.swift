import Foundation
import CryptoKit
import Security

enum SSHKeyManagerError: Error, LocalizedError {
    case keyGenerationFailed
    case keychainError(OSStatus)
    case noKeyFound

    var errorDescription: String? {
        switch self {
        case .keyGenerationFailed:     return "Failed to generate SSH key pair"
        case .keychainError(let s):    return "Keychain error: \(s)"
        case .noKeyFound:              return "No SSH key found"
        }
    }
}

class SSHKeyManager {
    private static let privateKeyService = "com.zedipad.ssh.privatekey"
    private static let privateKeyAccount = "ed25519-private"

    // MARK: - Generate

    static func generateKeyPair() throws -> (privateKeyPEM: String, publicKeyOpenSSH: String) {
        let privateKey = Curve25519.Signing.PrivateKey()
        let publicKey = privateKey.publicKey

        let privateKeyData = privateKey.rawRepresentation
        let publicKeyData = publicKey.rawRepresentation

        // Store private key in Keychain
        try savePrivateKey(privateKeyData)

        // Format public key as OpenSSH
        let openSSHPub = encodeOpenSSHPublicKey(publicKeyData)

        // Format private key as PEM-like string (base64 for display)
        let privatePEM = "-----BEGIN OPENSSH PRIVATE KEY-----\n" +
            privateKeyData.base64EncodedString(options: .lineLength64Characters) +
            "\n-----END OPENSSH PRIVATE KEY-----"

        return (privatePEM, openSSHPub)
    }

    // MARK: - Load / Delete

    static func loadPublicKey() throws -> String {
        let privateData = try loadPrivateKey()
        let privateKey = try Curve25519.Signing.PrivateKey(rawRepresentation: privateData)
        return encodeOpenSSHPublicKey(privateKey.publicKey.rawRepresentation)
    }

    static func hasKey() -> Bool {
        (try? loadPrivateKey()) != nil
    }

    static func deleteKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: privateKeyService,
            kSecAttrAccount as String: privateKeyAccount
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Keychain helpers

    private static func savePrivateKey(_ data: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: privateKeyService,
            kSecAttrAccount as String: privateKeyAccount,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw SSHKeyManagerError.keychainError(status) }
    }

    private static func loadPrivateKey() throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: privateKeyService,
            kSecAttrAccount as String: privateKeyAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            throw SSHKeyManagerError.noKeyFound
        }
        return data
    }

    // MARK: - OpenSSH public key format

    /// Encodes a 32-byte Ed25519 public key as: "ssh-ed25519 <base64> zedipad"
    static func encodeOpenSSHPublicKey(_ keyData: Data) -> String {
        let keyType = "ssh-ed25519"
        var blob = Data()

        // Length-prefixed key type
        let typeBytes = keyType.data(using: .utf8)!
        blob.append(contentsOf: withUInt32BigEndian(UInt32(typeBytes.count)))
        blob.append(typeBytes)

        // Length-prefixed key data
        blob.append(contentsOf: withUInt32BigEndian(UInt32(keyData.count)))
        blob.append(keyData)

        return "\(keyType) \(blob.base64EncodedString()) zedipad@ipad"
    }

    private static func withUInt32BigEndian(_ value: UInt32) -> [UInt8] {
        [
            UInt8((value >> 24) & 0xFF),
            UInt8((value >> 16) & 0xFF),
            UInt8((value >> 8)  & 0xFF),
            UInt8( value        & 0xFF)
        ]
    }
}
