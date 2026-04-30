import Foundation
import SwiftParser
import SwiftSyntax

class SwiftCompletionProvider {

    private let swiftKeywords: [CompletionItem] = {
        let keywords = [
            ("import", "import "),
            ("func", "func <#name#>(<#params#>) {\n    <#body#>\n}"),
            ("var", "var <#name#>: <#Type#>"),
            ("let", "let <#name#>: <#Type#> = <#value#>"),
            ("struct", "struct <#Name#> {\n    <#body#>\n}"),
            ("class", "class <#Name#> {\n    <#body#>\n}"),
            ("enum", "enum <#Name#> {\n    case <#case#>\n}"),
            ("protocol", "protocol <#Name#> {\n    <#requirements#>\n}"),
            ("extension", "extension <#Type#> {\n    <#body#>\n}"),
            ("if", "if <#condition#> {\n    <#body#>\n}"),
            ("guard", "guard <#condition#> else { return }"),
            ("for", "for <#item#> in <#collection#> {\n    <#body#>\n}"),
            ("while", "while <#condition#> {\n    <#body#>\n}"),
            ("switch", "switch <#value#> {\ncase <#pattern#>:\n    <#body#>\ndefault:\n    break\n}"),
            ("return", "return "),
            ("async", "async "),
            ("await", "await "),
            ("throw", "throw "),
            ("try", "try "),
            ("throws", "throws"),
            ("static", "static "),
            ("private", "private "),
            ("public", "public "),
            ("internal", "internal "),
            ("final", "final "),
            ("override", "override "),
            ("mutating", "mutating "),
            ("weak", "weak "),
            ("lazy", "lazy "),
            ("@Published", "@Published var <#name#>: <#Type#>"),
            ("@State", "@State private var <#name#>: <#Type#>"),
            ("@Binding", "@Binding var <#name#>: <#Type#>"),
            ("@ObservedObject", "@ObservedObject var <#name#>: <#Type#>"),
            ("@StateObject", "@StateObject private var <#name#>: <#Type#>"),
            ("@EnvironmentObject", "@EnvironmentObject var <#name#>: <#Type#>"),
            ("@MainActor", "@MainActor"),
            ("print", "print(<#value#>)"),
            ("nil", "nil"),
            ("true", "true"),
            ("false", "false"),
            ("self", "self"),
            ("super", "super"),
            ("init", "init(<#params#>) {\n    <#body#>\n}"),
        ]
        return keywords.map { CompletionItem(label: $0.0, insertText: $0.1, kind: .keyword, detail: "keyword", score: 10) }
    }()

    private let swiftTypes: [CompletionItem] = {
        let types = ["String", "Int", "Double", "Float", "Bool", "Array", "Dictionary", "Set",
                     "Optional", "Any", "AnyObject", "Void", "Never", "UUID", "Date", "Data",
                     "URL", "Error", "View", "Color", "Font", "Text", "VStack", "HStack", "ZStack",
                     "Button", "Image", "List", "NavigationView", "NavigationStack", "ObservableObject",
                     "Identifiable", "Hashable", "Equatable", "Comparable", "Codable", "Encodable",
                     "Decodable", "Collection", "Sequence", "IteratorProtocol"]
        return types.map { CompletionItem(label: $0, insertText: $0, kind: .type, detail: "Swift type", score: 8) }
    }()

    func completions(source: String, prefix: String) -> [CompletionItem] {
        guard !prefix.isEmpty else { return [] }
        let lower = prefix.lowercased()

        // Parse with swift-syntax
        var items: [CompletionItem] = []
        let parsed = parseSymbols(from: source)
        items.append(contentsOf: parsed)

        // Add keywords and types
        items.append(contentsOf: swiftKeywords)
        items.append(contentsOf: swiftTypes)

        // Filter and score
        return items
            .filter { fuzzyMatch(prefix: lower, text: $0.label.lowercased()) }
            .map { item -> CompletionItem in
                var scored = item
                if item.label.lowercased().hasPrefix(lower) {
                    scored.score += 100 + (50 - min(item.label.count, 50))
                } else {
                    scored.score += 30
                }
                return scored
            }
    }

    private func parseSymbols(from source: String) -> [CompletionItem] {
        var items: [CompletionItem] = []
        let sourceFile = Parser.parse(source: source)
        let visitor = SymbolExtractorVisitor(viewMode: .sourceAccurate)
        visitor.walk(sourceFile)
        items.append(contentsOf: visitor.functions.map {
            CompletionItem(label: $0, insertText: $0, kind: .function, detail: "func", score: 50)
        })
        items.append(contentsOf: visitor.types.map {
            CompletionItem(label: $0, insertText: $0, kind: .type, detail: "type", score: 45)
        })
        items.append(contentsOf: visitor.variables.map {
            CompletionItem(label: $0, insertText: $0, kind: .variable, detail: "var", score: 40)
        })
        return items
    }

    private func fuzzyMatch(prefix: String, text: String) -> Bool {
        if text.hasPrefix(prefix) { return true }
        var pi = prefix.startIndex
        for ch in text {
            if pi == prefix.endIndex { return true }
            if ch == prefix[pi] { pi = prefix.index(after: pi) }
        }
        return pi == prefix.endIndex
    }
}

// MARK: - AST Visitor

private final class SymbolExtractorVisitor: SyntaxVisitor {
    var functions: [String] = []
    var types: [String] = []
    var variables: [String] = []

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        functions.append(node.name.text)
        return .visitChildren
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        types.append(node.name.text)
        return .visitChildren
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        types.append(node.name.text)
        return .visitChildren
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        types.append(node.name.text)
        return .visitChildren
    }

    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        types.append(node.name.text)
        return .visitChildren
    }

    override func visit(_ node: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
        types.append(node.name.text)
        return .visitChildren
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        for binding in node.bindings {
            if let id = binding.pattern.as(IdentifierPatternSyntax.self) {
                variables.append(id.identifier.text)
            }
        }
        return .visitChildren
    }
}
