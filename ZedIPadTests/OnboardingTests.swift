import XCTest
@testable import ZedIPad

@MainActor
final class OnboardingTests: XCTestCase {
    func testInitialStepIsWelcome() {
        let state = OnboardingState()
        state.reset()
        XCTAssertEqual(state.currentStep, 0)
        XCTAssertEqual(state.currentStepEnum, .welcome)
        XCTAssertFalse(state.hasCompletedOnboarding)
    }

    func testNextAdvancesStep() {
        let state = OnboardingState()
        state.reset()
        state.next()
        XCTAssertEqual(state.currentStep, 1)
        XCTAssertEqual(state.currentStepEnum, .editor)
    }

    func testNextOnLastStepCompletes() {
        let state = OnboardingState()
        state.reset()
        state.currentStep = state.totalSteps - 1
        state.next()
        XCTAssertTrue(state.hasCompletedOnboarding)
    }

    func testSkipCompletes() {
        let state = OnboardingState()
        state.reset()
        state.skip()
        XCTAssertTrue(state.hasCompletedOnboarding)
    }

    func testResetClearsCompletion() {
        let state = OnboardingState()
        state.complete()
        XCTAssertTrue(state.hasCompletedOnboarding)
        state.reset()
        XCTAssertFalse(state.hasCompletedOnboarding)
        XCTAssertEqual(state.currentStep, 0)
    }

    func testTotalSteps() {
        let state = OnboardingState()
        XCTAssertEqual(state.totalSteps, OnboardingStep.allCases.count)
        XCTAssertEqual(state.totalSteps, 5)
    }

    func testAllStepsHaveTitles() {
        for step in OnboardingStep.allCases {
            XCTAssertFalse(step.title.isEmpty, "Step \(step) has empty title")
        }
    }

    func testStepEnumMappingIsCorrect() {
        XCTAssertEqual(OnboardingStep(rawValue: 0), .welcome)
        XCTAssertEqual(OnboardingStep(rawValue: 1), .editor)
        XCTAssertEqual(OnboardingStep(rawValue: 2), .terminal)
        XCTAssertEqual(OnboardingStep(rawValue: 3), .files)
        XCTAssertEqual(OnboardingStep(rawValue: 4), .ready)
    }

    func testCurrentStepEnumReturnsWelcomeForInvalidIndex() {
        let state = OnboardingState()
        state.currentStep = 99
        XCTAssertEqual(state.currentStepEnum, .welcome)
    }

    func testCompleteMethodSetsFlag() {
        let state = OnboardingState()
        state.reset()
        XCTAssertFalse(state.hasCompletedOnboarding)
        state.complete()
        XCTAssertTrue(state.hasCompletedOnboarding)
    }
}

@MainActor
final class TerminalBugTests: XCTestCase {
    func testShellInterpreterHasAllExpectedCommands() {
        let shell = ShellInterpreter()
        let helpOutput = shell.execute("help")
        XCTAssertTrue(helpOutput.contains("ls"))
        XCTAssertTrue(helpOutput.contains("cd"))
        XCTAssertTrue(helpOutput.contains("pwd"))
        XCTAssertTrue(helpOutput.contains("cat"))
        XCTAssertTrue(helpOutput.contains("mkdir"))
        XCTAssertTrue(helpOutput.contains("grep"))
    }

    func testShellPromptDoesNotContainBrokenANSI() {
        let shell = ShellInterpreter()
        let prompt = shell.prompt()
        // Prompt should start with ESC[ not with literal [
        XCTAssertTrue(prompt.hasPrefix("\u{1B}["), "Prompt should start with ESC[ not literal bracket")
        XCTAssertFalse(prompt.hasPrefix("["), "Prompt must not leak raw ANSI codes")
    }

    func testShellExecuteReturnsNonEmptyForHelp() {
        let shell = ShellInterpreter()
        let result = shell.execute("help")
        XCTAssertFalse(result.isEmpty)
    }

    func testShellExecuteEmptyCommandReturnsEmpty() {
        let shell = ShellInterpreter()
        let result = shell.execute("")
        XCTAssertTrue(result.isEmpty)
    }

    func testShellHistoryTracksCommands() {
        let shell = ShellInterpreter()
        let _ = shell.execute("help")
        let _ = shell.execute("pwd")
        let historyOutput = shell.execute("history")
        XCTAssertTrue(historyOutput.contains("help"))
        XCTAssertTrue(historyOutput.contains("pwd"))
    }

    func testTerminalSessionShowsCorrectName() {
        let session = TerminalSession(name: "Terminal 1", isSSH: false, shell: ShellInterpreter())
        XCTAssertEqual(session.name, "Terminal 1")
        XCTAssertFalse(session.isSSH)
    }

    func testTerminalSessionSSHFlag() {
        let session = TerminalSession(name: "SSH: myserver", isSSH: true)
        XCTAssertTrue(session.isSSH)
    }

    func testANSIHelperFunctions() {
        let green = ANSI.green("test")
        XCTAssertTrue(green.hasPrefix("\u{1B}["))
        XCTAssertTrue(green.contains("test"))
        XCTAssertTrue(green.hasSuffix(ANSI.reset))
    }
}
