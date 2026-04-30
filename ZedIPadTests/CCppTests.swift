import XCTest
@testable import ZedIPad

final class CCppTests: XCTestCase {

    func testHighlightC() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = """
        #include <stdio.h>
        #include <stdlib.h>

        typedef struct Node {
            int value;
            struct Node *next;
        } Node;

        Node *create_node(int val) {
            Node *n = (Node *)malloc(sizeof(Node));
            if (n == NULL) return NULL;
            n->value = val;
            n->next = NULL;
            return n;
        }

        void push(Node **head, int val) {
            Node *n = create_node(val);
            if (n == NULL) return;
            n->next = *head;
            *head = n;
        }

        int main() {
            Node *list = NULL;
            for (int i = 0; i < 10; i++) {
                push(&list, i * 2);
            }
            printf("Done\\n");
            return 0;
        }
        """
        let tokens = hl.highlight(code, language: .c)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testHighlightCpp() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = """
        #include <iostream>
        #include <vector>
        #include <algorithm>
        #include <memory>

        template<typename T>
        class Stack {
        private:
            std::vector<T> data;
        public:
            void push(const T& val) { data.push_back(val); }
            void pop() { if (!data.empty()) data.pop_back(); }
            T& top() { return data.back(); }
            bool empty() const { return data.empty(); }
            size_t size() const { return data.size(); }
        };

        int main() {
            auto stack = std::make_unique<Stack<int>>();
            for (int i = 0; i < 5; ++i) stack->push(i);
            while (!stack->empty()) {
                std::cout << stack->top() << "\\n";
                stack->pop();
            }
            return 0;
        }
        """
        let tokens = hl.highlight(code, language: .cpp)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testLanguageDetectionC() {
        XCTAssertEqual(Language.detect(from: "c"), .c)
        XCTAssertEqual(Language.detect(from: "h"), .c)
    }

    func testLanguageDetectionCpp() {
        XCTAssertEqual(Language.detect(from: "cpp"), .cpp)
        XCTAssertEqual(Language.detect(from: "cc"), .cpp)
        XCTAssertEqual(Language.detect(from: "cxx"), .cpp)
        XCTAssertEqual(Language.detect(from: "hpp"), .cpp)
        XCTAssertEqual(Language.detect(from: "hxx"), .cpp)
    }

    func testCKeywordsHighlighted() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "int main(void) { return 0; }"
        let tokens = hl.highlight(code, language: .c)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testCppTemplateHighlighted() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "template<typename T> T max(T a, T b) { return a > b ? a : b; }"
        let tokens = hl.highlight(code, language: .cpp)
        XCTAssertFalse(tokens.isEmpty)
    }
}
