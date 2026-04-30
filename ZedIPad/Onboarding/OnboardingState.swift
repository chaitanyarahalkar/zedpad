import SwiftUI

enum OnboardingStep: Int, CaseIterable {
    case welcome, editor, terminal, files, ready

    var title: String {
        switch self {
        case .welcome: return "Welcome to ZedIPad"
        case .editor: return "Powerful Code Editor"
        case .terminal: return "Built-in Terminal"
        case .files: return "Files & Git"
        case .ready: return "You're All Set!"
        }
    }
}

@MainActor
class OnboardingState: ObservableObject {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @Published var currentStep: Int = 0

    var totalSteps: Int { OnboardingStep.allCases.count }

    var currentStepEnum: OnboardingStep {
        OnboardingStep(rawValue: currentStep) ?? .welcome
    }

    func next() {
        if currentStep < totalSteps - 1 {
            currentStep += 1
        } else {
            complete()
        }
    }

    func skip() { complete() }

    func complete() {
        hasCompletedOnboarding = true
    }

    func reset() {
        hasCompletedOnboarding = false
        currentStep = 0
    }
}
