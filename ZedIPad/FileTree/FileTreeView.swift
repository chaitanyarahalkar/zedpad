import SwiftUI

struct FileTreeView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            appState.theme.sidebarBackground.ignoresSafeArea()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if let root = appState.rootDirectory {
                        FileTreeNodeView(node: root, depth: 0)
                    }
                }
                .padding(.top, 8)
            }
        }
    }
}

struct FileTreeNodeView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var node: FileNode
    let depth: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            FileTreeRowView(node: node, depth: depth)
                .onTapGesture {
                    handleTap()
                }

            if node.type == .directory && node.isExpanded {
                ForEach(node.children ?? []) { child in
                    FileTreeNodeView(node: child, depth: depth + 1)
                }
            }
        }
    }

    private func handleTap() {
        if node.type == .directory {
            withAnimation(.easeInOut(duration: 0.15)) {
                node.isExpanded.toggle()
            }
        } else {
            appState.openFile(node)
        }
    }
}

struct FileTreeRowView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var node: FileNode
    let depth: Int

    private var isActive: Bool {
        appState.activeFile?.id == node.id
    }

    var body: some View {
        HStack(spacing: 4) {
            // Indent
            Rectangle()
                .fill(Color.clear)
                .frame(width: CGFloat(depth) * 16)

            // Chevron for directories
            if node.type == .directory {
                Image(systemName: node.isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(appState.theme.secondaryText)
                    .frame(width: 12)
            } else {
                Spacer().frame(width: 12)
            }

            // Icon
            Image(systemName: node.icon)
                .font(.system(size: 13))
                .foregroundColor(iconColor)
                .frame(width: 16)

            // Name
            Text(node.name)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(isActive ? appState.theme.accentColor : appState.theme.primaryText)
                .lineLimit(1)

            Spacer()
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 8)
        .background(
            isActive ? appState.theme.accentColor.opacity(0.15) : Color.clear
        )
        .contentShape(Rectangle())
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
            return node.type == .directory
                ? appState.theme.accentColor
                : appState.theme.secondaryText
        }
    }
}
