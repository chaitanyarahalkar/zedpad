import XCTest
@testable import ZedIPad

final class SQLTests: XCTestCase {

    func testHighlightSQL() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = """
        -- Create users table
        CREATE TABLE users (
            id SERIAL PRIMARY KEY,
            username VARCHAR(50) UNIQUE NOT NULL,
            email VARCHAR(255) UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            is_active BOOLEAN DEFAULT TRUE
        );

        -- Insert sample data
        INSERT INTO users (username, email, password_hash)
        VALUES
            ('alice', 'alice@example.com', 'hash1'),
            ('bob', 'bob@example.com', 'hash2');

        /* Complex query with joins */
        SELECT
            u.id,
            u.username,
            p.bio,
            COUNT(f.follower_id) AS follower_count
        FROM users u
        LEFT JOIN profiles p ON u.id = p.user_id
        LEFT JOIN follows f ON u.id = f.following_id
        WHERE u.is_active = TRUE
            AND u.created_at > '2024-01-01'
        GROUP BY u.id, u.username, p.bio
        HAVING COUNT(f.follower_id) > 10
        ORDER BY follower_count DESC
        LIMIT 20 OFFSET 0;
        """
        let tokens = hl.highlight(code, language: .sql)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testSQLLineCommentHighlighted() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "SELECT * FROM users -- get all users\nWHERE id = 1;"
        let tokens = hl.highlight(code, language: .sql)
        let commentTokens = tokens.filter { $0.color == ZedTheme.dark.syntaxComment }
        XCTAssertFalse(commentTokens.isEmpty)
    }

    func testLanguageDetectionSQL() {
        XCTAssertEqual(Language.detect(from: "sql"), .sql)
    }

    func testSQLKeywordsHighlighted() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "SELECT id, name FROM users WHERE active = TRUE"
        let tokens = hl.highlight(code, language: .sql)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testSQLNumbersHighlighted() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "SELECT * FROM orders WHERE total > 99.99 LIMIT 100"
        let tokens = hl.highlight(code, language: .sql)
        let numberTokens = tokens.filter { $0.color == ZedTheme.dark.syntaxNumber }
        XCTAssertFalse(numberTokens.isEmpty)
    }
}
