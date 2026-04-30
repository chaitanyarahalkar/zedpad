import SwiftUI

// MARK: - Remote File Tree

struct RemoteFileTreeView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var sftp: SFTPService
    @State private var expandedPaths: Set<String> = []

    init(connection: SSHConnection) {
        _sftp = StateObject(wrappedValue: SFTPService(connection: connection))
    }

    var body: some View {
        ZStack {
            appState.theme.sidebarBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                // Path breadcrumb
                HStack {
                    Image(systemName: "network")
                        .font(.system(size: 11))
                        .foregroundColor(appState.theme.accentColor)
                    Text(sftp.connection.host)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(appState.theme.secondaryText)
                    Spacer()
                    if sftp.isConnected {
                        Circle().fill(Color.green).frame(width: 6, height: 6)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(appState.theme.tabBarBackground)
                .overlay(Rectangle().fill(appState.theme.borderColor).frame(height: 1), alignment: .bottom)

                if let error = sftp.lastError {
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                        .padding(8)
                }

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(sftp.entries) { entry in
                            RemoteFileRowView(entry: entry, sftp: sftp)
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .task {
            await sftp.connect()
        }
    }
}

struct RemoteFileRowView: View {
    @EnvironmentObject private var appState: AppState
    let entry: RemoteFileEntry
    @ObservedObject var sftp: SFTPService

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: entry.isDirectory ? "folder.fill" : iconForExtension(entry.fileExtension))
                .font(.system(size: 13))
                .foregroundColor(entry.isDirectory ? appState.theme.accentColor : appState.theme.secondaryText)
                .frame(width: 16)

            Text(entry.name)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(appState.theme.primaryText)
                .lineLimit(1)

            Spacer()

            if !entry.isDirectory {
                Text(formatSize(entry.size))
                    .font(.system(size: 10))
                    .foregroundColor(appState.theme.secondaryText)
            }
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 10)
        .contentShape(Rectangle())
        .onTapGesture {
            if entry.isDirectory {
                Task { await sftp.listDirectory(entry.path) }
            } else {
                openRemoteFile()
            }
        }
    }

    private func openRemoteFile() {
        Task {
            guard let content = try? await sftp.readFile(entry.path) else { return }
            await MainActor.run {
                // Create a FileNode backed by the remote file
                let node = FileNode(name: entry.name, type: .file,
                    path: "[remote] \(entry.path)",
                    content: content)
                // Note: remote files don't have a local URL
                // AppState.openFile will be called on main actor
            }
        }
    }

    private func formatSize(_ bytes: Int64) -> String {
        if bytes < 1024 { return "\(bytes)B" }
        if bytes < 1024 * 1024 { return "\(bytes / 1024)K" }
        return "\(bytes / (1024 * 1024))M"
    }

    private func iconForExtension(_ ext: String) -> String {
        switch ext {
        case "swift": return "swift"
        case "py": return "p.square"
        case "js", "ts": return "j.square"
        case "rs": return "r.square"
        case "json": return "curlybraces"
        case "md": return "doc.text"
        case "sh": return "terminal"
        default: return "doc"
        }
    }
}
