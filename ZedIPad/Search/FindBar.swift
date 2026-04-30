import SwiftUI

@MainActor
class FindState: ObservableObject {
    @Published var query: String = ""
    @Published var replaceQuery: String = ""
    @Published var matchCount: Int = 0
    @Published var currentMatch: Int = 0
    @Published var isCaseSensitive: Bool = false
    @Published var isRegex: Bool = false
    @Published var showReplace: Bool = false

    func search(in text: String) -> [Range<String.Index>] {
        guard !query.isEmpty else {
            matchCount = 0
            currentMatch = 0
            return []
        }
        var options: NSRegularExpression.Options = []
        if !isCaseSensitive { options.insert(.caseInsensitive) }

        let pattern = isRegex ? query : NSRegularExpression.escapedPattern(for: query)
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return [] }

        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        let ranges = matches.compactMap { Range($0.range, in: text) }
        matchCount = ranges.count
        if currentMatch >= matchCount { currentMatch = matchCount > 0 ? 0 : 0 }
        return ranges
    }

    func nextMatch() {
        guard matchCount > 0 else { return }
        currentMatch = (currentMatch + 1) % matchCount
    }

    func previousMatch() {
        guard matchCount > 0 else { return }
        currentMatch = currentMatch == 0 ? matchCount - 1 : currentMatch - 1
    }

    func replace(in text: inout String, at rangeIndex: Int) {
        let ranges = searchRanges(in: text)
        guard rangeIndex < ranges.count else { return }
        let range = ranges[rangeIndex]
        let replacement = isRegex
            ? applyRegexReplacement(in: text, range: range)
            : replaceQuery
        text.replaceSubrange(range, with: replacement)
    }

    func replaceAll(in text: inout String) -> Int {
        let ranges = searchRanges(in: text)
        guard !ranges.isEmpty else { return 0 }
        var count = 0
        var options: NSRegularExpression.Options = []
        if !isCaseSensitive { options.insert(.caseInsensitive) }
        let pattern = isRegex ? query : NSRegularExpression.escapedPattern(for: query)
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return 0 }
        let replaced = regex.stringByReplacingMatches(
            in: text,
            range: NSRange(text.startIndex..., in: text),
            withTemplate: replaceQuery
        )
        count = ranges.count
        text = replaced
        matchCount = 0
        currentMatch = 0
        return count
    }

    private func searchRanges(in text: String) -> [Range<String.Index>] {
        guard !query.isEmpty else { return [] }
        var options: NSRegularExpression.Options = []
        if !isCaseSensitive { options.insert(.caseInsensitive) }
        let pattern = isRegex ? query : NSRegularExpression.escapedPattern(for: query)
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return [] }
        return regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            .compactMap { Range($0.range, in: text) }
    }

    private func applyRegexReplacement(in text: String, range: Range<String.Index>) -> String {
        replaceQuery
    }
}

struct FindBar: View {
    @EnvironmentObject private var appState: AppState
    @Binding var isVisible: Bool
    @ObservedObject var file: FileNode
    @StateObject private var findState = FindState()
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Find row
            HStack(spacing: 8) {
                // Toggle replace
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        findState.showReplace.toggle()
                    }
                } label: {
                    Image(systemName: findState.showReplace ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(appState.theme.secondaryText)
                        .frame(width: 14)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Toggle replace")

                // Search field
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13))
                        .foregroundColor(appState.theme.secondaryText)

                    TextField("Find", text: $findState.query)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(appState.theme.primaryText)
                        .focused($isSearchFocused)
                        .onSubmit { findState.nextMatch() }
                        .accessibilityLabel("Search field")

                    if !findState.query.isEmpty {
                        Text(findState.matchCount == 0 ? "No results" : "\(findState.currentMatch + 1)/\(findState.matchCount)")
                            .font(.system(size: 11))
                            .foregroundColor(appState.theme.secondaryText)

                        Button { findState.query = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundColor(appState.theme.secondaryText)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(appState.theme.background)
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(appState.theme.borderColor, lineWidth: 1))

                FindOptionButton(icon: "textformat", tooltip: "Match Case", isActive: findState.isCaseSensitive) {
                    findState.isCaseSensitive.toggle()
                }
                FindOptionButton(icon: "chevron.left.forwardslash.chevron.right", tooltip: "Use Regex", isActive: findState.isRegex) {
                    findState.isRegex.toggle()
                }

                Divider().frame(height: 18)

                Button { findState.previousMatch() } label: {
                    Image(systemName: "chevron.up").font(.system(size: 12, weight: .medium))
                        .foregroundColor(appState.theme.primaryText)
                }
                .buttonStyle(.plain).disabled(findState.matchCount == 0)
                .accessibilityLabel("Previous match")

                Button { findState.nextMatch() } label: {
                    Image(systemName: "chevron.down").font(.system(size: 12, weight: .medium))
                        .foregroundColor(appState.theme.primaryText)
                }
                .buttonStyle(.plain).disabled(findState.matchCount == 0)
                .accessibilityLabel("Next match")

                Spacer()

                Button { withAnimation { isVisible = false } } label: {
                    Image(systemName: "xmark").font(.system(size: 12, weight: .medium))
                        .foregroundColor(appState.theme.secondaryText)
                }
                .buttonStyle(.plain).accessibilityLabel("Close find bar")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)

            // Replace row (collapsible)
            if findState.showReplace {
                Divider().background(appState.theme.borderColor)
                HStack(spacing: 8) {
                    Spacer().frame(width: 14)
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 12))
                            .foregroundColor(appState.theme.secondaryText)
                        TextField("Replace", text: $findState.replaceQuery)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(appState.theme.primaryText)
                            .accessibilityLabel("Replace field")
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(appState.theme.background)
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(appState.theme.borderColor, lineWidth: 1))

                    Button {
                        findState.replace(in: &file.content, at: findState.currentMatch)
                        findState.nextMatch()
                    } label: {
                        Text("Replace")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(appState.theme.primaryText)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(appState.theme.sidebarBackground)
                            .cornerRadius(4)
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(appState.theme.borderColor, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .disabled(findState.matchCount == 0 || findState.query.isEmpty)
                    .accessibilityLabel("Replace current match")

                    Button {
                        let n = findState.replaceAll(in: &file.content)
                        _ = n
                    } label: {
                        Text("All")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(appState.theme.primaryText)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(appState.theme.sidebarBackground)
                            .cornerRadius(4)
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(appState.theme.borderColor, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .disabled(findState.matchCount == 0 || findState.query.isEmpty)
                    .accessibilityLabel("Replace all matches")

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
            }
        }
        .background(appState.theme.tabBarBackground)
        .onAppear { isSearchFocused = true }
    }
}

struct FindOptionButton: View {
    @EnvironmentObject private var appState: AppState
    let icon: String
    let tooltip: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isActive ? appState.theme.accentColor : appState.theme.secondaryText)
                .padding(5)
                .background(isActive ? appState.theme.accentColor.opacity(0.15) : Color.clear)
                .cornerRadius(4)
        }
        .buttonStyle(.plain)
        .help(tooltip)
    }
}
