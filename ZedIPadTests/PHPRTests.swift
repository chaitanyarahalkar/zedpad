import XCTest
@testable import ZedIPad

final class PHPRTests: XCTestCase {

    func testHighlightPHP() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = """
        <?php
        namespace App\\Controllers;

        use App\\Models\\User;
        use App\\Services\\AuthService;

        class UserController
        {
            private AuthService $authService;

            public function __construct(AuthService $authService)
            {
                $this->authService = $authService;
            }

            public function index(): array
            {
                $users = User::where('active', true)
                    ->orderBy('created_at', 'desc')
                    ->limit(20)
                    ->get();
                return ['data' => $users, 'total' => count($users)];
            }

            public function show(int $id): ?User
            {
                $user = User::find($id);
                if ($user === null) {
                    throw new \\RuntimeException("User $id not found");
                }
                return $user;
            }
        }
        """
        let tokens = hl.highlight(code, language: .php)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testHighlightR() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = """
        # Data analysis script
        library(ggplot2)
        library(dplyr)
        library(tidyr)

        # Load data
        df <- read.csv("data.csv", stringsAsFactors = FALSE)

        # Summary statistics
        summary_stats <- df %>%
            group_by(category) %>%
            summarise(
                mean_value = mean(value, na.rm = TRUE),
                sd_value = sd(value, na.rm = TRUE),
                count = n()
            ) %>%
            arrange(desc(mean_value))

        # Visualization
        p <- ggplot(df, aes(x = category, y = value, fill = category)) +
            geom_boxplot(alpha = 0.7) +
            geom_jitter(width = 0.2, alpha = 0.5) +
            theme_minimal() +
            labs(title = "Distribution by Category",
                 x = "Category", y = "Value")

        print(p)
        ggsave("output.png", p, width = 10, height = 6)
        """
        let tokens = hl.highlight(code, language: .r)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testLanguageDetectionPHP() {
        XCTAssertEqual(Language.detect(from: "php"), .php)
        XCTAssertEqual(Language.detect(from: "phtml"), .php)
    }

    func testLanguageDetectionR() {
        XCTAssertEqual(Language.detect(from: "r"), .r)
        XCTAssertEqual(Language.detect(from: "rmd"), .r)
    }

    func testPHPVariablesHighlighted() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "<?php\n$name = \"Alice\";\n$age = 30;\necho \"$name is $age years old\";"
        let tokens = hl.highlight(code, language: .php)
        let varTokens = tokens.filter { $0.color == ZedTheme.dark.syntaxType }
        XCTAssertFalse(varTokens.isEmpty, "PHP variables should be highlighted")
    }

    func testRAssignmentHighlighted() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "x <- 42\ny = 3.14\nz <<- TRUE"
        let tokens = hl.highlight(code, language: .r)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testAllNewLanguagesHighlight() {
        let hl = SyntaxHighlighter(theme: .dark)
        let simple = "hello world 123"
        let langs: [Language] = [.php, .r, .scala, .lua]
        for lang in langs {
            let tokens = hl.highlight(simple, language: lang)
            _ = tokens // must not crash
        }
    }
}
