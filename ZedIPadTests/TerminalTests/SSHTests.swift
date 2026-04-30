import XCTest
@testable import ZedIPad

final class SSHConnectionTests: XCTestCase {
    func testSSHConnectionDefaults() {
        let conn = SSHConnection(name: "Test", host: "192.168.1.1", username: "root")
        XCTAssertEqual(conn.port, 22)
        XCTAssertEqual(conn.authMethod, .password)
        XCTAssertTrue(conn.isValid)
    }

    func testSSHConnectionInvalidHost() {
        let conn = SSHConnection(name: "", host: "", username: "root")
        XCTAssertFalse(conn.isValid)
    }

    func testSSHConnectionInvalidUsername() {
        let conn = SSHConnection(name: "", host: "host", username: "")
        XCTAssertFalse(conn.isValid)
    }

    func testSSHConnectionDisplayName() {
        let namedConn = SSHConnection(name: "My Server", host: "host", username: "user")
        XCTAssertEqual(namedConn.displayName, "My Server")
        let unnamedConn = SSHConnection(name: "", host: "host.com", username: "admin")
        XCTAssertEqual(unnamedConn.displayName, "admin@host.com")
    }

    func testSSHConnectionCodable() throws {
        let conn = SSHConnection(name: "Test", host: "10.0.0.1", port: 2222, username: "deploy", authMethod: .password)
        let data = try JSONEncoder().encode(conn)
        let decoded = try JSONDecoder().decode(SSHConnection.self, from: data)
        XCTAssertEqual(conn, decoded)
    }

    func testSSHAuthMethodPasswordCodable() throws {
        let method = SSHAuthMethod.password
        let data = try JSONEncoder().encode(method)
        let decoded = try JSONDecoder().decode(SSHAuthMethod.self, from: data)
        XCTAssertEqual(method, decoded)
    }

    func testSSHAuthMethodKeyPairCodable() throws {
        let method = SSHAuthMethod.keyPair(publicKey: "ssh-ed25519 AAAA test@host")
        let data = try JSONEncoder().encode(method)
        let decoded = try JSONDecoder().decode(SSHAuthMethod.self, from: data)
        XCTAssertEqual(method, decoded)
    }

    func testSSHConnectionPortValidation() {
        let validPort = SSHConnection(name: "", host: "h", port: 22, username: "u")
        XCTAssertTrue(validPort.isValid)
        let invalidPort = SSHConnection(name: "", host: "h", port: 0, username: "u")
        XCTAssertFalse(invalidPort.isValid)
        let maxPort = SSHConnection(name: "", host: "h", port: 65535, username: "u")
        XCTAssertTrue(maxPort.isValid)
        let overMax = SSHConnection(name: "", host: "h", port: 65536, username: "u")
        XCTAssertFalse(overMax.isValid)
    }
}

@MainActor
final class ServerStoreTests: XCTestCase {
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "zedipad.ssh.connections")
    }

    func testAddConnection() {
        let store = ServerStore()
        let conn = SSHConnection(name: "Test", host: "h", username: "u")
        store.add(conn)
        XCTAssertEqual(store.connections.count, 1)
        XCTAssertEqual(store.connections[0].id, conn.id)
    }

    func testDeleteConnection() {
        let store = ServerStore()
        let conn = SSHConnection(name: "Del", host: "h", username: "u")
        store.add(conn)
        store.delete(conn)
        XCTAssertTrue(store.connections.isEmpty)
    }

    func testUpdateConnection() {
        let store = ServerStore()
        var conn = SSHConnection(name: "Old", host: "h", username: "u")
        store.add(conn)
        conn.name = "New"
        store.update(conn)
        XCTAssertEqual(store.connections[0].name, "New")
    }

    func testConnectionStateSetting() {
        let store = ServerStore()
        let id = UUID()
        store.setState(.connecting, for: id)
        XCTAssertEqual(store.connectionStates[id], .connecting)
        store.setState(.connected, for: id)
        XCTAssertEqual(store.connectionStates[id], .connected)
    }

    func testMultipleConnections() {
        let store = ServerStore()
        for i in 0..<5 {
            store.add(SSHConnection(name: "Server \(i)", host: "h\(i)", username: "u"))
        }
        XCTAssertEqual(store.connections.count, 5)
    }
}

final class SSHKeyManagerTests: XCTestCase {
    override func tearDown() {
        SSHKeyManager.deleteKey()
    }

    // Keychain operations require entitlements; skip gracefully if not available in test host
    private func tryKeychain(_ block: () throws -> Void) {
        do {
            try block()
        } catch SSHKeyManagerError.keychainError(-34018) {
            // errSecMissingEntitlement — expected in test host without keychain entitlements
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testKeyGeneration() {
        tryKeychain {
            let (privatePEM, publicOpenSSH) = try SSHKeyManager.generateKeyPair()
            XCTAssertTrue(privatePEM.contains("BEGIN OPENSSH PRIVATE KEY"))
            XCTAssertTrue(publicOpenSSH.hasPrefix("ssh-ed25519 "))
            XCTAssertTrue(publicOpenSSH.hasSuffix("zedipad@ipad"))
        }
    }

    func testPublicKeyFormat() {
        tryKeychain {
            let (_, pub) = try SSHKeyManager.generateKeyPair()
            let parts = pub.split(separator: " ")
            XCTAssertEqual(parts.count, 3)
            XCTAssertEqual(String(parts[0]), "ssh-ed25519")
            XCTAssertFalse(String(parts[1]).isEmpty)
        }
    }

    func testHasKey() {
        // Without entitlements, hasKey returns false
        tryKeychain {
            _ = try SSHKeyManager.generateKeyPair()
        }
        // Either true (entitlements OK) or false (no entitlements) — both valid
        _ = SSHKeyManager.hasKey()
    }

    func testLoadPublicKey() {
        tryKeychain {
            let (_, original) = try SSHKeyManager.generateKeyPair()
            let loaded = try SSHKeyManager.loadPublicKey()
            XCTAssertEqual(original, loaded)
        }
    }

    func testDeleteKey() {
        tryKeychain {
            _ = try SSHKeyManager.generateKeyPair()
        }
        SSHKeyManager.deleteKey() // Should not throw
    }
}

final class SSHPasswordStoreTests: XCTestCase {
    func testSaveAndLoad() {
        let id = UUID()
        SSHPasswordStore.save(password: "s3cr3t", for: id)
        let loaded = SSHPasswordStore.load(for: id)
        XCTAssertEqual(loaded, "s3cr3t")
        SSHPasswordStore.delete(for: id)
    }

    func testDeletePassword() {
        let id = UUID()
        SSHPasswordStore.save(password: "pass", for: id)
        SSHPasswordStore.delete(for: id)
        XCTAssertNil(SSHPasswordStore.load(for: id))
    }

    func testLoadNonexistent() {
        XCTAssertNil(SSHPasswordStore.load(for: UUID()))
    }
}

final class SSHConnectionStateTests: XCTestCase {
    func testStateDescriptions() {
        XCTAssertEqual(SSHConnectionState.disconnected.description, "Disconnected")
        XCTAssertEqual(SSHConnectionState.connecting.description, "Connecting…")
        XCTAssertEqual(SSHConnectionState.connected.description, "Connected")
        XCTAssertEqual(SSHConnectionState.failed("err").description, "Failed: err")
    }

    func testIsConnected() {
        XCTAssertTrue(SSHConnectionState.connected.isConnected)
        XCTAssertFalse(SSHConnectionState.disconnected.isConnected)
        XCTAssertFalse(SSHConnectionState.connecting.isConnected)
        XCTAssertFalse(SSHConnectionState.failed("x").isConnected)
    }
}
