import SwiftUI

struct OnboardingView: View {
    @ObservedObject var state: OnboardingState

    var body: some View {
        ZStack {
            Color(hex: "#1e2124").ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") { state.skip() }
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#6e738d"))
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                }

                // Page content
                TabView(selection: $state.currentStep) {
                    ForEach(OnboardingStep.allCases, id: \.rawValue) { step in
                        OnboardingStepContent(step: step)
                            .tag(step.rawValue)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: state.currentStep)

                // Progress dots + Next button
                VStack(spacing: 20) {
                    HStack(spacing: 8) {
                        ForEach(0..<state.totalSteps, id: \.self) { i in
                            Circle()
                                .fill(i == state.currentStep ? Color(hex: "#89b4fa") : Color(hex: "#45475a"))
                                .frame(width: i == state.currentStep ? 8 : 6, height: i == state.currentStep ? 8 : 6)
                                .animation(.spring(response: 0.3), value: state.currentStep)
                        }
                    }

                    Button {
                        withAnimation { state.next() }
                    } label: {
                        Text(state.currentStep == state.totalSteps - 1 ? "Start Coding →" : "Next →")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: "#89b4fa"))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                }
                .padding(.bottom, 40)
            }
        }
    }
}

struct OnboardingStepContent: View {
    let step: OnboardingStep

    var body: some View {
        switch step {
        case .welcome:   OnboardingWelcomeStep()
        case .editor:    OnboardingEditorStep()
        case .terminal:  OnboardingTerminalStep()
        case .files:     OnboardingFilesStep()
        case .ready:     OnboardingReadyStep()
        }
    }
}
