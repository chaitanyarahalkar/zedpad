import XCTest
@testable import ZedIPad

@MainActor
final class SyntaxHighlightBatchTests: XCTestCase {

    private let hl = SyntaxHighlighter(theme: .dark)

    func testBatchHighlightAllLanguages() {
        let pairs: [(String, Language)] = [
            ("import Foundation", .swift),
            ("import os", .python),
            ("const x = 1;", .javascript),
            ("const x: number = 1;", .typescript),
            ("fn main() {}", .rust),
            ("func main() {}", .go),
            ("fun main() {}", .kotlin),
            ("def x = 1", .scala),
            ("puts 'hello'", .ruby),
            ("local x = 1", .lua),
            ("<?php $x = 1;", .php),
            ("x <- 1", .r),
            ("int x = 1;", .c),
            ("int x = 1;", .cpp),
            ("SELECT 1;", .sql),
            ("<div>hello</div>", .html),
            ("body { color: red; }", .css),
            ("key: value", .yaml),
            ("{ \"x\": 1 }", .json),
            ("#!/bin/bash", .bash),
            ("# Title", .markdown),
        ]
        for (code, lang) in pairs {
            let tokens = hl.highlight(code, language: lang)
            _ = tokens // no crash
        }
    }

    func testHighlightWithAllThemesBatch() {
        let code = "struct Foo { let bar: Int = 42 }"
        let testLangs: [Language] = [.swift, .python, .rust]
        for theme in ZedTheme.allCases {
            let h = SyntaxHighlighter(theme: theme)
            for lang in testLangs {
                _ = h.highlight(code, language: lang)
            }
        }
    }

    func testSearchInAllSampleFiles() {
        let state = FindState()
        state.query = "the"
        state.isCaseSensitive = false
        let root = FileNode.sampleRoot()
        var total = 0
        func search(_ node: FileNode) {
            if node.type == .file {
                let ranges = state.search(in: node.content)
                total += ranges.count
            }
            node.children?.forEach { search($0) }
        }
        search(root)
        _ = total
    }

    func testHighlightRealWorldKotlin() {
        let code = """
        sealed interface Result<out T> {
            data class Success<T>(val data: T) : Result<T>
            data class Failure(val error: Throwable) : Result<Nothing>
            object Loading : Result<Nothing>
        }
        fun <T> Result<T>.onSuccess(block: (T) -> Unit): Result<T> = also {
            if (this is Result.Success) block(data)
        }
        """
        let tokens = hl.highlight(code, language: .kotlin)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testHighlightRealWorldTypeScript() {
        let code = """
        type EventMap = Record<string, (...args: any[]) => void>;
        class EventEmitter<T extends EventMap> {
          private listeners = new Map<keyof T, Set<Function>>();
          on<K extends keyof T>(event: K, listener: T[K]): this {
            if (!this.listeners.has(event)) this.listeners.set(event, new Set());
            this.listeners.get(event)!.add(listener);
            return this;
          }
          emit<K extends keyof T>(event: K, ...args: Parameters<T[K]>): void {
            this.listeners.get(event)?.forEach(fn => fn(...args));
          }
        }
        """
        let tokens = hl.highlight(code, language: .typescript)
        XCTAssertFalse(tokens.isEmpty)
    }
}
