import SwiftUI

struct CompletionItem: Identifiable, Equatable {
    let id = UUID()
    let label: String
    let insertText: String
    let kind: CompletionKind
    let detail: String?
    var score: Int = 0

    static func == (lhs: CompletionItem, rhs: CompletionItem) -> Bool {
        lhs.id == rhs.id
    }
}

enum CompletionKind: String {
    case keyword, function, type, variable, snippet, module, property

    var icon: String {
        switch self {
        case .keyword:  return "k.square.fill"
        case .function: return "f.square.fill"
        case .type:     return "t.square.fill"
        case .variable: return "v.square.fill"
        case .snippet:  return "doc.badge.plus"
        case .module:   return "shippingbox.fill"
        case .property: return "p.square.fill"
        }
    }

    var color: Color {
        switch self {
        case .keyword:  return .orange
        case .function: return .blue
        case .type:     return .purple
        case .variable: return .green
        case .snippet:  return .teal
        case .module:   return .yellow
        case .property: return .cyan
        }
    }
}
