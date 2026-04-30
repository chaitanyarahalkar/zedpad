import SwiftUI
import UniformTypeIdentifiers

struct DocumentPickerButton: View {
    @EnvironmentObject private var appState: AppState
    @State private var showingPicker = false

    var body: some View {
        Button {
            showingPicker = true
        } label: {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 14))
                .foregroundColor(appState.theme.primaryText)
        }
        .accessibilityLabel("Open file")
        .sheet(isPresented: $showingPicker) {
            DocumentPickerView { url in
                handleSelectedFile(url)
            }
        }
    }

    private func handleSelectedFile(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        let content = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
        let node = FileNode(
            name: url.lastPathComponent,
            type: .file,
            path: url.path,
            content: content
        )
        appState.openFile(node)
        if appState.rootDirectory == nil {
            let root = FileNode(name: url.deletingLastPathComponent().lastPathComponent,
                                type: .directory,
                                path: url.deletingLastPathComponent().path,
                                children: [node])
            appState.rootDirectory = root
        } else {
            appState.rootDirectory?.children?.append(node)
        }
    }
}

struct DocumentPickerView: UIViewControllerRepresentable {
    let onPick: (URL) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = [.plainText, .sourceCode, .pythonScript,
                               .json, .yaml, .xml, .shellScript, .swiftSource]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        init(onPick: @escaping (URL) -> Void) { self.onPick = onPick }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }
    }
}
