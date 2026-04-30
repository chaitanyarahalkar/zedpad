import SwiftUI

struct GitCommitView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var commitMessage: String = ""
    @State private var stagedPaths: Set<String> = []
    @StateObject private var gitService: GitService

    init(repoURL: URL?) {
        _gitService = StateObject(wrappedValue: GitService(repoURL: repoURL))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Staged files
                if gitService.statusEntries.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 28))
                            .foregroundColor(appState.theme.accentColor)
                        Text("Working tree clean")
                            .foregroundColor(appState.theme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        Section("Changes") {
                            ForEach(gitService.statusEntries) { entry in
                                HStack(spacing: 10) {
                                    Toggle("", isOn: Binding(
                                        get: { stagedPaths.contains(entry.path) },
                                        set: { checked in
                                            if checked { stagedPaths.insert(entry.path) }
                                            else { stagedPaths.remove(entry.path) }
                                        }
                                    ))
                                    .labelsHidden()
                                    .tint(appState.theme.accentColor)

                                    Text(entry.status.badge)
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(statusColor(entry.status))
                                        .frame(width: 16)

                                    Text(entry.path)
                                        .font(.system(size: 13, design: .monospaced))
                                        .foregroundColor(appState.theme.primaryText)
                                        .lineLimit(1)
                                }
                                .listRowBackground(appState.theme.sidebarBackground)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(appState.theme.editorBackground)
                }

                // Commit message
                VStack(alignment: .leading, spacing: 8) {
                    Text("Commit Message")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(appState.theme.secondaryText)
                        .padding(.horizontal, 12)

                    TextEditor(text: $commitMessage)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(appState.theme.primaryText)
                        .scrollContentBackground(.hidden)
                        .background(appState.theme.sidebarBackground)
                        .frame(height: 80)
                        .padding(.horizontal, 8)
                        .overlay(
                            Group {
                                if commitMessage.isEmpty {
                                    Text("Enter commit message…")
                                        .foregroundColor(appState.theme.secondaryText)
                                        .font(.system(size: 13, design: .monospaced))
                                        .allowsHitTesting(false)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                }
                            }
                        )
                }
                .padding(.vertical, 8)
                .background(appState.theme.tabBarBackground)
                .overlay(Rectangle().fill(appState.theme.borderColor).frame(height: 1), alignment: .top)
            }
            .background(appState.theme.editorBackground)
            .navigationTitle("Git Commit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(appState.theme.accentColor)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Commit") { performCommit() }
                        .foregroundColor(appState.theme.accentColor)
                        .disabled(commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || stagedPaths.isEmpty)
                }
            }
        }
        .onAppear {
            if let url = gitService.repoURL {
                gitService.refresh(at: url)
            }
            // Pre-select all changed files
            stagedPaths = Set(gitService.statusEntries.map(\.path))
        }
    }

    private func performCommit() {
        let stagedList = Array(stagedPaths)
        _ = gitService.handleGitCommand(["add"] + stagedList)
        let result = gitService.handleGitCommand(["commit", "-m", commitMessage])
        _ = result
        dismiss()
    }

    private func statusColor(_ status: GitFileStatus) -> Color {
        switch status {
        case .added:     return Color(hex: "#a6e3a1")
        case .modified:  return Color(hex: "#f9e2af")
        case .deleted:   return Color(hex: "#f38ba8")
        case .untracked: return appState.theme.secondaryText
        default:         return appState.theme.primaryText
        }
    }
}
