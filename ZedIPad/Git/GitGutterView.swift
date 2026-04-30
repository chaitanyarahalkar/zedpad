import SwiftUI

// MARK: - Git Gutter State

@MainActor
class GitGutterState: ObservableObject {
    @Published var lineIndicators: [Int: GitLineIndicator] = [:]

    enum GitLineIndicator {
        case added
        case modified
        case deleted

        var color: Color {
            switch self {
            case .added:    return Color(hex: "#a6e3a1")  // green
            case .modified: return Color(hex: "#f9e2af")  // yellow
            case .deleted:  return Color(hex: "#f38ba8")  // red
            }
        }
    }

    func update(from diff: String) {
        lineIndicators.removeAll()
        let lines = diff.components(separatedBy: "\n")
        var lineNum = 0
        for line in lines {
            if line.hasPrefix("@@") {
                if let range = line.range(of: #"\+(\d+)"#, options: .regularExpression) {
                    let numStr = line[range].dropFirst()
                    lineNum = (Int(numStr) ?? 1) - 1
                }
            } else if line.hasPrefix("+") && !line.hasPrefix("+++") {
                lineNum += 1
                lineIndicators[lineNum] = .added
            } else if line.hasPrefix("-") && !line.hasPrefix("---") {
                lineIndicators[lineNum] = .deleted
            } else if !line.hasPrefix("\\") {
                lineNum += 1
            }
        }
    }
}

// MARK: - Gutter Indicator Bar

struct GitGutterBar: View {
    let lineCount: Int
    let indicators: [Int: GitGutterState.GitLineIndicator]
    let theme: ZedTheme

    var body: some View {
        VStack(spacing: 0) {
            ForEach(1...max(lineCount, 1), id: \.self) { line in
                Rectangle()
                    .fill(indicators[line]?.color ?? Color.clear)
                    .frame(width: 3)
                    .frame(height: 20)
                    .padding(.vertical, 1)
            }
        }
        .frame(width: 4)
    }
}

// MARK: - Git Branch Status Bar Widget

struct GitBranchWidget: View {
    @EnvironmentObject private var appState: AppState
    let gitService: GitService

    var body: some View {
        if gitService.isRepo {
            HStack(spacing: 4) {
                Image(systemName: "arrow.triangle.branch")
                    .font(.system(size: 10))
                    .foregroundColor(appState.theme.accentColor)
                Text(gitService.currentBranch)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(appState.theme.secondaryText)

                if !gitService.statusEntries.isEmpty {
                    Text("\(gitService.statusEntries.count)")
                        .font(.system(size: 10))
                        .foregroundColor(appState.theme.accentColor)
                        .padding(.horizontal, 4)
                        .background(appState.theme.accentColor.opacity(0.15))
                        .cornerRadius(3)
                }
            }
            .padding(.horizontal, 8)
        }
    }
}
