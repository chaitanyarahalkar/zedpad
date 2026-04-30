import SwiftUI

struct ExternalChangeBanner: View {
    @EnvironmentObject private var appState: AppState
    let onReload: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 13))
                .foregroundColor(.orange)
            Text("File changed externally")
                .font(.system(size: 12))
                .foregroundColor(appState.theme.primaryText)
            Spacer()
            Button("Reload") {
                onReload()
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(appState.theme.accentColor)

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10))
                    .foregroundColor(appState.theme.secondaryText)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.orange.opacity(0.1))
        .overlay(Rectangle().fill(Color.orange.opacity(0.3)).frame(height: 1), alignment: .bottom)
    }
}
