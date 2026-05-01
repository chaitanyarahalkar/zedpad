import Foundation

enum CodexRole { case user, agent, system }

struct CodexMessage: Identifiable {
    let id: String
    let role: CodexRole
    var content: String
    var isStreaming: Bool = false
    var fileChanges: [FileChangeDiff] = []
    var commandOutput: String? = nil
    var commandText: String? = nil
}

struct FileChangeDiff: Identifiable {
    let id: String
    let path: String
    let diff: String
    var decision: DiffDecision = .pending
}

enum DiffDecision { case pending, accepted, declined }

struct CodexApproval {
    let requestId: Int
    let type: ApprovalType
    let path: String?
    let diff: String?
    let command: String?
    let itemId: String

    enum ApprovalType { case fileChange, command }
}
