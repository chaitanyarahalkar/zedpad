import XCTest
@testable import ZedIPad

final class HTMLCSSTests: XCTestCase {

    func testHighlightHTML() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <title>My Page</title>
            <!-- This is a comment -->
        </head>
        <body>
            <h1 class="title">Hello World</h1>
            <p id="intro">Welcome to <strong>my</strong> page.</p>
        </body>
        </html>
        """
        let tokens = hl.highlight(code, language: .html)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testHighlightHTMLComment() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "<div><!-- comment here --></div>"
        let tokens = hl.highlight(code, language: .html)
        let commentTokens = tokens.filter { $0.color == ZedTheme.dark.syntaxComment }
        XCTAssertFalse(commentTokens.isEmpty)
    }

    func testHighlightCSS() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = """
        body {
            background-color: #1e2124;
            color: #cdd6f4;
            font-family: monospace;
            font-size: 14px;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }

        #header {
            background: linear-gradient(to right, #89b4fa, #cba6f7);
        }
        """
        let tokens = hl.highlight(code, language: .css)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testLanguageDetectionHTML() {
        XCTAssertEqual(Language.detect(from: "html"), .html)
        XCTAssertEqual(Language.detect(from: "htm"), .html)
    }

    func testLanguageDetectionCSS() {
        XCTAssertEqual(Language.detect(from: "css"), .css)
    }

    func testAllLanguageCasesHandled() {
        // Every Language case should produce a result (even if empty for .unknown)
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "hello world 123"
        let languages: [Language] = [.swift, .javascript, .typescript, .python, .rust,
                                      .markdown, .json, .yaml, .bash, .ruby, .html, .css, .unknown]
        for lang in languages {
            let tokens = hl.highlight(code, language: lang)
            // Just verify it doesn't crash
            _ = tokens
        }
    }

    func testLanguageDetectionAllExtensions() {
        let cases: [(String, Language)] = [
            ("html", .html), ("htm", .html),
            ("css", .css),
            ("swift", .swift),
            ("js", .javascript),
            ("ts", .typescript),
            ("tsx", .typescript),
            ("jsx", .typescript),
            ("py", .python),
            ("rs", .rust),
            ("md", .markdown),
            ("json", .json),
            ("yaml", .yaml),
            ("yml", .yaml),
            ("sh", .bash),
            ("bash", .bash),
            ("rb", .ruby),
            ("txt", .unknown),
            ("", .unknown),
        ]
        for (ext, expected) in cases {
            XCTAssertEqual(Language.detect(from: ext), expected,
                           "Extension .\(ext) should detect as \(expected)")
        }
    }
}
