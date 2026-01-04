import SwiftUI

@main
struct BreadAIApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                LoginView()
            } else {
                OnboardingView()
            }
        }
    }
}
