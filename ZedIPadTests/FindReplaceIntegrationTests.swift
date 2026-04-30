import XCTest
@testable import ZedIPad

@MainActor
final class FindReplaceIntegrationTests: XCTestCase {

    func testFindInRealSwiftCode() {
        let find = FindState()
        let code = """
        import Foundation
        import SwiftUI

        struct ContentView: View {
            @State private var text = "Hello, World!"

            var body: some View {
                VStack {
                    Text(text)
                    Button("Update") { text = "Updated!" }
                }
            }
        }
        """
        find.query = "import"
        let ranges = find.search(in: code)
        XCTAssertEqual(ranges.count, 2)

        find.query = "var"
        let varRanges = find.search(in: code)
        XCTAssertGreaterThan(varRanges.count, 0)
    }

    func testReplaceAllInRealCode() {
        let find = FindState()
        var code = """
        let username = "alice"
        let userAge = 25
        print(username, userAge)
        """
        find.query = "user"
        find.replaceQuery = "player"
        let _ = find.search(in: code)
        let count = find.replaceAll(in: &code)
        XCTAssertEqual(count, 3) // username, userAge, username again... no, username and userAge have "user" once each, + userAge twice? Let me recount
        // "username" has "user" at offset 0, "userAge" has "user" at offset 0, "username" again has "user"
        // Actually: "username" (1) + "userAge" (1) + "username" (1) = 3
        XCTAssertFalse(code.contains("username"))
        XCTAssertTrue(code.contains("playername"))
    }

    func testRegexReplaceInCode() {
        let find = FindState()
        find.isRegex = true
        find.query = "let [a-z]+ ="
        find.replaceQuery = "var x ="
        var code = "let count = 0\nlet name = \"alice\"\nlet value = 42"
        let _ = find.search(in: code)
        let count = find.replaceAll(in: &code)
        XCTAssertEqual(count, 3)
    }

    func testFindWithMultilineQuery() {
        let find = FindState()
        find.query = "Hello"
        let text = "Hello World\nHello Swift\nHello iPad"
        let ranges = find.search(in: text)
        XCTAssertEqual(ranges.count, 3)
    }

    func testReplaceDoesNotBreakSurroundingCode() {
        let find = FindState()
        find.query = "foo"
        find.replaceQuery = "bar"
        var code = "prefix_foo_suffix"
        let _ = find.replaceAll(in: &code)
        XCTAssertEqual(code, "prefix_bar_suffix")
    }
}
