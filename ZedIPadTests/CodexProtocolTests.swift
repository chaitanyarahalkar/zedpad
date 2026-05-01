import XCTest
@testable import ZedIPad

final class CodexProtocolTests: XCTestCase {

    func testAnyCodableRoundtrip() throws {
        let dict: [String: Any] = ["name": "ZedIPad", "version": 1, "flag": true]
        let encoded = try JSONSerialization.data(withJSONObject: dict)
        let decoded = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
        XCTAssertEqual(decoded["name"]?.value as? String, "ZedIPad")
        XCTAssertEqual(decoded["version"]?.value as? Int, 1)
        XCTAssertEqual(decoded["flag"]?.value as? Bool, true)
    }

    func testParseNotification() {
        let json = """
        {"method":"turn/started","params":{"turn":{"id":"turn_123"}}}
        """.data(using: .utf8)!
        let msg = CodexInboundMessage.parse(from: json)
        guard case .notification(let method, let params) = msg else {
            XCTFail("Expected notification"); return
        }
        XCTAssertEqual(method, "turn/started")
        let turn = params["turn"] as? [String: Any]
        XCTAssertEqual(turn?["id"] as? String, "turn_123")
    }

    func testParseResponse() {
        let json = """
        {"id":1,"result":{"thread":{"id":"thr_abc"}}}
        """.data(using: .utf8)!
        let msg = CodexInboundMessage.parse(from: json)
        guard case .response(let id, let result, let error) = msg else {
            XCTFail("Expected response"); return
        }
        XCTAssertEqual(id, 1)
        XCTAssertNil(error)
        let thread = result?["thread"] as? [String: Any]
        XCTAssertEqual(thread?["id"] as? String, "thr_abc")
    }

    func testParseServerRequest() {
        let json = """
        {"id":50,"method":"item/fileChange/requestApproval","params":{"itemId":"fc_1","path":"EditorView.swift","diff":"- old\\n+ new"}}
        """.data(using: .utf8)!
        let msg = CodexInboundMessage.parse(from: json)
        guard case .serverRequest(let id, let method, let params) = msg else {
            XCTFail("Expected serverRequest"); return
        }
        XCTAssertEqual(id, 50)
        XCTAssertEqual(method, "item/fileChange/requestApproval")
        XCTAssertEqual(params["path"] as? String, "EditorView.swift")
    }

    func testParseErrorResponse() {
        let json = """
        {"id":2,"error":{"code":-32600,"message":"Invalid request"}}
        """.data(using: .utf8)!
        let msg = CodexInboundMessage.parse(from: json)
        guard case .response(_, _, let error) = msg else {
            XCTFail("Expected response with error"); return
        }
        XCTAssertEqual(error?.code, -32600)
        XCTAssertEqual(error?.message, "Invalid request")
    }

    func testCodexServerConfigCodable() throws {
        let config = CodexServerConfig(name: "My Server", wsURL: "ws://localhost:4500", model: "codex-mini-latest")
        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(CodexServerConfig.self, from: data)
        XCTAssertEqual(decoded.name, "My Server")
        XCTAssertEqual(decoded.wsURL, "ws://localhost:4500")
        XCTAssertEqual(decoded.model, "codex-mini-latest")
    }

    func testCodexMessageDeltaStitching() {
        var msg = CodexMessage(id: "item_1", role: .agent, content: "", isStreaming: true)
        let deltas = ["Hello", ", ", "world", "!"]
        for delta in deltas { msg.content += delta }
        XCTAssertEqual(msg.content, "Hello, world!")
    }

    func testCodexApprovalTypes() {
        let fileApproval = CodexApproval(requestId: 50, type: .fileChange, path: "foo.swift", diff: "+ new", command: nil, itemId: "fc_1")
        XCTAssertEqual(fileApproval.type, .fileChange)
        XCTAssertEqual(fileApproval.path, "foo.swift")

        let cmdApproval = CodexApproval(requestId: 51, type: .command, path: nil, diff: nil, command: "swift test", itemId: "cmd_1")
        XCTAssertEqual(cmdApproval.type, .command)
        XCTAssertEqual(cmdApproval.command, "swift test")
    }

    func testFileChangeDiffDecision() {
        var diff = FileChangeDiff(id: "fc_1", path: "foo.swift", diff: "+ new line")
        XCTAssertEqual(diff.decision, .pending)
        diff.decision = .accepted
        XCTAssertEqual(diff.decision, .accepted)
    }

    @MainActor func testCodexServerStoreCRUD() {
        let store = CodexServerStore()
        let config = CodexServerConfig(name: "Test", wsURL: "ws://test:4500", model: "codex-mini-latest")
        store.add(config, token: "tok123")
        XCTAssertTrue(store.servers.contains(where: { $0.id == config.id }))
        let loaded = store.token(for: config)
        XCTAssertEqual(loaded, "tok123")
        store.remove(config)
        XCTAssertFalse(store.servers.contains(where: { $0.id == config.id }))
    }

    func testParseInvalidJSON() {
        let invalid = "not json".data(using: .utf8)!
        XCTAssertNil(CodexInboundMessage.parse(from: invalid))
    }
}

extension CodexApproval.ApprovalType: Equatable {
    public static func == (lhs: CodexApproval.ApprovalType, rhs: CodexApproval.ApprovalType) -> Bool {
        switch (lhs, rhs) {
        case (.fileChange, .fileChange): return true
        case (.command, .command): return true
        default: return false
        }
    }
}

extension DiffDecision: Equatable {
    public static func == (lhs: DiffDecision, rhs: DiffDecision) -> Bool {
        switch (lhs, rhs) {
        case (.pending, .pending), (.accepted, .accepted), (.declined, .declined): return true
        default: return false
        }
    }
}
