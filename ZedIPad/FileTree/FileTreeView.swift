import SwiftUI
import UniformTypeIdentifiers

// Flat row model for the file tree List
struct FlatFileNode: Identifiable {
    let id: UUID
    let node: FileNode
    let depth: Int
    let parent: FileNode?
}

struct FileTreeView: View {
    @EnvironmentObject private var appState: AppState
    @State private var filterQuery: String = ""
    @State private var showingNewItemSheet = false
    @State private var showingSortPicker = false

    // Flatten the visible tree into a linear array — each node is one List row
    private var flatNodes: [FlatFileNode] {
        _ = appState.treeRevision  // subscribe — recomputes whenever a folder is expanded/collapsed
        let root = filterQuery.isEmpty
            ? appState.rootDirectory
            : appState.rootDirectory?.filtered(by: filterQuery)
        guard let root else { return [] }
        return flatten(root, depth: 0, parent: nil)
    }

    private func flatten(_ node: FileNode, depth: Int, parent: FileNode?) -> [FlatFileNode] {
        var result = [FlatFileNode(id: node.id, node: node, depth: depth, parent: parent)]
        if node.type == .directory && node.isExpanded {
            for child in node.children ?? [] {
                result += flatten(child, depth: depth + 1, parent: node)
            }
        }
        return result
    }

    var body: some View {
        ZStack {
            appState.theme.sidebarBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    FileSearchBar(query: $filterQuery)
                    Button { showingNewItemSheet = true } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14))
                            .foregroundColor(appState.theme.primaryText)
                            .padding(.horizontal, 8)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("New file or folder")
                    Button { showingSortPicker = true } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 12))
                            .foregroundColor(appState.theme.secondaryText)
                            .padding(.horizontal, 6)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showingSortPicker) { SortPickerView() }
                }
                Divider().background(appState.theme.borderColor)

                if flatNodes.isEmpty && !filterQuery.isEmpty {
                    Spacer()
                    Text("No files match \"\(filterQuery)\"")
                        .font(.system(size: 12))
                        .foregroundColor(appState.theme.secondaryText)
                    Spacer()
                } else {
                    // List backed by UITableView — tap + contextMenu coexist natively on device
                    List(flatNodes) { flat in
                        FileTreeRowView(
                            node: flat.node,
                            depth: flat.depth,
                            parentNode: flat.parent
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(
                            appState.activeFile?.id == flat.node.id
                                ? appState.theme.accentColor.opacity(0.15)
                                : appState.theme.sidebarBackground
                        )
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(appState.theme.sidebarBackground)
                }
            }
        }
        .sheet(isPresented: $showingNewItemSheet) {
            NewItemSheet(parentNode: appState.rootDirectory)
        }
    }
}

struct FileTreeRowView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var node: FileNode
    let depth: Int
    let parentNode: FileNode?
    @State private var showingRenameSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingNewFileSheet = false
    @State private var showingNewFolderSheet = false

    var body: some View {
        // Button inside a List row — natively coexists with .contextMenu on device
        Button(action: handleTap) {
            HStack(spacing: 4) {
                Rectangle().fill(Color.clear).frame(width: CGFloat(depth) * 16)
                if node.type == .directory {
                    Image(systemName: node.isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(appState.theme.secondaryText)
                        .frame(width: 12)
                } else {
                    Spacer().frame(width: 12)
                }
                Image(systemName: node.icon)
                    .font(.system(size: 13))
                    .foregroundColor(iconColor)
                    .frame(width: 16)
                Text(node.name)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(appState.activeFile?.id == node.id ? appState.theme.accentColor : appState.theme.primaryText)
                    .lineLimit(1)
                if node.isDirty {
                    Circle().fill(appState.theme.accentColor).frame(width: 6, height: 6)
                }
                Spacer()
                if let meta = node.metadata, node.type == .file {
                    Text(meta.formattedSize)
                        .font(.system(size: 10))
                        .foregroundColor(appState.theme.secondaryText)
                        .padding(.trailing, 4)
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            // New file / folder inside a directory
            if node.type == .directory {
                Button {
                    node.isExpanded = true
                    showingNewFileSheet = true
                } label: {
                    Label("New File", systemImage: "doc.badge.plus")
                }
                Button {
                    node.isExpanded = true
                    showingNewFolderSheet = true
                } label: {
                    Label("New Folder", systemImage: "folder.badge.plus")
                }
                Divider()
            }
            Button {
                showingRenameSheet = true
            } label: {
                Label("Rename", systemImage: "pencil")
            }
            if node.type == .file, let parent = parentNode {
                Button {
                    appState.duplicateNode(node, in: parent)
                } label: {
                    Label("Duplicate", systemImage: "doc.on.doc")
                }
            }
            Divider()
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Delete \"\(node.name)\"?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let parent = parentNode {
                    appState.deleteNode(node, from: parent)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(node.type == .directory ? "This folder and its contents will be permanently deleted." : "This file will be permanently deleted.")
        }
        .sheet(isPresented: $showingRenameSheet) {
            RenameSheet(node: node)
        }
        .sheet(isPresented: $showingNewFileSheet) {
            NewItemSheet(initialIsFolder: false, parentNode: node)
        }
        .sheet(isPresented: $showingNewFolderSheet) {
            NewItemSheet(initialIsFolder: true, parentNode: node)
        }
        .onAppear {
            if let url = node.fileURL {
                node.metadata = try? FileSystemService.shared.attributes(at: url)
            }
        }
    }

    private func handleTap() {
        if node.type == .directory {
            withAnimation(.easeInOut(duration: 0.15)) {
                node.isExpanded.toggle()
                appState.treeRevision += 1  // notify FileTreeView to recompute flatNodes
            }
        } else {
            if let url = node.fileURL,
               let content = try? FileSystemService.shared.readFile(at: url) {
                node.content = content
                node.isDirty = false
            }
            appState.openFile(node)
        }
    }

    private var iconColor: Color {
        switch node.fileExtension {
        case "swift": return Color(hex: "#F05138")
        case "js", "ts": return Color(hex: "#F7DF1E")
        case "py": return Color(hex: "#3776AB")
        case "rs": return Color(hex: "#CE422B")
        case "json": return Color(hex: "#F7B731")
        case "md": return Color(hex: "#8BE9FD")
        default:
            return node.type == .directory ? appState.theme.accentColor : appState.theme.secondaryText
        }
    }
}

// MARK: - New Item Sheet

struct NewItemSheet: View {
    var initialIsFolder: Bool = false
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    let parentNode: FileNode?
    @State private var name: String = ""
    @State private var selectedExtension: String = ".swift"
    @State private var isFolder: Bool = false
    // initialIsFolder handled in onAppear

    private let extensions = [".swift", ".py", ".js", ".ts", ".md", ".txt", ".json", ".yaml", ".sh", ".rs"]

    var body: some View {
        NavigationView {
            Form {
                Section("Type") {
                    Picker("Item type", selection: $isFolder) {
                        Text("File").tag(false)
                        Text("Folder").tag(true)
                    }
                    .pickerStyle(.segmented)
                }
                Section("Name") {

                    TextField(isFolder ? "Folder name" : "File name", text: $name)
                        .autocorrectionDisabled()
                    if !isFolder {
                        Picker("Extension", selection: $selectedExtension) {
                            ForEach(extensions, id: \.self) { ext in
                                Text(ext).tag(ext)
                            }
                        }
                    }
                }
            }
            .navigationTitle(isFolder ? "New Folder" : "New File")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        guard !name.isEmpty, let parent = parentNode else { dismiss(); return }
                        if isFolder {
                            appState.createDirectory(named: name, in: parent)
                        } else {
                            let fullName = name.hasSuffix(selectedExtension) ? name : name + selectedExtension
                            appState.createFile(named: fullName, in: parent)
                        }
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear { isFolder = initialIsFolder }
        }
    }
}

// MARK: - Rename Sheet

struct RenameSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    let node: FileNode
    @State private var newName: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section("New name") {
                    TextField("Name", text: $newName)
                        .autocorrectionDisabled()
                }
            }
            .navigationTitle("Rename")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Rename") {
                        guard !newName.isEmpty else { dismiss(); return }
                        appState.renameNode(node, to: newName)
                        dismiss()
                    }
                    .disabled(newName.isEmpty)
                }
            }
            .onAppear { newName = node.name }
        }
    }
}

// MARK: - Sort Picker

struct SortPickerView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Sort by")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(appState.theme.secondaryText)
                .padding(.horizontal, 12)
                .padding(.top, 8)

            ForEach(AppState.FileSortOrder.allCases, id: \.self) { order in
                Button {
                    appState.sortOrder = order
                    if let root = appState.rootDirectory {
                        appState.sortChildren(of: root)
                    }
                    dismiss()
                } label: {
                    HStack {
                        Text(order.rawValue)
                            .font(.system(size: 14))
                            .foregroundColor(appState.theme.primaryText)
                        Spacer()
                        if appState.sortOrder == order {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12))
                                .foregroundColor(appState.theme.accentColor)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 8)
        .background(appState.theme.sidebarBackground)
        .presentationCompactAdaptation(.popover)
    }
}
