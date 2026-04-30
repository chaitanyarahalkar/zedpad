import Foundation

enum FileNodeType {
    case file
    case directory
}

class FileNode: Identifiable, ObservableObject {
    let id: UUID
    let name: String
    let type: FileNodeType
    let path: String
    @Published var children: [FileNode]?
    @Published var isExpanded: Bool = false
    @Published var content: String

    var fileExtension: String {
        (name as NSString).pathExtension.lowercased()
    }

    var icon: String {
        switch type {
        case .directory:
            return isExpanded ? "folder.fill" : "folder"
        case .file:
            return iconForExtension(fileExtension)
        }
    }

    init(id: UUID = UUID(), name: String, type: FileNodeType, path: String, children: [FileNode]? = nil, content: String = "") {
        self.id = id
        self.name = name
        self.type = type
        self.path = path
        self.children = children
        self.content = content
    }

    private func iconForExtension(_ ext: String) -> String {
        switch ext {
        case "swift": return "swift"
        case "js", "ts", "jsx", "tsx": return "j.square"
        case "py": return "p.square"
        case "rs": return "r.square"
        case "json": return "curlybraces"
        case "md": return "doc.text"
        case "yaml", "yml": return "doc.plaintext"
        case "sh": return "terminal"
        case "html", "htm": return "globe"
        case "css": return "paintbrush"
        default: return "doc"
        }
    }

    static func sampleRoot() -> FileNode {
        let root = FileNode(name: "my-project", type: .directory, path: "/my-project", children: [
            FileNode(name: "Sources", type: .directory, path: "/my-project/Sources", children: [
                FileNode(name: "main.swift", type: .file, path: "/my-project/Sources/main.swift",
                    content: """
                    import Foundation

                    // ZedIPad — a Zed-inspired code editor for iPad
                    struct App {
                        let name: String = "ZedIPad"
                        let version: String = "1.0.0"

                        func run() {
                            print("Welcome to \\(name) v\\(version)")
                        }
                    }

                    let app = App()
                    app.run()
                    """),
                FileNode(name: "Editor.swift", type: .file, path: "/my-project/Sources/Editor.swift",
                    content: """
                    import SwiftUI

                    /// Core editor model
                    class Editor: ObservableObject {
                        @Published var text: String = ""
                        @Published var cursorPosition: Int = 0

                        var lineCount: Int {
                            text.components(separatedBy: "\\n").count
                        }

                        func insertText(_ newText: String, at position: Int) {
                            let index = text.index(text.startIndex, offsetBy: min(position, text.count))
                            text.insert(contentsOf: newText, at: index)
                            cursorPosition = position + newText.count
                        }

                        func deleteLine(at lineNumber: Int) {
                            var lines = text.components(separatedBy: "\\n")
                            guard lineNumber >= 0 && lineNumber < lines.count else { return }
                            lines.remove(at: lineNumber)
                            text = lines.joined(separator: "\\n")
                        }
                    }
                    """),
            ]),
            FileNode(name: "Tests", type: .directory, path: "/my-project/Tests", children: [
                FileNode(name: "AppTests.swift", type: .file, path: "/my-project/Tests/AppTests.swift",
                    content: """
                    import XCTest

                    final class AppTests: XCTestCase {
                        func testExample() throws {
                            XCTAssertEqual(1 + 1, 2)
                        }
                    }
                    """),
            ]),
            FileNode(name: "Package.swift", type: .file, path: "/my-project/Package.swift",
                content: """
                // swift-tools-version:5.9
                import PackageDescription

                let package = Package(
                    name: "my-project",
                    targets: [
                        .executableTarget(name: "my-project", path: "Sources"),
                        .testTarget(name: "my-projectTests", dependencies: ["my-project"], path: "Tests"),
                    ]
                )
                """),
            FileNode(name: "README.md", type: .file, path: "/my-project/README.md",
                content: """
                # my-project

                A sample project opened in ZedIPad.

                ## Features

                - Fast, native Swift editor
                - Syntax highlighting
                - File tree navigation
                - Find & replace
                - Dark/light themes

                ## Getting Started

                Open any file from the sidebar to start editing.
                """),
            FileNode(name: ".gitignore", type: .file, path: "/my-project/.gitignore",
                content: """
                .DS_Store
                .build/
                *.o
                *.a
                *.dylib
                xcuserdata/
                *.xcworkspace/xcuserdata
                """),
        ])
        root.isExpanded = true
        return root
    }
}
