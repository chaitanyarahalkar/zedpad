import Foundation

actor CodexWSClient {
    private var task: URLSessionWebSocketTask?
    private var nextId = 0
    private var pending: [Int: CheckedContinuation<[String: Any]?, Error>] = [:]
    private var notificationContinuation: AsyncStream<CodexInboundMessage>.Continuation?

    private(set) var notifications: AsyncStream<CodexInboundMessage>

    init() {
        var cont: AsyncStream<CodexInboundMessage>.Continuation!
        notifications = AsyncStream { cont = $0 }
        notificationContinuation = cont
    }

    // MARK: - Connect

    func connect(url: URL, token: String) throws {
        var req = URLRequest(url: url)
        req.timeoutInterval = 10
        // Only send auth header when a token is provided
        if !token.isEmpty {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        task = session.webSocketTask(with: req)
        task?.resume()
        startReceiveLoop()
    }

    func disconnect() {
        task?.cancel(with: .normalClosure, reason: nil)
        task = nil
        notificationContinuation?.finish()
    }

    // MARK: - Send

    func send(method: String, id: Int? = nil, params: [String: Any]? = nil) async throws {
        var body: [String: Any] = ["method": method]
        if let id { body["id"] = id }
        if let params { body["params"] = params }
        let data = try JSONSerialization.data(withJSONObject: body)
        let str = String(data: data, encoding: .utf8)!
        try await task?.send(.string(str))
    }

    // MARK: - Request (send + await response)

    func request(method: String, params: [String: Any]? = nil) async throws -> [String: Any]? {
        let id = nextId; nextId += 1
        try await send(method: method, id: id, params: params)
        return try await withCheckedThrowingContinuation { cont in
            pending[id] = cont
        }
    }

    // MARK: - Respond to server request (approval)

    func respond(toRequestId id: Int, result: [String: Any]) async throws {
        let body: [String: Any] = ["id": id, "result": result]
        let data = try JSONSerialization.data(withJSONObject: body)
        try await task?.send(.string(String(data: data, encoding: .utf8)!))
    }

    // MARK: - Initialize handshake

    func initialize() async throws {
        _ = try await request(method: "initialize", params: [
            "clientInfo": ["name": "ZedIPad", "version": "1.0.0"],
            "capabilities": ["experimentalApi": true]
        ])
        try await send(method: "initialized")
    }

    // MARK: - Thread + Turn

    func startThread(model: String) async throws -> String {
        let result = try await request(method: "thread/start", params: ["model": model])
        guard let thread = result?["thread"] as? [String: Any],
              let threadId = thread["id"] as? String else {
            throw CodexError.unexpectedResponse("thread/start")
        }
        return threadId
    }

    func startTurn(threadId: String, input: String, model: String) async throws -> String {
        let params: [String: Any] = [
            "threadId": threadId,
            "input": [["type": "text", "text": input]],
            "model": model
        ]
        let result = try await request(method: "turn/start", params: params)
        return (result?["turn"] as? [String: Any])?["id"] as? String ?? ""
    }

    func interruptTurn(turnId: String) async throws {
        try await send(method: "turn/interrupt", params: ["turnId": turnId])
    }

    // MARK: - Receive loop

    private func startReceiveLoop() {
        Task { [weak self] in
            guard let self else { return }
            while true {
                guard let task = await self.task else { break }
                do {
                    let msg = try await task.receive()
                    await self.handle(message: msg)
                } catch {
                    await self.notificationContinuation?.finish()
                    break
                }
            }
        }
    }

    private func handle(message: URLSessionWebSocketTask.Message) {
        let data: Data
        switch message {
        case .string(let s): data = Data(s.utf8)
        case .data(let d):   data = d
        @unknown default:    return
        }

        guard let parsed = CodexInboundMessage.parse(from: data) else { return }

        switch parsed {
        case .response(let id, let result, let error):
            if let cont = pending.removeValue(forKey: id) {
                if let error {
                    cont.resume(throwing: CodexError.rpc(error))
                } else {
                    cont.resume(returning: result)
                }
            }
        case .notification, .serverRequest:
            notificationContinuation?.yield(parsed)
        }
    }
}

enum CodexError: Error, LocalizedError {
    case unexpectedResponse(String)
    case rpc(CodexRPCError)
    case connectionFailed(String)

    var errorDescription: String? {
        switch self {
        case .unexpectedResponse(let m): return "Unexpected response to \(m)"
        case .rpc(let e): return "RPC error \(e.code): \(e.message)"
        case .connectionFailed(let r): return "Connection failed: \(r)"
        }
    }
}
