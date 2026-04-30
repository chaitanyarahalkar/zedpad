import SwiftUI

struct GlobalSearchResult: Identifiable {
    let id = UUID()
    let file: FileNode
    let lineNumber: Int
    let lineText: String
    let matchRange: Range<String.Index>
}

@MainActor
class GlobalSearchState: ObservableObject {
    @Published var query: String = ""
    @Published var results: [GlobalSearchResult] = []
    @Published var isSearching: Bool = false

    func search(in root: FileNode?) {
        guard !query.isEmpty, let root else {
            results = []
            return
        }
        isSearching = true
        var found: [GlobalSearchResult] = []
        searchNode(root, query: query, results: &found)
        results = found
        isSearching = false
    }

    private func searchNode(_ node: FileNode, query: String, results: inout [GlobalSearchResult]) {
        if node.type == .file {
            let lines = node.content.components(separatedBy: "\n")
            for (idx, line) in lines.enumerated() {
                var searchStart = line.startIndex
                while let range = line.range(of: query,
                                              options: .caseInsensitive,
                                              range: searchStart..<line.endIndex) {
                    results.append(GlobalSearchResult(
                        file: node,
                        lineNumber: idx + 1,
                        lineText: line.trimmingCharacters(in: .whitespaces),
                        matchRange: range
                    ))
                    searchStart = range.upperBound
                    if searchStart >= line.endIndex { break }
                }
            }
        }
        for child in node.children ?? [] {
            searchNode(child, query: query, results: &results)
        }
    }
}

struct GlobalSearchView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var searchState = GlobalSearchState()
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            appState.theme.sidebarBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                // Search input
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13))
                        .foregroundColor(appState.theme.secondaryText)
                    TextField("Search in files...", text: $searchState.query)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(appState.theme.primaryText)
                        .focused($isFocused)
                        .onSubmit { searchState.search(in: appState.rootDirectory) }
                        .onChange(of: searchState.query) { _ in
                            if searchState.query.count >= 2 {
                                searchState.search(in: appState.rootDirectory)
                            } else if searchState.query.isEmpty {
                                searchState.results = []
                            }
                        }
                    if !searchState.query.isEmpty {
                        Button { searchState.query = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(appState.theme.secondaryText)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(10)
                .background(appState.theme.background)
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(appState.theme.borderColor, lineWidth: 1))
                .padding(8)

                Divider().background(appState.theme.borderColor)

                if searchState.isSearching {
                    ProgressView()
                        .padding()
                } else if searchState.results.isEmpty && !searchState.query.isEmpty {
                    Text("No results for \"\(searchState.query)\"")
                        .font(.system(size: 12))
                        .foregroundColor(appState.theme.secondaryText)
                        .padding()
                } else {
                    // Group results by file
                    let grouped = Dictionary(grouping: searchState.results, by: { $0.file.path })
                    let sortedKeys = grouped.keys.sorted()
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(sortedKeys, id: \.self) { key in
                                if let fileResults = grouped[key], let file = fileResults.first?.file {
                                    GlobalSearchFileSection(file: file, results: fileResults)
                                }
                            }
                        }
                    }
                }

                if !searchState.results.isEmpty {
                    Text("\(searchState.results.count) result\(searchState.results.count == 1 ? "" : "s")")
                        .font(.system(size: 11))
                        .foregroundColor(appState.theme.secondaryText)
                        .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { isFocused = true }
    }
}

struct GlobalSearchFileSection: View {
    @EnvironmentObject private var appState: AppState
    let file: FileNode
    let results: [GlobalSearchResult]
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // File header
            Button {
                withAnimation(.easeInOut(duration: 0.15)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(appState.theme.secondaryText)
                    Image(systemName: file.icon)
                        .font(.system(size: 12))
                        .foregroundColor(appState.theme.accentColor)
                    Text(file.name)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(appState.theme.primaryText)
                    Text("(\(results.count))")
                        .font(.system(size: 11))
                        .foregroundColor(appState.theme.secondaryText)
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
            }
            .buttonStyle(.plain)
            .background(appState.theme.sidebarBackground)

            if isExpanded {
                ForEach(results) { result in
                    GlobalSearchResultRow(result: result)
                        .onTapGesture {
                            appState.openFile(result.file)
                        }
                }
            }
        }
    }
}

struct GlobalSearchResultRow: View {
    @EnvironmentObject private var appState: AppState
    let result: GlobalSearchResult

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(result.lineNumber)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(appState.theme.lineNumberText)
                .frame(width: 32, alignment: .trailing)
            Text(result.lineText)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(appState.theme.primaryText)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 3)
        .background(appState.theme.editorBackground)
        .contentShape(Rectangle())
    }
}
