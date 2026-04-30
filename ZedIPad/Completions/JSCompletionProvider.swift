import Foundation
import JavaScriptCore

class JSCompletionProvider {
    private let context = JSContext()!
    private var cache: [Int: [CompletionItem]] = [:]

    init() { setupContext() }

    private func setupContext() {
        let script = """
        function extractSymbols(source) {
            var symbols = [];
            var seen = {};

            // Functions
            var fnRe = /(?:function\\s+(\\w+)|(?:const|let|var)\\s+(\\w+)\\s*=\\s*(?:async\\s*)?(?:\\([^)]*\\)|\\w+)\\s*=>)/g;
            var m;
            while ((m = fnRe.exec(source)) !== null) {
                var name = m[1] || m[2];
                if (name && !seen[name]) { seen[name] = 1; symbols.push({label: name, kind: 'function', score: 50}); }
            }

            // Classes
            var clsRe = /class\\s+(\\w+)/g;
            while ((m = clsRe.exec(source)) !== null) {
                if (!seen[m[1]]) { seen[m[1]] = 1; symbols.push({label: m[1], kind: 'type', score: 45}); }
            }

            // Variables
            var varRe = /(?:const|let|var)\\s+(\\w+)/g;
            while ((m = varRe.exec(source)) !== null) {
                if (!seen[m[1]]) { seen[m[1]] = 1; symbols.push({label: m[1], kind: 'variable', score: 40}); }
            }

            // Interfaces/types (TS)
            var ifaceRe = /(?:interface|type)\\s+(\\w+)/g;
            while ((m = ifaceRe.exec(source)) !== null) {
                if (!seen[m[1]]) { seen[m[1]] = 1; symbols.push({label: m[1], kind: 'type', score: 45}); }
            }

            return symbols;
        }

        function getCompletions(source, prefix) {
            var lower = prefix.toLowerCase();
            var symbols = extractSymbols(source);

            var keywords = [
                {label:'const',kind:'keyword',score:10}, {label:'let',kind:'keyword',score:10},
                {label:'var',kind:'keyword',score:10}, {label:'function',kind:'keyword',score:10},
                {label:'class',kind:'keyword',score:10}, {label:'return',kind:'keyword',score:10},
                {label:'import',kind:'keyword',score:10}, {label:'export',kind:'keyword',score:10},
                {label:'async',kind:'keyword',score:10}, {label:'await',kind:'keyword',score:10},
                {label:'if',kind:'keyword',score:10}, {label:'else',kind:'keyword',score:10},
                {label:'for',kind:'keyword',score:10}, {label:'while',kind:'keyword',score:10},
                {label:'switch',kind:'keyword',score:10}, {label:'case',kind:'keyword',score:10},
                {label:'try',kind:'keyword',score:10}, {label:'catch',kind:'keyword',score:10},
                {label:'throw',kind:'keyword',score:10}, {label:'new',kind:'keyword',score:10},
                {label:'typeof',kind:'keyword',score:10}, {label:'instanceof',kind:'keyword',score:10},
                {label:'null',kind:'keyword',score:10}, {label:'undefined',kind:'keyword',score:10},
                {label:'true',kind:'keyword',score:10}, {label:'false',kind:'keyword',score:10},
                {label:'interface',kind:'keyword',score:10}, {label:'type',kind:'keyword',score:10},
                {label:'enum',kind:'keyword',score:10}, {label:'extends',kind:'keyword',score:10},
                {label:'implements',kind:'keyword',score:10}, {label:'readonly',kind:'keyword',score:10},
                // Common builtins
                {label:'console.log',kind:'function',score:20,detail:'console'},
                {label:'console.error',kind:'function',score:20,detail:'console'},
                {label:'console.warn',kind:'function',score:20,detail:'console'},
                {label:'Math.floor',kind:'function',score:15,detail:'Math'},
                {label:'Math.ceil',kind:'function',score:15,detail:'Math'},
                {label:'Math.random',kind:'function',score:15,detail:'Math'},
                {label:'JSON.parse',kind:'function',score:15,detail:'JSON'},
                {label:'JSON.stringify',kind:'function',score:15,detail:'JSON'},
                {label:'Array.from',kind:'function',score:15,detail:'Array'},
                {label:'Object.keys',kind:'function',score:15,detail:'Object'},
                {label:'Object.values',kind:'function',score:15,detail:'Object'},
                {label:'Promise.all',kind:'function',score:15,detail:'Promise'},
                {label:'setTimeout',kind:'function',score:15},
                // React hooks
                {label:'useState',kind:'function',score:25,detail:'React hook'},
                {label:'useEffect',kind:'function',score:25,detail:'React hook'},
                {label:'useCallback',kind:'function',score:25,detail:'React hook'},
                {label:'useMemo',kind:'function',score:25,detail:'React hook'},
                {label:'useRef',kind:'function',score:25,detail:'React hook'},
                {label:'useContext',kind:'function',score:25,detail:'React hook'},
            ];

            var all = symbols.concat(keywords);
            var filtered = all.filter(function(item) {
                var lbl = item.label.toLowerCase();
                if (lbl.indexOf(lower) === 0) { item.score += 100; return true; }
                // fuzzy
                var pi = 0;
                for (var i = 0; i < lbl.length && pi < lower.length; i++) {
                    if (lbl[i] === lower[pi]) pi++;
                }
                return pi === lower.length;
            });

            filtered.sort(function(a,b) { return b.score - a.score; });
            return filtered.slice(0, 15);
        }
        """
        context.evaluateScript(script)
    }

    func completions(source: String, prefix: String) -> [CompletionItem] {
        guard !prefix.isEmpty else { return [] }
        let hashKey = source.hashValue ^ prefix.hashValue
        if let cached = cache[hashKey] { return cached }

        guard let fn = context.objectForKeyedSubscript("getCompletions"),
              let result = fn.call(withArguments: [source, prefix]),
              result.isArray,
              let arr = result.toArray() else { return [] }

        let items: [CompletionItem] = arr.compactMap { obj -> CompletionItem? in
            guard let dict = obj as? [String: Any],
                  let label = dict["label"] as? String else { return nil }
            let kindStr = dict["kind"] as? String ?? "variable"
            let kind: CompletionKind = {
                switch kindStr {
                case "function": return .function
                case "type": return .type
                case "keyword": return .keyword
                default: return .variable
                }
            }()
            let score = dict["score"] as? Int ?? 10
            let detail = dict["detail"] as? String
            return CompletionItem(label: label, insertText: label, kind: kind, detail: detail, score: score)
        }

        cache[hashKey] = items
        return items
    }

    func invalidateCache() { cache.removeAll() }
}
