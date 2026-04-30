import SwiftUI

@main
struct ZedIPadApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var onboardingState = OnboardingState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(onboardingState)
                .preferredColorScheme(appState.theme.colorScheme)
                .fullScreenCover(isPresented: Binding(
                    get: { !onboardingState.hasCompletedOnboarding },
                    set: { _ in }
                )) {
                    OnboardingView(state: onboardingState)
                }
        }
    }
}
