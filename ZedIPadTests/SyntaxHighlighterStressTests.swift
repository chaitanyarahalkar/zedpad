import XCTest
@testable import ZedIPad

final class SyntaxHighlighterStressTests: XCTestCase {

    func testHighlightManyKeywordsSwift() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = """
        import Foundation
        import SwiftUI
        import Combine

        public protocol Composable: Identifiable, Equatable, Hashable {
            associatedtype ID: Hashable
            var id: ID { get }
        }

        @MainActor
        open class BaseViewModel: ObservableObject {
            @Published public var isLoading: Bool = false
            @Published public var error: Error? = nil
            @Published private var _data: [Any] = []

            public required init() {}

            public func load() async throws {
                guard !isLoading else { return }
                isLoading = true
                defer { isLoading = false }
                try await performLoad()
            }

            open func performLoad() async throws {
                fatalError("Subclasses must override performLoad()")
            }
        }

        @propertyWrapper
        struct UserDefault<Value> {
            let key: String
            let defaultValue: Value
            private let storage: UserDefaults

            init(_ key: String, defaultValue: Value, storage: UserDefaults = .standard) {
                self.key = key
                self.defaultValue = defaultValue
                self.storage = storage
            }

            var wrappedValue: Value {
                get { storage.object(forKey: key) as? Value ?? defaultValue }
                set { storage.set(newValue, forKey: key) }
            }
        }
        """
        let tokens = hl.highlight(code, language: .swift)
        XCTAssertGreaterThan(tokens.count, 20, "Should produce many tokens")
    }

    func testHighlightLargeJSON() {
        let hl = SyntaxHighlighter(theme: .dark)
        var obj = "{ "
        for i in 0..<50 {
            obj += "\"key\(i)\": \(i), "
        }
        obj += "\"last\": null }"
        let tokens = hl.highlight(obj, language: .json)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testHighlightComplexSQL() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = """
        SELECT u.id, u.name, COUNT(o.id) as orders,
               SUM(o.total) as revenue
        FROM users u
        LEFT JOIN orders o ON u.id = o.user_id
        WHERE u.created_at > '2024-01-01'
          AND u.status = 'active'
          AND o.status IN ('completed', 'shipped')
        GROUP BY u.id, u.name
        HAVING COUNT(o.id) > 5
        ORDER BY revenue DESC
        LIMIT 100;
        """
        let tokens = hl.highlight(code, language: .sql)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testAllThemesWithComplexCode() {
        let code = """
        async function fetchData(url: string): Promise<Response> {
            try {
                const response = await fetch(url, { method: 'GET', headers: { 'Content-Type': 'application/json' } });
                if (!response.ok) throw new Error(`HTTP error: ${response.status}`);
                return response;
            } catch (error) {
                console.error('Fetch failed:', error);
                throw error;
            }
        }
        """
        for theme in ZedTheme.allCases {
            let hl = SyntaxHighlighter(theme: theme)
            let tokens = hl.highlight(code, language: .typescript)
            XCTAssertFalse(tokens.isEmpty, "Theme \(theme.rawValue) produced no tokens")
        }
    }
}
