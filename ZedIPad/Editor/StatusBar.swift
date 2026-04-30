import SwiftUI

struct StatusBar: View {
    @EnvironmentObject private var appState: AppState
    let file: FileNode
    let text: String
    @State private var wordWrap: Bool = true
    @State private var tabSize: Int = 4
    @State private var showTabSizePicker: Bool = false

    private var language: Language { Language.detect(from: file.fileExtension) }
    private var lineCount: Int { text.components(separatedBy: "\n").count }
    private var charCount: Int { text.count }

    var body: some View {
        HStack(spacing: 0) {
            // Left side: language
            HStack(spacing: 6) {
                Image(systemName: languageIcon)
                    .font(.system(size: 11))
                    .foregroundColor(appState.theme.accentColor)
                Text(languageName)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(appState.theme.secondaryText)
            }
            .padding(.horizontal, 10)

            Divider().frame(height: 14).background(appState.theme.borderColor)

            // File stats
            HStack(spacing: 4) {
                Image(systemName: "list.number")
                    .font(.system(size: 10))
                    .foregroundColor(appState.theme.secondaryText)
                Text("\(lineCount) lines")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(appState.theme.secondaryText)
            }
            .padding(.horizontal, 10)

            Divider().frame(height: 14).background(appState.theme.borderColor)

            HStack(spacing: 4) {
                Image(systemName: "character.cursor.ibeam")
                    .font(.system(size: 10))
                    .foregroundColor(appState.theme.secondaryText)
                Text("\(charCount) chars")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(appState.theme.secondaryText)
            }
            .padding(.horizontal, 10)

            Spacer()

            // Word wrap toggle
            Button {
                wordWrap.toggle()
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: wordWrap ? "text.alignleft" : "text.alignright")
                        .font(.system(size: 10))
                    Text(wordWrap ? "Wrap" : "No Wrap")
                        .font(.system(size: 11, design: .monospaced))
                }
                .foregroundColor(wordWrap ? appState.theme.accentColor : appState.theme.secondaryText)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
            .accessibilityLabel("Toggle word wrap")

            Divider().frame(height: 14).background(appState.theme.borderColor)

            // Tab size picker
            Button {
                showTabSizePicker.toggle()
            } label: {
                Text("Tab: \(tabSize)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(appState.theme.secondaryText)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
            .popover(isPresented: $showTabSizePicker) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tab Size")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(appState.theme.primaryText)
                        .padding(.bottom, 4)
                    ForEach([2, 4, 8], id: \.self) { size in
                        Button {
                            tabSize = size
                            showTabSizePicker = false
                        } label: {
                            HStack {
                                Text("\(size) spaces")
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundColor(appState.theme.primaryText)
                                if tabSize == size {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11))
                                        .foregroundColor(appState.theme.accentColor)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
                .background(appState.theme.sidebarBackground)
                .presentationCompactAdaptation(.popover)
            }

            Divider().frame(height: 14).background(appState.theme.borderColor)

            Text("UTF-8")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(appState.theme.secondaryText)
                .padding(.horizontal, 8)

            Divider().frame(height: 14).background(appState.theme.borderColor)

            Text("LF")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(appState.theme.secondaryText)
                .padding(.horizontal, 8)
        }
        .frame(height: 24)
        .background(appState.theme.tabBarBackground)
        .overlay(Rectangle().fill(appState.theme.borderColor).frame(height: 1), alignment: .top)
    }

    private var languageName: String {
        switch language {
        case .swift: return "Swift"
        case .javascript: return "JavaScript"
        case .typescript: return "TypeScript"
        case .python: return "Python"
        case .rust: return "Rust"
        case .markdown: return "Markdown"
        case .json: return "JSON"
        case .yaml: return "YAML"
        case .bash: return "Shell"
        case .ruby: return "Ruby"
        case .unknown: return file.fileExtension.isEmpty ? "Plain Text" : file.fileExtension.uppercased()
        }
    }

    private var languageIcon: String {
        switch language {
        case .swift: return "swift"
        case .python: return "p.square"
        case .rust: return "r.square"
        case .javascript, .typescript: return "j.square"
        case .markdown: return "doc.text"
        case .json: return "curlybraces"
        case .bash: return "terminal"
        default: return "doc"
        }
    }
}
