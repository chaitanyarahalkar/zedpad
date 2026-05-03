import SwiftUI

struct FileSearchBar: View {
    @EnvironmentObject private var appState: AppState
    @Binding var query: String
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundColor(appState.theme.secondaryText)

            TextField("Filter files...", text: $query)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(appState.theme.primaryText)
                .focused($isFocused)
                .autocorrectionDisabled()
                .accessibilityLabel("Filter files")
                .accessibilityIdentifier("Filter files")
                .onTapGesture { isFocused = true }

            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(appState.theme.secondaryText)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(appState.theme.background)
        .cornerRadius(5)
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(
            isFocused ? appState.theme.accentColor : appState.theme.borderColor,
            lineWidth: isFocused ? 1.5 : 1
        ))
        .contentShape(Rectangle())
        .onTapGesture { isFocused = true }
        .animation(.easeInOut(duration: 0.15), value: isFocused)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }
}

extension FileNode {
    func filtered(by query: String) -> FileNode? {
        guard !query.isEmpty else { return self }
        if type == .file {
            return name.localizedCaseInsensitiveContains(query) ? self : nil
        }
        let filteredChildren = (children ?? []).compactMap { $0.filtered(by: query) }
        if filteredChildren.isEmpty { return nil }
        let result = FileNode(id: id, name: name, type: type, path: path,
                              children: filteredChildren, content: content)
        result.isExpanded = true
        return result
    }
}
