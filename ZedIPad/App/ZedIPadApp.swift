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
        .commands {
            CommandMenu("Editor") {
                Button("Command Palette") {
                    NotificationCenter.default.post(name: .showCommandPalette, object: nil)
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])

                Divider()

                Button("Toggle Terminal") {
                    NotificationCenter.default.post(name: .toggleTerminal, object: nil)
                }
                .keyboardShortcut("`", modifiers: .command)

                Button("Toggle Theme") {
                    NotificationCenter.default.post(name: .toggleTheme, object: nil)
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])

                Divider()

                Button("Find in File") {
                    NotificationCenter.default.post(name: .showFindBar, object: nil)
                }
                .keyboardShortcut("f", modifiers: .command)
            }
        }
    }
}

extension Notification.Name {
    static let showCommandPalette = Notification.Name("showCommandPalette")
    static let toggleTerminal     = Notification.Name("toggleTerminal")
    static let toggleTheme        = Notification.Name("toggleTheme")
    static let showFindBar        = Notification.Name("showFindBar")
}
