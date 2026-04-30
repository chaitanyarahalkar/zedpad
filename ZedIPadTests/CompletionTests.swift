import XCTest
@testable import ZedIPad

@MainActor
final class SwiftCompletionProviderTests: XCTestCase {
    let provider = SwiftCompletionProvider()

    func testExtractsFunctionNames() {
        let source = "func myFunction() {}\nfunc anotherFunc(x: Int) -> String { return \"\" }"
        let items = provider.completions(source: source, prefix: "my")
        XCTAssertTrue(items.contains { $0.label == "myFunction" }, "Should find myFunction")
    }

    func testExtractsTypeNames() {
        let source = "struct MyStruct {}\nclass MyClass {}\nenum MyEnum { case a }"
        let items = provider.completions(source: source, prefix: "My")
        let labels = items.map(\.label)
        XCTAssertTrue(labels.contains("MyStruct"))
        XCTAssertTrue(labels.contains("MyClass"))
        XCTAssertTrue(labels.contains("MyEnum"))
    }

    func testExtractsVariables() {
        let source = "let myVariable = 42\nvar anotherVar: String = \"\""
        let items = provider.completions(source: source, prefix: "my")
        XCTAssertTrue(items.contains { $0.label == "myVariable" })
    }

    func testKeywordsPresent() {
        let items = provider.completions(source: "", prefix: "func")
        XCTAssertFalse(items.isEmpty)
        XCTAssertTrue(items.contains { $0.label == "func" })
    }

    func testSwiftUIKeywords() {
        let items = provider.completions(source: "", prefix: "@Pub")
        XCTAssertTrue(items.contains { $0.label == "@Published" })
    }

    func testFuzzyMatch() {
        let items = provider.completions(source: "", prefix: "fnc")
        // "func" should fuzzy-match "fnc" (f-n-c are subsequence of func)
        // Actually func has f-u-n-c, "fnc" = f,n,c — matches
        XCTAssertTrue(items.contains { $0.label == "func" })
    }

    func testEmptyPrefixReturnsEmpty() {
        let items = provider.completions(source: "func hello() {}", prefix: "")
        XCTAssertTrue(items.isEmpty)
    }

    func testExactPrefixScoresHigher() {
        let source = "func printMessage() {}\nfunc processMessage() {}"
        let items = provider.completions(source: source, prefix: "print")
        XCTAssertFalse(items.isEmpty)
        // Items starting with "print" should score higher
        let topItem = items.first!
        XCTAssertTrue(topItem.label.lowercased().hasPrefix("print"))
    }

    func testSwiftTypes() {
        let items = provider.completions(source: "", prefix: "Str")
        XCTAssertTrue(items.contains { $0.label == "String" })
    }
}

@MainActor
final class JSCompletionProviderTests: XCTestCase {
    let provider = JSCompletionProvider()

    func testExtractsFunctions() {
        let source = "function greet(name) { return name; }\nconst add = (a, b) => a + b;"
        let items = provider.completions(source: source, prefix: "gr")
        XCTAssertTrue(items.contains { $0.label == "greet" })
    }

    func testExtractsVariables() {
        let source = "const myVariable = 42;\nlet anotherVar = 'hello';"
        let items = provider.completions(source: source, prefix: "my")
        XCTAssertTrue(items.contains { $0.label == "myVariable" })
    }

    func testKeywordsPresent() {
        let items = provider.completions(source: "", prefix: "con")
        XCTAssertTrue(items.contains { $0.label == "const" })
    }

    func testReactHooks() {
        let items = provider.completions(source: "", prefix: "use")
        let labels = items.map(\.label)
        XCTAssertTrue(labels.contains("useState"))
        XCTAssertTrue(labels.contains("useEffect"))
    }

    func testBuiltins() {
        let items = provider.completions(source: "", prefix: "JSON")
        let labels = items.map(\.label)
        XCTAssertTrue(labels.contains("JSON.parse") || labels.contains("JSON.stringify"))
    }

    func testEmptyPrefix() {
        let items = provider.completions(source: "const x = 1;", prefix: "")
        XCTAssertTrue(items.isEmpty)
    }

    func testTSInterfaces() {
        let source = "interface UserProfile { name: string; }\ntype ApiResponse = { data: any; }"
        let items = provider.completions(source: source, prefix: "User")
        XCTAssertTrue(items.contains { $0.label == "UserProfile" })
    }
}

@MainActor
final class GenericCompletionProviderTests: XCTestCase {
    let provider = GenericCompletionProvider()

    func testExtractsPythonIdentifiers() {
        let source = "def calculate_total(items):\n    result = sum(items)\n    return result"
        let items = provider.completions(source: source, prefix: "cal", language: .python)
        XCTAssertTrue(items.contains { $0.label == "calculate_total" })
    }

    func testPythonKeywords() {
        let items = provider.completions(source: "", prefix: "def", language: .python)
        XCTAssertTrue(items.contains { $0.label == "def" })
    }

    func testRustKeywords() {
        let items = provider.completions(source: "", prefix: "fn", language: .rust)
        XCTAssertTrue(items.contains { $0.label == "fn" })
    }

    func testFrequencyScoring() {
        let source = "myVar myVar myVar otherVar"
        let items = provider.completions(source: source, prefix: "my", language: .unknown)
        let myVarItem = items.first { $0.label == "myVar" }
        let otherItem = items.first { $0.label == "otherVar" }
        if let mv = myVarItem, let ov = otherItem {
            XCTAssertGreaterThan(mv.score, ov.score, "Higher frequency should score higher")
        }
    }

    func testPythonSnippets() {
        let items = provider.completions(source: "", prefix: "def", language: .python)
        XCTAssertTrue(items.contains { $0.kind == .snippet })
    }

    func testRustSnippets() {
        let items = provider.completions(source: "", prefix: "fn", language: .rust)
        XCTAssertTrue(items.contains { $0.kind == .snippet })
    }
}

@MainActor
final class CompletionManagerTests: XCTestCase {

    func testPrefixExtraction() {
        let manager = CompletionManager()
        let source = "let myVariable = 42"
        // cursor after "myVa"
        let offset = 8  // "let myVa" -> prefix = "myVa"
        let prefix = manager.extractPrefix(source: source, at: offset)
        XCTAssertEqual(prefix, "myVa")
    }

    func testPrefixAtStart() {
        let manager = CompletionManager()
        let prefix = manager.extractPrefix(source: "hello world", at: 0)
        XCTAssertEqual(prefix, "")
    }

    func testPrefixMiddleOfWord() {
        let manager = CompletionManager()
        let prefix = manager.extractPrefix(source: "func myFunction(", at: 15)
        XCTAssertEqual(prefix, "myFunction")
    }

    func testSelectNext() {
        let manager = CompletionManager()
        manager.items = [
            CompletionItem(label: "a", insertText: "a", kind: .variable, detail: nil),
            CompletionItem(label: "b", insertText: "b", kind: .variable, detail: nil),
        ]
        manager.isVisible = true
        XCTAssertEqual(manager.selectedIndex, 0)
        manager.selectNext()
        XCTAssertEqual(manager.selectedIndex, 1)
        manager.selectNext()
        XCTAssertEqual(manager.selectedIndex, 1, "Should clamp at last index")
    }

    func testSelectPrev() {
        let manager = CompletionManager()
        manager.items = [
            CompletionItem(label: "a", insertText: "a", kind: .variable, detail: nil),
            CompletionItem(label: "b", insertText: "b", kind: .variable, detail: nil),
        ]
        manager.selectedIndex = 1
        manager.selectPrev()
        XCTAssertEqual(manager.selectedIndex, 0)
        manager.selectPrev()
        XCTAssertEqual(manager.selectedIndex, 0, "Should clamp at 0")
    }

    func testDismiss() {
        let manager = CompletionManager()
        manager.items = [CompletionItem(label: "a", insertText: "a", kind: .keyword, detail: nil)]
        manager.isVisible = true
        manager.dismiss()
        XCTAssertFalse(manager.isVisible)
        XCTAssertTrue(manager.items.isEmpty)
    }

    func testSelected() {
        let manager = CompletionManager()
        XCTAssertNil(manager.selected)
        let item = CompletionItem(label: "hello", insertText: "hello", kind: .function, detail: nil)
        manager.items = [item]
        XCTAssertEqual(manager.selected?.label, "hello")
    }

    func testRequestSwift() {
        let manager = CompletionManager()
        let source = "func myFunction() {}\nlet myVariable = 1"
        manager.request(source: source, cursorOffset: 5, language: .swift)
        // prefix after "func " is "" — so should dismiss
        XCTAssertFalse(manager.isVisible)
    }

    func testRequestWithPrefix() {
        let manager = CompletionManager()
        // "fu" prefix matches "func", "final", etc. — Swift keywords
        let source = "fu"
        manager.request(source: source, cursorOffset: 2, language: .swift)
        XCTAssertTrue(manager.isVisible)
        XCTAssertFalse(manager.items.isEmpty)
    }

    func testMRUBoost() {
        let manager = CompletionManager()
        let item = CompletionItem(label: "myFunc", insertText: "myFunc", kind: .function, detail: nil, score: 50)
        manager.mruBoosts["myFunc"] = 3
        // Request and check that myFunc gets boosted
        let source = "func myFunc() {}"
        manager.request(source: source, cursorOffset: 6, language: .swift)
        if let found = manager.items.first(where: { $0.label == "myFunc" }) {
            XCTAssertGreaterThan(found.score, item.score)
        }
    }
}

@MainActor
final class CompletionItemTests: XCTestCase {
    func testKindIcons() {
        XCTAssertEqual(CompletionKind.keyword.icon, "k.square.fill")
        XCTAssertEqual(CompletionKind.function.icon, "f.square.fill")
        XCTAssertEqual(CompletionKind.type.icon, "t.square.fill")
        XCTAssertEqual(CompletionKind.variable.icon, "v.square.fill")
        XCTAssertEqual(CompletionKind.snippet.icon, "doc.badge.plus")
    }

    func testItemEquality() {
        let item = CompletionItem(label: "hello", insertText: "hello", kind: .keyword, detail: nil)
        XCTAssertEqual(item, item)
    }

    func testDefaultScore() {
        let item = CompletionItem(label: "test", insertText: "test", kind: .variable, detail: nil)
        XCTAssertEqual(item.score, 0)
    }
}
