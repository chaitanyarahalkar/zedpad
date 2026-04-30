import XCTest
@testable import ZedIPad

final class LanguageExtensionMapTests: XCTestCase {

    func testAllKnownExtensions() {
        let map: [(String, Language)] = [
            ("swift", .swift), ("js", .javascript), ("ts", .typescript),
            ("tsx", .typescript), ("jsx", .typescript),
            ("py", .python), ("rs", .rust), ("md", .markdown),
            ("json", .json), ("yaml", .yaml), ("yml", .yaml),
            ("sh", .bash), ("bash", .bash), ("rb", .ruby),
            ("html", .html), ("htm", .html), ("css", .css),
            ("go", .go), ("kt", .kotlin), ("kts", .kotlin),
            ("c", .c), ("h", .c), ("cpp", .cpp), ("cc", .cpp),
            ("cxx", .cpp), ("hpp", .cpp), ("hxx", .cpp),
            ("sql", .sql), ("scala", .scala), ("sc", .scala),
            ("lua", .lua), ("php", .php), ("phtml", .php),
            ("r", .r), ("rmd", .r),
        ]
        for (ext, expectedLang) in map {
            let detected = Language.detect(from: ext)
            XCTAssertEqual(detected, expectedLang, ".\(ext) should detect as \(expectedLang)")
        }
    }

    func testAllUnknownExtensions() {
        let unknown = ["exe", "dll", "bin", "pdf", "jpg", "png", "gif", "mp4",
                       "zip", "tar", "gz", "7z", "dmg", "pkg", "deb", "rpm",
                       "doc", "docx", "xls", "xlsx", "ppt", "pptx"]
        for ext in unknown {
            XCTAssertEqual(Language.detect(from: ext), .unknown, ".\(ext) should be unknown")
        }
    }

    func testEmptyExtension() {
        XCTAssertEqual(Language.detect(from: ""), .unknown)
    }

    func testSingleLetterExtensions() {
        XCTAssertEqual(Language.detect(from: "c"), .c)
        XCTAssertEqual(Language.detect(from: "h"), .c)
        XCTAssertEqual(Language.detect(from: "r"), .r)
        XCTAssertEqual(Language.detect(from: "a"), .unknown) // unknown
    }

    func testUppercaseExtensions() {
        // Extensions should be lowercased before detection
        XCTAssertEqual(Language.detect(from: "swift"), .swift)
        XCTAssertEqual(Language.detect(from: "SWIFT"), .unknown) // not lowercased → unknown
        XCTAssertEqual(Language.detect(from: "Swift"), .unknown)
    }

    func testLanguageRawValues() {
        XCTAssertEqual(Language.swift.rawValue, "swift")
        XCTAssertEqual(Language.python.rawValue, "python")
        XCTAssertEqual(Language.unknown.rawValue, "unknown")
    }
}
