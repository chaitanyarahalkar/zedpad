import SwiftUI

struct BreadcrumbView: View {
    @EnvironmentObject private var appState: AppState
    let file: FileNode

    private var pathComponents: [String] {
        let parts = file.path
            .split(separator: "/")
            .map(String.init)
            .filter { !$0.isEmpty }
        return parts
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                ForEach(Array(pathComponents.enumerated()), id: \.offset) { index, component in
                    HStack(spacing: 2) {
                        if index > 0 {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(appState.theme.secondaryText.opacity(0.6))
                        }
                        Text(component)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(
                                index == pathComponents.count - 1
                                    ? appState.theme.primaryText
                                    : appState.theme.secondaryText
                            )
                    }
                }
            }
            .padding(.horizontal, 12)
        }
        .frame(height: 26)
        .background(appState.theme.tabBarBackground)
        .overlay(Rectangle().fill(appState.theme.borderColor).frame(height: 1), alignment: .bottom)
    }
}
