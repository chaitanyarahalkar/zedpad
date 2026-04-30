import XCTest
@testable import ZedIPad

final class CodeSnippetTests: XCTestCase {

    private let hl = SyntaxHighlighter(theme: .dark)

    func testFibonacciSwift() {
        let code = """
        func fibonacci(_ n: Int) -> Int {
            guard n > 1 else { return n }
            return fibonacci(n - 1) + fibonacci(n - 2)
        }
        let result = fibonacci(10)
        """
        let tokens = hl.highlight(code, language: .swift)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testQuickSortPython() {
        let code = """
        def quicksort(arr):
            if len(arr) <= 1:
                return arr
            pivot = arr[len(arr) // 2]
            left = [x for x in arr if x < pivot]
            middle = [x for x in arr if x == pivot]
            right = [x for x in arr if x > pivot]
            return quicksort(left) + middle + quicksort(right)
        """
        let tokens = hl.highlight(code, language: .python)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testBinarySearchRust() {
        let code = """
        fn binary_search<T: Ord>(arr: &[T], target: &T) -> Option<usize> {
            let mut low = 0;
            let mut high = arr.len();
            while low < high {
                let mid = low + (high - low) / 2;
                match arr[mid].cmp(target) {
                    std::cmp::Ordering::Equal => return Some(mid),
                    std::cmp::Ordering::Less => low = mid + 1,
                    std::cmp::Ordering::Greater => high = mid,
                }
            }
            None
        }
        """
        let tokens = hl.highlight(code, language: .rust)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testBubbleSortGo() {
        let code = """
        func bubbleSort(arr []int) []int {
            n := len(arr)
            for i := 0; i < n-1; i++ {
                for j := 0; j < n-i-1; j++ {
                    if arr[j] > arr[j+1] {
                        arr[j], arr[j+1] = arr[j+1], arr[j]
                    }
                }
            }
            return arr
        }
        """
        let tokens = hl.highlight(code, language: .go)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testLinkedListKotlin() {
        let code = """
        data class Node<T>(val value: T, var next: Node<T>? = null)
        class LinkedList<T> {
            private var head: Node<T>? = null
            fun push(value: T) { head = Node(value, head) }
            fun pop(): T? { val v = head?.value; head = head?.next; return v }
            fun isEmpty() = head == null
        }
        """
        let tokens = hl.highlight(code, language: .kotlin)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testFactorialScala() {
        let code = """
        def factorial(n: BigInt): BigInt = n match {
          case _ if n <= 0 => 1
          case _ => n * factorial(n - 1)
        }
        println(factorial(20))
        """
        let tokens = hl.highlight(code, language: .scala)
        XCTAssertFalse(tokens.isEmpty)
    }
}
