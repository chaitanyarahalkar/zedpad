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
            FileNode(name: "scripts", type: .directory, path: "/my-project/scripts", children: [
                FileNode(name: "build.py", type: .file, path: "/my-project/scripts/build.py",
                    content: """
                    #!/usr/bin/env python3
                    \"\"\"Build script for my-project.\"\"\"

                    import os
                    import sys
                    import subprocess
                    from pathlib import Path

                    PROJECT_ROOT = Path(__file__).parent.parent
                    BUILD_DIR = PROJECT_ROOT / ".build"

                    def clean():
                        if BUILD_DIR.exists():
                            import shutil
                            shutil.rmtree(BUILD_DIR)
                        print("Cleaned build directory.")

                    def build(release=False):
                        cmd = ["swift", "build"]
                        if release:
                            cmd += ["-c", "release"]
                        result = subprocess.run(cmd, cwd=PROJECT_ROOT)
                        return result.returncode == 0

                    def run_tests():
                        result = subprocess.run(["swift", "test"], cwd=PROJECT_ROOT)
                        return result.returncode == 0

                    if __name__ == "__main__":
                        mode = sys.argv[1] if len(sys.argv) > 1 else "build"
                        if mode == "clean":
                            clean()
                        elif mode == "test":
                            success = run_tests()
                            sys.exit(0 if success else 1)
                        elif mode == "release":
                            success = build(release=True)
                            sys.exit(0 if success else 1)
                        else:
                            success = build()
                            sys.exit(0 if success else 1)
                    """),
                FileNode(name: "server.js", type: .file, path: "/my-project/scripts/server.js",
                    content: """
                    #!/usr/bin/env node
                    // Simple dev server for my-project

                    const http = require('http');
                    const fs = require('fs');
                    const path = require('path');

                    const PORT = process.env.PORT || 3000;
                    const PUBLIC_DIR = path.join(__dirname, '..', 'public');

                    const MIME_TYPES = {
                      '.html': 'text/html',
                      '.js': 'application/javascript',
                      '.css': 'text/css',
                      '.json': 'application/json',
                      '.png': 'image/png',
                      '.svg': 'image/svg+xml',
                    };

                    const server = http.createServer((req, res) => {
                      const filePath = path.join(PUBLIC_DIR, req.url === '/' ? 'index.html' : req.url);
                      const ext = path.extname(filePath);
                      const contentType = MIME_TYPES[ext] || 'text/plain';

                      fs.readFile(filePath, (err, data) => {
                        if (err) {
                          res.writeHead(404);
                          res.end('Not found');
                          return;
                        }
                        res.writeHead(200, { 'Content-Type': contentType });
                        res.end(data);
                      });
                    });

                    server.listen(PORT, () => {
                      console.log(`Server running at http://localhost:${PORT}`);
                    });
                    """),
                FileNode(name: "parser.rs", type: .file, path: "/my-project/scripts/parser.rs",
                    content: """
                    // parser.rs — simple expression parser

                    use std::fmt;
                    use std::str::Chars;
                    use std::iter::Peekable;

                    #[derive(Debug, Clone, PartialEq)]
                    pub enum Token {
                        Number(f64),
                        Plus,
                        Minus,
                        Star,
                        Slash,
                        LParen,
                        RParen,
                        Eof,
                    }

                    impl fmt::Display for Token {
                        fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
                            match self {
                                Token::Number(n) => write!(f, "{}", n),
                                Token::Plus => write!(f, "+"),
                                Token::Minus => write!(f, "-"),
                                Token::Star => write!(f, "*"),
                                Token::Slash => write!(f, "/"),
                                Token::LParen => write!(f, "("),
                                Token::RParen => write!(f, ")"),
                                Token::Eof => write!(f, "EOF"),
                            }
                        }
                    }

                    pub struct Lexer<'a> {
                        chars: Peekable<Chars<'a>>,
                    }

                    impl<'a> Lexer<'a> {
                        pub fn new(input: &'a str) -> Self {
                            Lexer { chars: input.chars().peekable() }
                        }

                        pub fn next_token(&mut self) -> Token {
                            while let Some(&c) = self.chars.peek() {
                                if c.is_whitespace() { self.chars.next(); continue; }
                                return match c {
                                    '+' => { self.chars.next(); Token::Plus }
                                    '-' => { self.chars.next(); Token::Minus }
                                    '*' => { self.chars.next(); Token::Star }
                                    '/' => { self.chars.next(); Token::Slash }
                                    '(' => { self.chars.next(); Token::LParen }
                                    ')' => { self.chars.next(); Token::RParen }
                                    '0'..='9' | '.' => self.lex_number(),
                                    _ => { self.chars.next(); continue; }
                                };
                            }
                            Token::Eof
                        }

                        fn lex_number(&mut self) -> Token {
                            let mut s = String::new();
                            while let Some(&c) = self.chars.peek() {
                                if c.is_ascii_digit() || c == '.' {
                                    s.push(c);
                                    self.chars.next();
                                } else {
                                    break;
                                }
                            }
                            Token::Number(s.parse().unwrap_or(0.0))
                        }
                    }

                    fn main() {
                        let input = "3.14 + 2 * (10 - 4)";
                        let mut lexer = Lexer::new(input);
                        loop {
                            let tok = lexer.next_token();
                            println!("{:?}", tok);
                            if tok == Token::Eof { break; }
                        }
                    }
                    """),
            ]),
            FileNode(name: "config", type: .directory, path: "/my-project/config", children: [
                FileNode(name: "settings.json", type: .file, path: "/my-project/config/settings.json",
                    content: """
                    {
                      "app": {
                        "name": "my-project",
                        "version": "1.0.0",
                        "debug": false,
                        "logLevel": "info"
                      },
                      "server": {
                        "host": "0.0.0.0",
                        "port": 3000,
                        "timeout": 30000,
                        "maxConnections": 100
                      },
                      "database": {
                        "driver": "sqlite",
                        "path": "./data/app.db",
                        "pool": {
                          "min": 2,
                          "max": 10
                        }
                      },
                      "features": {
                        "darkMode": true,
                        "syntaxHighlighting": true,
                        "autoSave": false,
                        "telemetry": false
                      }
                    }
                    """),
                FileNode(name: "deploy.yaml", type: .file, path: "/my-project/config/deploy.yaml",
                    content: """
                    # Deployment configuration
                    apiVersion: apps/v1
                    kind: Deployment
                    metadata:
                      name: my-project
                      namespace: production
                      labels:
                        app: my-project
                        version: "1.0.0"
                    spec:
                      replicas: 3
                      selector:
                        matchLabels:
                          app: my-project
                      template:
                        metadata:
                          labels:
                            app: my-project
                        spec:
                          containers:
                            - name: app
                              image: myregistry/my-project:1.0.0
                              ports:
                                - containerPort: 3000
                              env:
                                - name: NODE_ENV
                                  value: production
                                - name: PORT
                                  value: "3000"
                              resources:
                                requests:
                                  memory: "64Mi"
                                  cpu: "250m"
                                limits:
                                  memory: "128Mi"
                                  cpu: "500m"
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
                - Syntax highlighting for Swift, JS, Python, Rust, JSON, YAML, Markdown
                - File tree navigation with collapsible folders
                - Find in file with regex support
                - Dark/light themes (Zed Dark, Zed Light, One Dark, Solarized Dark)
                - Editable code with line numbers and status bar

                ## Getting Started

                Open any file from the sidebar to start editing.

                ## Structure

                ```
                my-project/
                  Sources/      # Swift source files
                  scripts/      # Python, JS, Rust utilities
                  config/       # JSON and YAML configuration
                  Tests/        # Unit tests
                ```

                ## Building

                ```bash
                swift build
                swift test
                python3 scripts/build.py
                ```
                """),
            FileNode(name: ".gitignore", type: .file, path: "/my-project/.gitignore",
                content: """
                .DS_Store
                .build/
                node_modules/
                __pycache__/
                *.pyc
                *.o
                *.a
                *.dylib
                xcuserdata/
                *.xcworkspace/xcuserdata
                .env
                """),
        ])
        root.isExpanded = true
        return root
    }
}
