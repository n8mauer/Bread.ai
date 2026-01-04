import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            Color.breadBeige.ignoresSafeArea()

            TabView(selection: $currentPage) {
                // Screen 1: Welcome
                OnboardingPageView(
                    systemImage: "hands.sparkles.fill",
                    title: "Welcome to BreadAI",
                    subtitle: "Your AI-Powered Baking Companion",
                    description: "Learn the art of bread baking with personalized recipes, expert techniques, and smart guidance.",
                    showLogo: true
                )
                .tag(0)

                // Screen 2: AI-Powered Recipes
                OnboardingPageView(
                    systemImage: "brain.head.profile",
                    title: "AI-Powered Recipes",
                    subtitle: "Customized Just for You",
                    description: "Get detailed recipes tailored to your preferences, with step-by-step instructions and helpful tips from our AI baker.",
                    showLogo: false
                )
                .tag(1)

                // Screen 3: Badges & Gamification
                OnboardingPageView(
                    systemImage: "rosette",
                    title: "Earn Badges",
                    subtitle: "Level Up Your Baking Skills",
                    description: "Track your progress, unlock achievements, and become a master baker as you complete challenges and bake delicious bread.",
                    showLogo: false
                )
                .tag(2)

                // Screen 4: Let's Start
                OnboardingFinalPage(onGetStarted: {
                    hasSeenOnboarding = true
                })
                .tag(3)
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }
}

struct OnboardingPageView: View {
    let systemImage: String
    let title: String
    let subtitle: String
    let description: String
    let showLogo: Bool

    var body: some View {
        VStack(spacing: 25) {
            Spacer()

            if showLogo {
                Image("bread.ai logo no background")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150)
                    .padding(.bottom, 20)
            }

            Image(systemName: systemImage)
                .font(.system(size: 80))
                .foregroundColor(.breadBrown)
                .padding(.bottom, 10)

            Text(title)
                .font(.title.bold())
                .foregroundColor(.breadBrown)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.title3)
                .foregroundColor(.breadBrown.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text(description)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 10)

            Spacer()
            Spacer()
        }
    }
}

struct OnboardingFinalPage: View {
    let onGetStarted: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Image("bread.ai logo no background")
                .resizable()
                .scaledToFit()
                .frame(width: 180)

            Text("Ready to Bake?")
                .font(.largeTitle.bold())
                .foregroundColor(.breadBrown)
                .multilineTextAlignment(.center)

            Text("Let's start your baking journey!")
                .font(.title3)
                .foregroundColor(.breadBrown.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: onGetStarted) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: 280)
                    .padding()
                    .background(Color.breadBrown)
                    .cornerRadius(15)
            }
            .padding(.top, 20)

            Spacer()
            Spacer()
        }
        .padding()
    }
}

#Preview {
    OnboardingView()
}
