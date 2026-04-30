import SwiftUI

/// A minimap that renders a tiny overview of the code on the right side of the editor.
struct MinimapView: View {
    @EnvironmentObject private var appState: AppState
    let text: String
    let language: Language
    @Binding var scrollFraction: CGFloat

    private let minimapWidth: CGFloat = 80
    private let lineHeight: CGFloat = 2.5
    private let charWidth: CGFloat = 0.55

    private var lines: [String] { text.components(separatedBy: "\n") }

    var body: some View {
        ZStack(alignment: .top) {
            // Background
            appState.theme.sidebarBackground

            // Lines
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                        MinimapLineView(line: line, theme: appState.theme)
                            .frame(height: lineHeight)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }
            .disabled(true)

            // Viewport indicator
            GeometryReader { geo in
                let viewportHeight = max(geo.size.height * 0.3, 40)
                let maxOffset = max(geo.size.height - viewportHeight, 0)
                RoundedRectangle(cornerRadius: 2)
                    .fill(appState.theme.accentColor.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(appState.theme.accentColor.opacity(0.3), lineWidth: 0.5)
                    )
                    .frame(height: viewportHeight)
                    .offset(y: scrollFraction * maxOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newFraction = value.location.y / geo.size.height
                                scrollFraction = max(0, min(1, newFraction))
                            }
                    )
            }
        }
        .frame(width: minimapWidth)
        .overlay(
            Rectangle()
                .fill(appState.theme.borderColor)
                .frame(width: 1),
            alignment: .leading
        )
    }
}

struct MinimapLineView: View {
    let line: String
    let theme: ZedTheme

    var body: some View {
        GeometryReader { geo in
            if line.isEmpty {
                Color.clear
            } else {
                let trimmed = String(line.prefix(Int(geo.size.width / 0.55)))
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(theme.primaryText.opacity(0.25))
                        .frame(
                            width: min(CGFloat(trimmed.count) * 0.55, geo.size.width),
                            height: 1.5
                        )
                    Spacer()
                }
            }
        }
    }
}
