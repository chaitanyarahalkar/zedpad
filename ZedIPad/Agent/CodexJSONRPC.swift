import Foundation

// MARK: - AnyCodable

struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) { self.value = value }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let v = try? container.decode(Bool.self) { value = v }
        else if let v = try? container.decode(Int.self) { value = v }
        else if let v = try? container.decode(Double.self) { value = v }
        else if let v = try? container.decode(String.self) { value = v }
        else if let v = try? container.decode([String: AnyCodable].self) { value = v.mapValues { $0.value } }
        else if let v = try? container.decode([AnyCodable].self) { value = v.map { $0.value } }
        else if container.decodeNil() { value = NSNull() }
        else { throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported type") }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let v as Bool:   try container.encode(v)
        case let v as Int:    try container.encode(v)
        case let v as Double: try container.encode(v)
        case let v as String: try container.encode(v)
        case let v as [String: Any]: try container.encode(v.mapValues { AnyCodable($0) })
        case let v as [Any]:  try container.encode(v.map { AnyCodable($0) })
        case is NSNull:       try container.encodeNil()
        default:              try container.encodeNil()
        }
    }
}

// MARK: - JSON-RPC Wire Types

struct CodexRPCRequest: Encodable {
    let method: String
    let id: Int?
    let params: AnyCodable?
}

struct CodexRPCResponse: Decodable {
    let id: Int?
    let result: AnyCodable?
    let error: CodexRPCError?
}

struct CodexRPCError: Codable {
    let code: Int
    let message: String
}

// MARK: - Parsed inbound message

enum CodexInboundMessage: @unchecked Sendable {
    case response(id: Int, result: [String: Any]?, error: CodexRPCError?)
    case notification(method: String, params: [String: Any])
    case serverRequest(id: Int, method: String, params: [String: Any])
}

extension CodexInboundMessage {
    static func parse(from data: Data) -> CodexInboundMessage? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        let method  = json["method"] as? String
        let id      = json["id"] as? Int
        let params  = json["params"] as? [String: Any] ?? [:]
        let result  = json["result"] as? [String: Any]

        if let id, let method {
            // Server-initiated request (approval)
            return .serverRequest(id: id, method: method, params: params)
        } else if let id {
            // Response to a client request
            var err: CodexRPCError? = nil
            if let e = json["error"] as? [String: Any],
               let code = e["code"] as? Int,
               let msg  = e["message"] as? String {
                err = CodexRPCError(code: code, message: msg)
            }
            return .response(id: id, result: result, error: err)
        } else if let method {
            return .notification(method: method, params: params)
        }
        return nil
    }
}
