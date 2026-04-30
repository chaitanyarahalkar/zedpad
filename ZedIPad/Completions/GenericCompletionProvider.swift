import Foundation

class GenericCompletionProvider {

    func completions(source: String, prefix: String, language: Language) -> [CompletionItem] {
        guard !prefix.isEmpty else { return [] }
        let lower = prefix.lowercased()
        var items: [CompletionItem] = []

        // Extract identifiers from source
        items.append(contentsOf: extractIdentifiers(from: source, prefix: lower))

        // Language keywords
        items.append(contentsOf: keywords(for: language))

        // Language snippets
        items.append(contentsOf: snippets(for: language))

        // Filter and score
        return items
            .filter { fuzzyMatch(prefix: lower, text: $0.label.lowercased()) }
            .map { item -> CompletionItem in
                var scored = item
                if item.label.lowercased().hasPrefix(lower) {
                    scored.score += 100 + (50 - min(item.label.count, 50))
                } else {
                    scored.score += 20
                }
                return scored
            }
    }

    private func extractIdentifiers(from source: String, prefix: String) -> [CompletionItem] {
        let pattern = "\\b[a-zA-Z_][a-zA-Z0-9_]{2,}\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(source.startIndex..., in: source)
        let matches = regex.matches(in: source, range: range)

        var frequency: [String: Int] = [:]
        for match in matches {
            if let r = Range(match.range, in: source) {
                let word = String(source[r])
                frequency[word, default: 0] += 1
            }
        }

        return frequency
            .filter { $0.key.lowercased().hasPrefix(prefix) }
            .map { word, count in
                CompletionItem(label: word, insertText: word, kind: .variable,
                               detail: nil, score: min(count * 5, 50))
            }
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

    // MARK: - Language Keywords

    private func keywords(for language: Language) -> [CompletionItem] {
        let words: [String]
        switch language {
        case .python:
            words = ["def","class","import","from","return","if","elif","else","for","while",
                     "in","not","and","or","is","None","True","False","try","except","finally",
                     "raise","with","as","pass","break","continue","lambda","yield","async","await",
                     "global","nonlocal","del","assert","print","len","range","list","dict","set",
                     "tuple","str","int","float","bool","open","type","isinstance","hasattr"]
        case .rust:
            words = ["fn","let","mut","const","static","struct","enum","trait","impl","use",
                     "mod","pub","if","else","match","for","while","loop","return","break",
                     "continue","in","where","type","self","Self","super","crate","extern",
                     "unsafe","async","await","move","ref","true","false","dyn","Box","Vec",
                     "String","Option","Result","Some","None","Ok","Err","println!","eprintln!",
                     "format!","vec!","HashMap","HashSet","Arc","Mutex","Rc","Cell","RefCell"]
        case .markdown:
            words = ["#","##","###","####","**","*","```","---","---","[](","![](",">","- ","1. "]
        case .json:
            words = ["true","false","null"]
        case .yaml:
            words = ["true","false","null","yes","no"]
        case .bash:
            words = ["if","then","else","elif","fi","for","do","done","while","until","case",
                     "esac","function","return","echo","exit","export","source","cd","ls","grep",
                     "sed","awk","cat","mkdir","rm","cp","mv","pwd","chmod","chown","sudo"]
        case .ruby:
            words = ["def","class","module","end","if","unless","else","elsif","for","while",
                     "until","do","begin","rescue","ensure","raise","return","yield","self",
                     "super","nil","true","false","require","include","extend","attr_accessor",
                     "attr_reader","attr_writer","puts","print","p","gets","chomp"]
        default:
            words = ["if","else","for","while","return","true","false","null","void","int",
                     "string","bool","class","function","import","export","const","let","var"]
        }
        return words.map { CompletionItem(label: $0, insertText: $0, kind: .keyword, detail: "\(language.rawValue) keyword", score: 10) }
    }

    // MARK: - Language Snippets

    private func snippets(for language: Language) -> [CompletionItem] {
        switch language {
        case .python:
            return [
                CompletionItem(label: "def", insertText: "def <#name#>(<#params#>):\n    <#body#>", kind: .snippet, detail: "function", score: 15),
                CompletionItem(label: "class", insertText: "class <#Name#>:\n    def __init__(self):\n        <#body#>", kind: .snippet, detail: "class", score: 15),
                CompletionItem(label: "if __main__", insertText: "if __name__ == \"__main__\":\n    <#body#>", kind: .snippet, detail: "main guard", score: 15),
                CompletionItem(label: "with open", insertText: "with open(<#path#>, <#mode#>) as f:\n    <#body#>", kind: .snippet, detail: "file open", score: 15),
                CompletionItem(label: "try", insertText: "try:\n    <#body#>\nexcept <#Exception#> as e:\n    <#handler#>", kind: .snippet, detail: "try/except", score: 15),
            ]
        case .rust:
            return [
                CompletionItem(label: "fn main", insertText: "fn main() {\n    <#body#>\n}", kind: .snippet, detail: "main function", score: 15),
                CompletionItem(label: "impl", insertText: "impl <#Type#> {\n    <#body#>\n}", kind: .snippet, detail: "impl block", score: 15),
                CompletionItem(label: "match", insertText: "match <#value#> {\n    <#pattern#> => <#body#>,\n    _ => <#default#>,\n}", kind: .snippet, detail: "match", score: 15),
                CompletionItem(label: "if let", insertText: "if let <#pattern#> = <#expr#> {\n    <#body#>\n}", kind: .snippet, detail: "if let", score: 15),
            ]
        case .bash:
            return [
                CompletionItem(label: "if", insertText: "if [ <#condition#> ]; then\n    <#body#>\nfi", kind: .snippet, detail: "if block", score: 15),
                CompletionItem(label: "for", insertText: "for <#item#> in <#list#>; do\n    <#body#>\ndone", kind: .snippet, detail: "for loop", score: 15),
                CompletionItem(label: "function", insertText: "<#name#>() {\n    <#body#>\n}", kind: .snippet, detail: "function", score: 15),
            ]
        default:
            return []
        }
    }
}
