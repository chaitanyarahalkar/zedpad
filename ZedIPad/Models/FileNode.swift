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
    var fileURL: URL?          // set when opened from DocumentPicker
    @Published var isDirty: Bool = false
    @Published var children: [FileNode]?
    @Published var isExpanded: Bool = false
    @Published var content: String {
        didSet { if fileURL != nil { isDirty = true } }
    }

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

    var url: URL? { fileURL }
    @Published var metadata: FileMetadata?

    init(id: UUID = UUID(), name: String, type: FileNodeType, path: String, url: URL? = nil, children: [FileNode]? = nil, content: String = "") {
        self.id = id
        self.name = name
        self.type = type
        self.path = path
        self.fileURL = url
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
            FileNode(name: "jvm", type: .directory, path: "/my-project/jvm", children: [
                FileNode(name: "Main.kt", type: .file, path: "/my-project/jvm/Main.kt",
                    content: """
                    package com.example

                    import kotlinx.coroutines.*
                    import kotlin.math.*

                    data class Vector2(val x: Double, val y: Double) {
                        operator fun plus(other: Vector2) = Vector2(x + other.x, y + other.y)
                        operator fun times(scalar: Double) = Vector2(x * scalar, y * scalar)
                        val magnitude get() = sqrt(x * x + y * y)
                        fun normalized() = this * (1.0 / magnitude)
                    }

                    suspend fun computeAsync(value: Int): Int = withContext(Dispatchers.Default) {
                        (1..value).sum()
                    }

                    fun main() = runBlocking {
                        val v1 = Vector2(3.0, 4.0)
                        println("Magnitude: ${v1.magnitude}")
                        println("Sum: ${computeAsync(100)}")
                    }
                    """),
                FileNode(name: "Analysis.scala", type: .file, path: "/my-project/jvm/Analysis.scala",
                    content: """
                    import scala.collection.parallel.CollectionConverters._
                    import scala.math._

                    object Analysis extends App {
                      case class DataPoint(x: Double, y: Double, label: String)

                      val data = List(
                        DataPoint(1.0, 2.0, "a"),
                        DataPoint(3.0, 4.0, "b"),
                        DataPoint(5.0, 6.0, "c"),
                      )

                      def euclidean(a: DataPoint, b: DataPoint): Double =
                        sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2))

                      val centroid = DataPoint(
                        data.map(_.x).sum / data.length,
                        data.map(_.y).sum / data.length,
                        "centroid"
                      )

                      val distances = data.par.map(p => p.label -> euclidean(p, centroid))
                      distances.foreach { case (label, dist) => println(s"$label: $dist") }
                    }
                    """),
            ]),
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
                FileNode(name: "api.ts", type: .file, path: "/my-project/scripts/api.ts",
                    content: """
                    // TypeScript API client

                    interface User {
                      id: number;
                      name: string;
                      email: string;
                      createdAt: Date;
                    }

                    interface ApiResponse<T> {
                      data: T;
                      status: number;
                      message: string;
                    }

                    type HttpMethod = 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH';

                    class ApiClient {
                      private baseUrl: string;
                      private headers: Record<string, string>;

                      constructor(baseUrl: string, apiKey?: string) {
                        this.baseUrl = baseUrl;
                        this.headers = {
                          'Content-Type': 'application/json',
                          ...(apiKey ? { 'Authorization': `Bearer ${apiKey}` } : {}),
                        };
                      }

                      async request<T>(method: HttpMethod, path: string, body?: unknown): Promise<ApiResponse<T>> {
                        const url = `${this.baseUrl}${path}`;
                        const response = await fetch(url, {
                          method,
                          headers: this.headers,
                          body: body ? JSON.stringify(body) : undefined,
                        });
                        const data = await response.json() as T;
                        return { data, status: response.status, message: response.statusText };
                      }

                      async getUser(id: number): Promise<User> {
                        const res = await this.request<User>('GET', `/users/${id}`);
                        return res.data;
                      }

                      async createUser(user: Omit<User, 'id' | 'createdAt'>): Promise<User> {
                        const res = await this.request<User>('POST', '/users', user);
                        return res.data;
                      }
                    }

                    export { ApiClient };
                    export type { User, ApiResponse };
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
            FileNode(name: "web", type: .directory, path: "/my-project/web", children: [
                FileNode(name: "index.html", type: .file, path: "/my-project/web/index.html",
                    content: """
                    <!DOCTYPE html>
                    <html lang="en">
                    <head>
                        <meta charset="UTF-8">
                        <meta name="viewport" content="width=device-width, initial-scale=1.0">
                        <title>My Project</title>
                        <link rel="stylesheet" href="styles.css">
                    </head>
                    <body>
                        <!-- Main container -->
                        <div id="app" class="container">
                            <header class="header">
                                <h1 class="title">Welcome</h1>
                                <nav class="nav">
                                    <a href="/" class="nav-link active">Home</a>
                                    <a href="/about" class="nav-link">About</a>
                                </nav>
                            </header>
                            <main class="main-content">
                                <p id="description">Hello from <strong>my-project</strong>!</p>
                            </main>
                        </div>
                        <script src="app.js"></script>
                    </body>
                    </html>
                    """),
                FileNode(name: "styles.css", type: .file, path: "/my-project/web/styles.css",
                    content: """
                    /* Global styles */
                    *, *::before, *::after {
                        box-sizing: border-box;
                        margin: 0;
                        padding: 0;
                    }

                    :root {
                        --color-bg: #1e2124;
                        --color-text: #cdd6f4;
                        --color-accent: #89b4fa;
                        --font-mono: 'JetBrains Mono', monospace;
                    }

                    body {
                        background-color: var(--color-bg);
                        color: var(--color-text);
                        font-family: var(--font-mono);
                        font-size: 14px;
                        line-height: 1.6;
                    }

                    .container {
                        max-width: 1200px;
                        margin: 0 auto;
                        padding: 20px;
                    }

                    .header {
                        display: flex;
                        justify-content: space-between;
                        align-items: center;
                        padding: 16px 0;
                        border-bottom: 1px solid #313244;
                    }

                    .title {
                        font-size: 24px;
                        font-weight: 600;
                        color: var(--color-accent);
                    }

                    .nav-link {
                        color: var(--color-text);
                        text-decoration: none;
                        margin-left: 16px;
                        opacity: 0.7;
                        transition: opacity 0.2s;
                    }

                    .nav-link:hover, .nav-link.active {
                        opacity: 1;
                        color: var(--color-accent);
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
