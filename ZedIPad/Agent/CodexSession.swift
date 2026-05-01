import Foundation
import SwiftUI

@MainActor
class CodexSession: ObservableObject, Identifiable {
    let id = UUID()
    let config: CodexServerConfig

    @Published var messages: [CodexMessage] = []
    @Published var isConnected = false
    @Published var isThinking = false
    @Published var pendingApproval: CodexApproval? = nil
    @Published var connectionError: String? = nil
    @Published var currentTurnId: String? = nil

    private let client = CodexWSClient()
    private var threadId: String?
    private var notificationTask: Task<Void, Never>?
    var token: String = ""

    init(config: CodexServerConfig) {
        self.config = config
    }

    // MARK: - Connect

    func connect() async {
        connectionError = nil
        guard let url = URL(string: config.wsURL) else {
            connectionError = "Invalid URL: \(config.wsURL)"
            return
        }
        do {
            try await client.connect(url: url, token: token)
            try await client.initialize()
            threadId = try await client.startThread(model: config.model)
            isConnected = true
            startNotificationLoop()
            appendSystem("Connected to \(config.name) · model: \(config.model)")
        } catch let urlError as URLError where urlError.code == .badServerResponse {
            connectionError = "Server rejected the connection (HTTP 401 — wrong token, or server not running). Check the URL and token."
            isConnected = false
        } catch let urlError as URLError where urlError.code == .cannotConnectToHost || urlError.code == .networkConnectionLost {
            connectionError = "Cannot reach server at \(config.wsURL). Make sure it is running and your iPad is on the same network."
            isConnected = false
        } catch {
            connectionError = error.localizedDescription
            isConnected = false
        }
    }

    func disconnect() {
        Task { await client.disconnect() }
        notificationTask?.cancel()
        isConnected = false
        isThinking = false
        appendSystem("Disconnected.")
    }

    // MARK: - Send message

    func sendMessage(_ text: String, context: String? = nil) async {
        guard isConnected, let threadId else { return }
        var fullInput = text
        if let ctx = context, !ctx.isEmpty {
            fullInput = ctx + "\n\n" + text
        }
        let userMsg = CodexMessage(id: UUID().uuidString, role: .user, content: text)
        messages.append(userMsg)
        isThinking = true
        do {
            let turnId = try await client.startTurn(threadId: threadId, input: fullInput, model: config.model)
            currentTurnId = turnId
        } catch {
            isThinking = false
            appendSystem("Error: \(error.localizedDescription)")
        }
    }

    // MARK: - Approve

    func approve(_ approval: CodexApproval, decision: String) async {
        pendingApproval = nil
        do {
            try await client.respond(toRequestId: approval.requestId, result: ["decision": decision])
            if decision == "accept" || decision == "acceptForSession" {
                if let msgIdx = messages.lastIndex(where: { $0.fileChanges.contains(where: { $0.id == approval.itemId }) }) {
                    for i in messages[msgIdx].fileChanges.indices where messages[msgIdx].fileChanges[i].id == approval.itemId {
                        messages[msgIdx].fileChanges[i].decision = .accepted
                    }
                }
            }
        } catch {
            appendSystem("Approval error: \(error.localizedDescription)")
        }
    }

    func stopTurn() async {
        guard let turnId = currentTurnId else { return }
        do {
            try await client.interruptTurn(turnId: turnId)
        } catch {}
        isThinking = false
    }

    // MARK: - Notification loop

    private func startNotificationLoop() {
        let client = self.client
        notificationTask = Task { [weak self] in
            guard let self else { return }
            let stream = await client.notifications
            for await msg in stream {
                await MainActor.run { self.handle(inbound: msg) }
            }
        }
    }

    private func handle(inbound: CodexInboundMessage) {
        switch inbound {
        case .notification(let method, let params):
            handleNotification(method: method, params: params)
        case .serverRequest(let id, let method, let params):
            handleServerRequest(id: id, method: method, params: params)
        case .response:
            break
        }
    }

    private func handleNotification(method: String, params: [String: Any]) {
        switch method {
        case "turn/started":
            isThinking = true

        case "turn/completed":
            isThinking = false
            currentTurnId = nil

        case "item/started":
            let item = params["item"] as? [String: Any] ?? [:]
            let itemId = item["id"] as? String ?? UUID().uuidString
            let type = item["type"] as? String ?? ""
            if type == "agentMessage" {
                let msg = CodexMessage(id: itemId, role: .agent, content: "", isStreaming: true)
                messages.append(msg)
            } else if type == "commandExecution" {
                let cmd = item["command"] as? String ?? ""
                let msg = CodexMessage(id: itemId, role: .agent, content: "", isStreaming: true, commandText: cmd)
                messages.append(msg)
            }

        case "item/agentMessage/delta":
            let itemId = params["itemId"] as? String ?? ""
            let delta = (params["delta"] as? [String: Any])?["text"] as? String ?? ""
            if let idx = messages.firstIndex(where: { $0.id == itemId }) {
                messages[idx].content += delta
            }

        case "item/commandExecution/outputDelta":
            let itemId = params["itemId"] as? String ?? ""
            let delta = params["outputDelta"] as? String ?? ""
            if let idx = messages.firstIndex(where: { $0.id == itemId }) {
                messages[idx].commandOutput = (messages[idx].commandOutput ?? "") + delta
            }

        case "item/completed":
            let item = params["item"] as? [String: Any] ?? [:]
            let itemId = item["id"] as? String ?? ""
            let content = item["content"] as? String
            if let idx = messages.firstIndex(where: { $0.id == itemId }) {
                if let content { messages[idx].content = content }
                messages[idx].isStreaming = false
            }

        case "item/fileChange/outputDelta":
            let itemId = params["itemId"] as? String ?? ""
            let delta = params["delta"] as? String ?? ""
            if messages.lastIndex(where: { $0.fileChanges.contains(where: { $0.id == itemId }) }) != nil {
                _ = delta // handled via approval
            }

        default:
            break
        }
    }

    private func handleServerRequest(id: Int, method: String, params: [String: Any]) {
        switch method {
        case "item/fileChange/requestApproval":
            let itemId = params["itemId"] as? String ?? UUID().uuidString
            let path = params["path"] as? String ?? ""
            let diff = params["diff"] as? String ?? ""
            // Attach diff to last agent message or create new
            let diffEntry = FileChangeDiff(id: itemId, path: path, diff: diff)
            if let msgIdx = messages.lastIndex(where: { $0.role == .agent }) {
                messages[msgIdx].fileChanges.append(diffEntry)
            }
            pendingApproval = CodexApproval(requestId: id, type: .fileChange, path: path, diff: diff, command: nil, itemId: itemId)

        case "item/commandExecution/requestApproval":
            let itemId = params["itemId"] as? String ?? UUID().uuidString
            let command = params["command"] as? String ?? ""
            pendingApproval = CodexApproval(requestId: id, type: .command, path: nil, diff: nil, command: command, itemId: itemId)

        default:
            // Respond with error for unknown server requests
            Task { try? await client.respond(toRequestId: id, result: ["error": "unknown method"]) }
        }
    }

    // MARK: - Helpers

    private func appendSystem(_ text: String) {
        messages.append(CodexMessage(id: UUID().uuidString, role: .system, content: text))
    }
}
