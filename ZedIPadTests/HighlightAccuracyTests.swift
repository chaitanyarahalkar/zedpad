import XCTest
@testable import ZedIPad

final class HighlightAccuracyTests: XCTestCase {

    func testSwiftStructHighlighted() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "struct Point { var x: Double; var y: Double }"
        let tokens = hl.highlight(code, language: .swift)
        let structToken = tokens.first { code[$0.range] == "struct" }
        XCTAssertNotNil(structToken)
        XCTAssertEqual(structToken?.color, ZedTheme.dark.syntaxKeyword)
    }

    func testSwiftClassHighlighted() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "class Manager: ObservableObject { }"
        let tokens = hl.highlight(code, language: .swift)
        let classToken = tokens.first { code[$0.range] == "class" }
        XCTAssertNotNil(classToken)
    }

    func testPythonClassHighlighted() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "class MyClass:\n    def __init__(self): pass"
        let tokens = hl.highlight(code, language: .python)
        let classToken = tokens.first { code[$0.range] == "class" }
        XCTAssertNotNil(classToken)
    }

    func testRustStructHighlighted() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "struct Config { pub name: String, pub value: i32 }"
        let tokens = hl.highlight(code, language: .rust)
        let structToken = tokens.first { code[$0.range] == "struct" }
        XCTAssertNotNil(structToken)
    }

    func testGoStructHighlighted() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "type Config struct { Name string; Value int }"
        let tokens = hl.highlight(code, language: .go)
        let structToken = tokens.first { code[$0.range] == "struct" }
        XCTAssertNotNil(structToken)
    }

    func testKotlinDataClassHighlighted() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "data class User(val name: String, val age: Int)"
        let tokens = hl.highlight(code, language: .kotlin)
        let dataToken = tokens.first { code[$0.range] == "data" }
        XCTAssertNotNil(dataToken)
    }

    func testScalaCaseClassHighlighted() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "case class Point(x: Double, y: Double)"
        let tokens = hl.highlight(code, language: .scala)
        let caseToken = tokens.first { code[$0.range] == "case" }
        XCTAssertNotNil(caseToken)
    }

    func testPHPClassHighlighted() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "class User extends Model { public $name; }"
        let tokens = hl.highlight(code, language: .php)
        let classToken = tokens.first { code[$0.range] == "class" }
        XCTAssertNotNil(classToken)
    }
}
