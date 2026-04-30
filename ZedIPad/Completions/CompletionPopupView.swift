import SwiftUI

struct CompletionPopupView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var manager: CompletionManager
    let onSelect: (CompletionItem) -> Void

    var body: some View {
        if manager.isVisible && !manager.items.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(manager.items.enumerated()), id: \.element.id) { idx, item in
                    CompletionRowView(
                        item: item,
                        isSelected: idx == manager.selectedIndex,
                        theme: appState.theme
                    )
                    .onTapGesture { onSelect(item) }

                    if idx < manager.items.count - 1 {
                        Divider()
                            .background(appState.theme.borderColor.opacity(0.5))
                    }
                }
            }
            .background(appState.theme.sidebarBackground)
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 6)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(appState.theme.borderColor, lineWidth: 1)
            )
            .frame(width: 340)
            .fixedSize(horizontal: true, vertical: true)
        }
    }
}

struct CompletionRowView: View {
    let item: CompletionItem
    let isSelected: Bool
    let theme: ZedTheme

    var body: some View {
        HStack(spacing: 8) {
            // Kind icon
            Image(systemName: item.kind.icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(item.kind.color)
                .frame(width: 18, height: 18)

            // Label
            Text(item.label)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(isSelected ? .white : theme.primaryText)
                .lineLimit(1)

            Spacer()

            // Detail
            if let detail = item.detail {
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundColor(isSelected ? .white.opacity(0.75) : theme.secondaryText)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isSelected ? theme.accentColor : Color.clear)
        .contentShape(Rectangle())
    }
}
