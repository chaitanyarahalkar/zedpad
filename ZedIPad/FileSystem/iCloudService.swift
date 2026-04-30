import Foundation

@MainActor
class iCloudService {
    static let shared = iCloudService()

    var isAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    var documentsURL: URL? {
        guard isAvailable else { return nil }
        return FileManager.default.url(
            forUbiquityContainerIdentifier: nil
        )?.appendingPathComponent("Documents")
    }

    func startDownloading(url: URL) {
        guard isAvailable else { return }
        try? FileManager.default.startDownloadingUbiquitousItem(at: url)
    }

    func isDownloaded(url: URL) -> Bool {
        let values = try? url.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey])
        return values?.ubiquitousItemDownloadingStatus == .current
    }

    func isInCloud(url: URL) -> Bool {
        let values = try? url.resourceValues(forKeys: [.isUbiquitousItemKey])
        return values?.isUbiquitousItem == true
    }

    func iCloudRoot() -> FileNode? {
        guard isAvailable, let cloudURL = documentsURL else { return nil }
        let node = FileNode(
            name: "iCloud Drive",
            type: .directory,
            path: cloudURL.path,
            url: cloudURL,
            children: (try? FileSystemService.shared.loadDirectory(at: cloudURL))?.children ?? []
        )
        return node
    }
}
