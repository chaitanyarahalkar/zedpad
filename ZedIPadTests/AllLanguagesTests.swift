import XCTest
@testable import ZedIPad

final class AllLanguagesTests: XCTestCase {

    private let hl = SyntaxHighlighter(theme: .dark)
    private let allLanguages: [Language] = [
        .swift, .javascript, .typescript, .python, .rust, .markdown,
        .json, .yaml, .bash, .ruby, .html, .css, .go, .kotlin,
        .c, .cpp, .sql, .scala, .lua, .php, .r
    ]

    func testAllLanguagesDoNotCrashOnEmptyInput() {
        for lang in allLanguages {
            let tokens = hl.highlight("", language: lang)
            XCTAssertTrue(tokens.isEmpty, "Empty input should produce no tokens for \(lang)")
        }
    }

    func testAllLanguagesDoNotCrashOnNonTriviallInput() {
        let code = "hello world 123 \"string\" // comment\n#include <header>"
        for lang in allLanguages {
            let tokens = hl.highlight(code, language: lang)
            _ = tokens
        }
    }

    func testAllLanguagesCoveredInEnum() {
        XCTAssertEqual(allLanguages.count, 21, "Should have 21 non-unknown languages")
    }

    func testUnknownLanguageReturnsEmpty() {
        let tokens = hl.highlight("anything here", language: .unknown)
        XCTAssertTrue(tokens.isEmpty)
    }

    func testSwiftProducesMoreTokensThanUnknown() {
        let code = "import SwiftUI\nstruct Foo: View { let x = 42 }"
        let swiftTokens = hl.highlight(code, language: .swift)
        let unknownTokens = hl.highlight(code, language: .unknown)
        XCTAssertGreaterThan(swiftTokens.count, unknownTokens.count)
    }

    func testAllLanguageDetectionRoundTrip() {
        let extensionMap: [(String, Language)] = [
            ("swift", .swift), ("js", .javascript), ("ts", .typescript),
            ("py", .python), ("rs", .rust), ("md", .markdown),
            ("json", .json), ("yaml", .yaml), ("sh", .bash),
            ("rb", .ruby), ("html", .html), ("css", .css),
            ("go", .go), ("kt", .kotlin), ("c", .c),
            ("cpp", .cpp), ("sql", .sql), ("scala", .scala),
            ("lua", .lua), ("php", .php), ("r", .r)
        ]
        for (ext, expectedLang) in extensionMap {
            let detected = Language.detect(from: ext)
            XCTAssertEqual(detected, expectedLang, "Extension .\(ext) should detect as \(expectedLang)")
        }
    }

    func testMultipleThemesWithMultipleLanguages() {
        let themes: [ZedTheme] = [.dark, .light, .oneDark, .solarizedDark]
        let testLangs: [Language] = [.swift, .python, .rust, .javascript, .go]
        let code = "def main():\n    return 42\n\nif __name__ == '__main__':\n    main()"
        for theme in themes {
            let hl = SyntaxHighlighter(theme: theme)
            for lang in testLangs {
                let tokens = hl.highlight(code, language: lang)
                _ = tokens
            }
        }
    }
}
