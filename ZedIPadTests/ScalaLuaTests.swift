import XCTest
@testable import ZedIPad

final class ScalaLuaTests: XCTestCase {

    func testHighlightScala() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = """
        package com.example

        import scala.concurrent.Future
        import scala.concurrent.ExecutionContext.Implicits.global

        sealed trait Shape
        case class Circle(radius: Double) extends Shape
        case class Rectangle(w: Double, h: Double) extends Shape
        case object Point extends Shape

        object Geometry {
          def area(shape: Shape): Double = shape match {
            case Circle(r) => math.Pi * r * r
            case Rectangle(w, h) => w * h
            case Point => 0.0
          }

          def perimeter(shape: Shape): Double = shape match {
            case Circle(r) => 2 * math.Pi * r
            case Rectangle(w, h) => 2 * (w + h)
            case Point => 0.0
          }
        }

        val shapes = List(Circle(5.0), Rectangle(3.0, 4.0), Point)
        val areas = shapes.map(Geometry.area)
        println(areas)
        """
        let tokens = hl.highlight(code, language: .scala)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testHighlightLua() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = """
        -- Lua module example
        local M = {}

        local function factorial(n)
            if n <= 1 then return 1 end
            return n * factorial(n - 1)
        end

        function M.fibonacci(n)
            if n <= 0 then return 0
            elseif n == 1 then return 1
            else return M.fibonacci(n-1) + M.fibonacci(n-2)
            end
        end

        function M.range(from, to, step)
            step = step or 1
            local result = {}
            for i = from, to, step do
                table.insert(result, i)
            end
            return result
        end

        -- Test
        for i = 1, 10 do
            io.write(factorial(i) .. " ")
        end
        print()

        return M
        """
        let tokens = hl.highlight(code, language: .lua)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testLanguageDetectionScala() {
        XCTAssertEqual(Language.detect(from: "scala"), .scala)
        XCTAssertEqual(Language.detect(from: "sc"), .scala)
    }

    func testLanguageDetectionLua() {
        XCTAssertEqual(Language.detect(from: "lua"), .lua)
    }

    func testScalaKeywordsHighlighted() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "def greet(name: String): Unit = println(s\"Hello, $name\")"
        let tokens = hl.highlight(code, language: .scala)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testLuaTableHighlighted() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "local t = {key = \"value\", count = 42}\nfor k, v in pairs(t) do print(k, v) end"
        let tokens = hl.highlight(code, language: .lua)
        XCTAssertFalse(tokens.isEmpty)
    }
}
