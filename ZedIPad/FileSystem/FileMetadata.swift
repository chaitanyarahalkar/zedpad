import Foundation

struct FileMetadata {
    let size: Int64
    let createdDate: Date?
    let modifiedDate: Date?
    let isReadable: Bool
    let isWritable: Bool

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var formattedModifiedDate: String {
        guard let date = modifiedDate else { return "Unknown" }
        let fmt = DateFormatter()
        fmt.dateStyle = .short
        fmt.timeStyle = .short
        return fmt.string(from: date)
    }

    var formattedCreatedDate: String {
        guard let date = createdDate else { return "Unknown" }
        let fmt = DateFormatter()
        fmt.dateStyle = .short
        fmt.timeStyle = .none
        return fmt.string(from: date)
    }
}
