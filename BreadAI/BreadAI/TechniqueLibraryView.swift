import SwiftUI

struct TechniqueLibraryView: View {
    @State private var searchText = ""
    @State private var selectedTechnique: BakingTechnique?

    private var filteredTechniques: [BakingTechnique] {
        TechniqueData.searchTechniques(query: searchText)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.breadBeige.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    Text("Technique Library")
                        .font(.largeTitle.bold())
                        .foregroundColor(.breadBrown)
                        .padding(.top, 15)

                    Image("bread.ai logo no background")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100)
                        .padding(.vertical, 10)

                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)

                        TextField("Search techniques...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.bottom, 10)

                    // Techniques list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredTechniques) { technique in
                                NavigationLink(destination: TechniqueDetailView(technique: technique)) {
                                    TechniqueCard(technique: technique)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct TechniqueCard: View {
    let technique: BakingTechnique

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(technique.title)
                    .font(.headline)
                    .foregroundColor(.breadBrown)

                Spacer()

                DifficultyBadge(difficulty: technique.difficulty)
            }

            Text(technique.description)
                .font(.subheadline)
                .foregroundColor(.primary.opacity(0.8))
                .lineLimit(2)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.9))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
    }
}

struct DifficultyBadge: View {
    let difficulty: String

    private var badgeColor: Color {
        switch difficulty {
        case "Beginner":
            return .green
        case "Intermediate":
            return .orange
        case "Advanced":
            return .red
        default:
            return .gray
        }
    }

    var body: some View {
        Text(difficulty)
            .font(.caption.bold())
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeColor)
            .cornerRadius(6)
    }
}

struct TechniqueDetailView: View {
    let technique: BakingTechnique
    @State private var showingAILearnMore = false
    @State private var aiResponse = ""
    @State private var isLoadingAI = false

    var body: some View {
        ZStack {
            Color.breadBeige.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title and difficulty
                    VStack(alignment: .leading, spacing: 8) {
                        Text(technique.title)
                            .font(.largeTitle.bold())
                            .foregroundColor(.breadBrown)

                        HStack {
                            Text("Difficulty:")
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            DifficultyBadge(difficulty: technique.difficulty)
                        }
                    }
                    .padding(.top)

                    // Short description
                    Text(technique.description)
                        .font(.title3)
                        .foregroundColor(.breadBrown.opacity(0.8))
                        .padding(.vertical, 5)

                    Divider()

                    // Detailed explanation
                    VStack(alignment: .leading, spacing: 10) {
                        Text("How It Works")
                            .font(.title2.bold())
                            .foregroundColor(.breadBrown)

                        Text(technique.detailedExplanation)
                            .font(.body)
                            .foregroundColor(.primary)
                    }

                    Divider()

                    // Tips section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tips & Best Practices")
                            .font(.title2.bold())
                            .foregroundColor(.breadBrown)

                        ForEach(Array(technique.tips.enumerated()), id: \.offset) { index, tip in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "\(index + 1).circle.fill")
                                    .foregroundColor(.breadBrown)
                                    .font(.system(size: 20))

                                Text(tip)
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                        }
                    }

                    // AI Learn More button
                    Button(action: {
                        showingAILearnMore = true
                        loadAIInsights()
                    }) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Learn More with AI")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.breadBrown)
                        .cornerRadius(12)
                    }
                    .padding(.top, 10)
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAILearnMore) {
            AILearnMoreSheet(
                techniqueName: technique.title,
                response: aiResponse,
                isLoading: isLoadingAI
            )
        }
    }

    private func loadAIInsights() {
        guard aiResponse.isEmpty else { return }

        isLoadingAI = true
        let query = "Tell me more about the \(technique.title) technique in bread baking. Include common mistakes to avoid and advanced tips."

        Task {
            let result = await BreadService.shared.askAboutBreadWithFallback(query: query)
            await MainActor.run {
                aiResponse = result.response
                isLoadingAI = false
            }
        }
    }
}

struct AILearnMoreSheet: View {
    let techniqueName: String
    let response: String
    let isLoading: Bool
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.breadBeige.ignoresSafeArea()

                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Consulting the AI baker...")
                            .font(.headline)
                            .foregroundColor(.breadBrown)
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("AI Insights")
                                .font(.title2.bold())
                                .foregroundColor(.breadBrown)
                                .padding(.bottom, 5)

                            Text(response)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Learn More: \(techniqueName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.breadBrown)
                }
            }
        }
    }
}

#Preview {
    TechniqueLibraryView()
}
