import Foundation

@MainActor
class FileSystemService {
    static let shared = FileSystemService()

    private let fm = FileManager.default

    var documentsURL: URL {
        fm.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    func loadDirectory(at url: URL) throws -> FileNode {
        let name = url.lastPathComponent
        let contents = try fm.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )
        let children: [FileNode] = contents.compactMap { childURL in
            let isDir = (try? childURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            if isDir {
                return (try? loadDirectory(at: childURL)) ?? FileNode(
                    name: childURL.lastPathComponent, type: .directory,
                    path: childURL.path, url: childURL, children: []
                )
            } else {
                return FileNode(
                    name: childURL.lastPathComponent, type: .file,
                    path: childURL.path, url: childURL
                )
            }
        }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        return FileNode(name: name, type: .directory, path: url.path, url: url, children: children)
    }

    func createFile(named name: String, in directoryURL: URL, content: String = "") throws -> URL {
        let fileURL = directoryURL.appendingPathComponent(name)
        let data = content.data(using: .utf8) ?? Data()
        guard fm.createFile(atPath: fileURL.path, contents: data) else {
            throw FSError.createFailed(fileURL.path)
        }
        return fileURL
    }

    func createDirectory(named name: String, in parentURL: URL) throws -> URL {
        let dirURL = parentURL.appendingPathComponent(name)
        try fm.createDirectory(at: dirURL, withIntermediateDirectories: true)
        return dirURL
    }

    func delete(at url: URL) throws {
        try fm.removeItem(at: url)
    }

    func rename(at url: URL, to newName: String) throws -> URL {
        let newURL = url.deletingLastPathComponent().appendingPathComponent(newName)
        try fm.moveItem(at: url, to: newURL)
        return newURL
    }

    func move(from sourceURL: URL, to destinationURL: URL) throws {
        try fm.moveItem(at: sourceURL, to: destinationURL)
    }

    func copy(from sourceURL: URL, to destinationURL: URL) throws {
        try fm.copyItem(at: sourceURL, to: destinationURL)
    }

    func readFile(at url: URL) throws -> String {
        try String(contentsOf: url, encoding: .utf8)
    }

    func writeFile(at url: URL, content: String) throws {
        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    func attributes(at url: URL) throws -> FileMetadata {
        let attrs = try fm.attributesOfItem(atPath: url.path)
        return FileMetadata(
            size: attrs[.size] as? Int64 ?? 0,
            createdDate: attrs[.creationDate] as? Date,
            modifiedDate: attrs[.modificationDate] as? Date,
            isReadable: fm.isReadableFile(atPath: url.path),
            isWritable: fm.isWritableFile(atPath: url.path)
        )
    }

    enum FSError: LocalizedError {
        case createFailed(String)
        case notFound(String)

        var errorDescription: String? {
            switch self {
            case .createFailed(let path): return "Failed to create file at \(path)"
            case .notFound(let path): return "File not found: \(path)"
            }
        }
    }
}
