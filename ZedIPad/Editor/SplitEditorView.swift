import SwiftUI

/// Manages split view state for displaying two editors
@MainActor
class SplitEditorState: ObservableObject {
    @Published var secondaryFile: FileNode?
    @Published var isSplit: Bool = false

    func openSplit(_ file: FileNode) {
        secondaryFile = file
        isSplit = true
    }

    func closeSplit() {
        secondaryFile = nil
        isSplit = false
    }

    func swapEditors(primary: inout FileNode?, secondary: inout FileNode?) {
        let temp = primary
        primary = secondary
        secondary = temp
    }
}

struct SplitEditorContainer: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var splitState = SplitEditorState()

    var body: some View {
        Group {
            if let primaryFile = appState.activeFile {
                if splitState.isSplit, let secondaryFile = splitState.secondaryFile {
                    HSplitEditorView(
                        primaryFile: primaryFile,
                        secondaryFile: secondaryFile,
                        splitState: splitState
                    )
                } else {
                    EditorView(file: primaryFile)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                SplitButton(splitState: splitState, primaryFile: primaryFile)
                            }
                        }
                }
            } else {
                WelcomeView()
            }
        }
        .environmentObject(splitState)
    }
}

struct HSplitEditorView: View {
    @EnvironmentObject private var appState: AppState
    let primaryFile: FileNode
    let secondaryFile: FileNode
    let splitState: SplitEditorState
    @State private var splitRatio: CGFloat = 0.5

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                EditorView(file: primaryFile)
                    .frame(width: geo.size.width * splitRatio)

                // Drag handle
                Rectangle()
                    .fill(appState.theme.borderColor)
                    .frame(width: 1)
                    .overlay(
                        Image(systemName: "ellipsis.vertical")
                            .font(.system(size: 10))
                            .foregroundColor(appState.theme.secondaryText)
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newRatio = value.location.x / geo.size.width
                                splitRatio = max(0.2, min(0.8, newRatio))
                            }
                    )

                EditorView(file: secondaryFile)
                    .frame(width: geo.size.width * (1 - splitRatio))
                    .overlay(alignment: .topTrailing) {
                        Button {
                            splitState.closeSplit()
                        } label: {
                            Image(systemName: "rectangle.portrait")
                                .font(.system(size: 12))
                                .foregroundColor(appState.theme.secondaryText)
                                .padding(6)
                        }
                        .buttonStyle(.plain)
                        .padding(8)
                        .accessibilityLabel("Close split view")
                    }
            }
        }
    }
}

struct SplitButton: View {
    @EnvironmentObject private var appState: AppState
    let splitState: SplitEditorState
    let primaryFile: FileNode

    var body: some View {
        Button {
            // Open second file (pick next open file, or same file)
            let otherFile = appState.openFiles.first { $0.id != primaryFile.id } ?? primaryFile
            splitState.openSplit(otherFile)
        } label: {
            Image(systemName: "rectangle.split.2x1")
                .foregroundColor(appState.theme.primaryText)
        }
        .accessibilityLabel("Split editor")
        .disabled(appState.openFiles.isEmpty)
    }
}
