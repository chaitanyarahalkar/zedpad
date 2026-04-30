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
}

struct FindBar: View {
    @EnvironmentObject private var appState: AppState
    @Binding var isVisible: Bool
    @StateObject private var findState = FindState()
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
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
                .padding(.vertical, 6)
                .background(appState.theme.background)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(appState.theme.borderColor, lineWidth: 1)
                )

                // Case sensitive toggle
                FindOptionButton(
                    icon: "textformat",
                    tooltip: "Match Case",
                    isActive: findState.isCaseSensitive
                ) {
                    findState.isCaseSensitive.toggle()
                }

                // Regex toggle
                FindOptionButton(
                    icon: "chevron.left.forwardslash.chevron.right",
                    tooltip: "Use Regex",
                    isActive: findState.isRegex
                ) {
                    findState.isRegex.toggle()
                }

                Divider()
                    .frame(height: 20)

                // Navigation
                Button { findState.previousMatch() } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(appState.theme.primaryText)
                }
                .buttonStyle(.plain)
                .disabled(findState.matchCount == 0)
                .accessibilityLabel("Previous match")

                Button { findState.nextMatch() } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(appState.theme.primaryText)
                }
                .buttonStyle(.plain)
                .disabled(findState.matchCount == 0)
                .accessibilityLabel("Next match")

                Spacer()

                Button {
                    withAnimation { isVisible = false }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(appState.theme.secondaryText)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close find bar")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
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
