import XCTest
@testable import ZedIPad

final class GoKotlinTests: XCTestCase {

    func testHighlightGo() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = """
        package main

        import (
            "fmt"
            "os"
        )

        type Server struct {
            host string
            port int
        }

        func NewServer(host string, port int) *Server {
            return &Server{host: host, port: port}
        }

        func (s *Server) Start() error {
            fmt.Printf("Starting server on %s:%d\\n", s.host, s.port)
            return nil
        }

        func main() {
            srv := NewServer("localhost", 8080)
            if err := srv.Start(); err != nil {
                fmt.Fprintln(os.Stderr, err)
                os.Exit(1)
            }
        }
        """
        let tokens = hl.highlight(code, language: .go)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testHighlightKotlin() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = """
        package com.example

        import kotlinx.coroutines.*
        import kotlinx.coroutines.flow.*

        data class User(
            val id: Int,
            val name: String,
            val email: String
        )

        sealed class Result<out T> {
            data class Success<out T>(val data: T) : Result<T>()
            data class Error(val message: String) : Result<Nothing>()
        }

        suspend fun fetchUser(id: Int): Result<User> {
            return try {
                val user = User(id, "Alice", "alice@example.com")
                Result.Success(user)
            } catch (e: Exception) {
                Result.Error(e.message ?: "Unknown error")
            }
        }

        fun main() = runBlocking {
            val result = fetchUser(1)
            when (result) {
                is Result.Success -> println("User: ${result.data.name}")
                is Result.Error -> println("Error: ${result.message}")
            }
        }
        """
        let tokens = hl.highlight(code, language: .kotlin)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testLanguageDetectionGo() {
        XCTAssertEqual(Language.detect(from: "go"), .go)
    }

    func testLanguageDetectionKotlin() {
        XCTAssertEqual(Language.detect(from: "kt"), .kotlin)
        XCTAssertEqual(Language.detect(from: "kts"), .kotlin)
    }

    func testGoKeywordsHighlighted() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "func main() { var x int = 42; return }"
        let tokens = hl.highlight(code, language: .go)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testGoTypesHighlighted() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "var name string = \"hello\"\nvar count int = 100"
        let tokens = hl.highlight(code, language: .go)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testKotlinDataClassHighlighted() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "data class Point(val x: Int, val y: Int)"
        let tokens = hl.highlight(code, language: .kotlin)
        XCTAssertFalse(tokens.isEmpty)
    }
}
