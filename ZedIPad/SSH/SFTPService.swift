import Foundation

// MARK: - SFTP Error

enum SFTPError: Error, LocalizedError {
    case notConnected
    case permissionDenied(String)
    case fileNotFound(String)
    case connectionLost
    case transferFailed(String)

    var errorDescription: String? {
        switch self {
        case .notConnected:         return "Not connected to SSH server"
        case .permissionDenied(let p): return "Permission denied: \(p)"
        case .fileNotFound(let p):  return "File not found: \(p)"
        case .connectionLost:       return "SSH connection lost"
        case .transferFailed(let m): return "Transfer failed: \(m)"
        }
    }
}

// MARK: - Remote File Entry

struct RemoteFileEntry: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let isDirectory: Bool
    let size: Int64
    let modifiedDate: Date
    let permissions: String

    var fileExtension: String {
        (name as NSString).pathExtension.lowercased()
    }
}

// MARK: - SFTP Session Protocol (mockable)

protocol SFTPSessionProtocol: Sendable {
    func listDirectory(_ path: String) async throws -> [RemoteFileEntry]
    func readFile(_ path: String) async throws -> Data
    func writeFile(_ path: String, data: Data) async throws
    func createDirectory(_ path: String) async throws
    func deleteFile(_ path: String) async throws
    func rename(from: String, to: String) async throws
    func fileExists(_ path: String) async throws -> Bool
}

// MARK: - Mock SFTP Session (used when Citadel not available)

final class MockSFTPSession: SFTPSessionProtocol, @unchecked Sendable {
    private var filesystem: [String: Data] = [
        "/home/user/projects/README.md": Data("# My Project\n\nA sample project.".utf8),
        "/home/user/projects/main.py": Data("#!/usr/bin/env python3\nprint('hello')".utf8),
        "/home/user/.bashrc": Data("export PATH=$HOME/bin:$PATH".utf8),
    ]
    private var directories: Set<String> = ["/", "/home", "/home/user", "/home/user/projects", "/var", "/etc"]

    func listDirectory(_ path: String) async throws -> [RemoteFileEntry] {
        let normalizedPath = normalize(path)
        var entries: [RemoteFileEntry] = []

        // Sub-dirs
        for dir in directories where dir != normalizedPath {
            let parent = parentPath(for: dir)
            if parent == normalizedPath {
                entries.append(RemoteFileEntry(name: dir.components(separatedBy: "/").last ?? "",
                    path: dir, isDirectory: true, size: 0, modifiedDate: Date(), permissions: "drwxr-xr-x"))
            }
        }

        // Files
        for (filePath, data) in filesystem {
            let parent = parentPath(for: filePath)
            if parent == normalizedPath {
                let name = filePath.components(separatedBy: "/").last ?? ""
                entries.append(RemoteFileEntry(name: name, path: filePath, isDirectory: false,
                    size: Int64(data.count), modifiedDate: Date(), permissions: "-rw-r--r--"))
            }
        }

        return entries.sorted { $0.name < $1.name }
    }

    private func normalize(_ path: String) -> String {
        guard path != "/" else { return "/" }
        return path.hasSuffix("/") ? String(path.dropLast()) : path
    }

    private func parentPath(for path: String) -> String {
        let normalized = normalize(path)
        guard normalized != "/" else { return "/" }
        let parts = normalized.split(separator: "/")
        guard parts.count > 1 else { return "/" }
        return "/" + parts.dropLast().joined(separator: "/")
    }

    func readFile(_ path: String) async throws -> Data {
        guard let data = filesystem[path] else { throw SFTPError.fileNotFound(path) }
        return data
    }

    func writeFile(_ path: String, data: Data) async throws {
        filesystem[path] = data
    }

    func createDirectory(_ path: String) async throws {
        directories.insert(path)
    }

    func deleteFile(_ path: String) async throws {
        if filesystem[path] != nil { filesystem.removeValue(forKey: path) }
        else if directories.contains(path) { directories.remove(path) }
        else { throw SFTPError.fileNotFound(path) }
    }

    func rename(from: String, to: String) async throws {
        if let data = filesystem[from] {
            filesystem[to] = data
            filesystem.removeValue(forKey: from)
        } else if directories.contains(from) {
            directories.remove(from)
            directories.insert(to)
        } else {
            throw SFTPError.fileNotFound(from)
        }
    }

    func fileExists(_ path: String) async throws -> Bool {
        filesystem[path] != nil || directories.contains(path)
    }
}

// MARK: - SFTP Service

@MainActor
class SFTPService: ObservableObject {
    @Published var isConnected: Bool = false
    @Published var currentPath: String = "/home/user"
    @Published var entries: [RemoteFileEntry] = []
    @Published var lastError: String?

    let connection: SSHConnection
    private var session: any SFTPSessionProtocol

    init(connection: SSHConnection, session: (any SFTPSessionProtocol)? = nil) {
        self.connection = connection
        self.session = session ?? MockSFTPSession()
    }

    func connect() async {
        isConnected = true
        await listDirectory(currentPath)
    }

    func listDirectory(_ path: String) async {
        do {
            let result = try await session.listDirectory(path)
            entries = result
            currentPath = path
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func readFile(_ path: String) async throws -> String {
        let data = try await session.readFile(path)
        return String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) ?? ""
    }

    func writeFile(_ path: String, content: String) async throws {
        guard let data = content.data(using: .utf8) else {
            throw SFTPError.transferFailed("Cannot encode content as UTF-8")
        }
        try await session.writeFile(path, data: data)
    }

    func createDirectory(_ path: String) async throws {
        try await session.createDirectory(path)
        await listDirectory(currentPath)
    }

    func deleteFile(_ path: String) async throws {
        try await session.deleteFile(path)
        await listDirectory(currentPath)
    }

    func rename(from: String, to: String) async throws {
        try await session.rename(from: from, to: to)
        await listDirectory(currentPath)
    }
}
