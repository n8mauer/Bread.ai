import SwiftUI

struct ContentView: View {
    @State private var breadQuery: String
    @State private var response: String
    @State private var isLoading: Bool
    @State private var currentResponseId: String = ""
    @State private var currentPromptVariant: String = ""
    @State private var feedbackSubmitted: FeedbackRating?
    @State private var showFeedbackThanks: Bool = false
    @State private var isCached: Bool = false
    @ObservedObject private var gamification = GamificationManager.shared

    init(breadQuery: String = "", response: String = "", isLoading: Bool = false) {
        self._breadQuery = State(initialValue: breadQuery)
        self._response = State(initialValue: response)
        self._isLoading = State(initialValue: isLoading)
    }

    var body: some View {
        ZStack {
            Color.breadBeige.ignoresSafeArea()

            VStack {
                Image("bread.ai logo no background")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100)
                    .padding()

                TextField("Ask about bread...", text: $breadQuery)
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                    .padding(.horizontal)
                    .disabled(isLoading)
                    .onSubmit {
                        askQuestion()
                    }

                Button(action: askQuestion) {
                    HStack {
                        Text("Ask")
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.leading, 5)
                        }
                    }
                    .padding()
                    .frame(minWidth: 100)
                    .background(Color.breadBrown)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
                }
                .disabled(breadQuery.isEmpty || isLoading)
                .padding()

                if !response.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            // Response with cache indicator
                            VStack(alignment: .leading, spacing: 8) {
                                if isCached {
                                    HStack {
                                        Image(systemName: "bolt.fill")
                                            .foregroundColor(.orange)
                                        Text("Cached response")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                }

                                Text(response)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)

                            // Feedback buttons
                            if !currentResponseId.isEmpty {
                                FeedbackButtonsView(
                                    feedbackSubmitted: $feedbackSubmitted,
                                    showThanks: $showFeedbackThanks,
                                    onFeedback: { rating in
                                        submitFeedback(rating: rating)
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()

                Text("Bread.ai - Your AI Bread Expert")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 10)
            }
            .padding()
        }
        .alert(isPresented: $gamification.showBadgeUnlockAlert) {
            Alert(
                title: Text("Badge Unlocked!"),
                message: Text("You earned: \(gamification.recentlyUnlockedBadge?.name ?? "")"),
                dismissButton: .default(Text("Awesome!"))
            )
        }
    }

    private func askQuestion() {
        guard !breadQuery.isEmpty, !isLoading else { return }

        isLoading = true
        feedbackSubmitted = nil
        showFeedbackThanks = false
        isCached = false
        gamification.logQuestionAsked()

        let query = breadQuery

        Task {
            let result = await BreadService.shared.askAboutBreadWithFallback(query: query)

            await MainActor.run {
                response = result.response
                if let metadata = result.metadata {
                    currentResponseId = metadata.responseId
                    currentPromptVariant = metadata.promptVariant
                    isCached = metadata.cached ?? false
                } else {
                    currentResponseId = ""
                    currentPromptVariant = ""
                    isCached = false
                }
                isLoading = false
            }
        }
    }

    private func submitFeedback(rating: FeedbackRating) {
        let query = breadQuery
        let responseText = response
        let responseId = currentResponseId
        let promptVariant = currentPromptVariant

        Task {
            let success = await BreadService.shared.submitFeedbackSilently(
                responseId: responseId,
                query: query,
                response: responseText,
                rating: rating,
                promptVariant: promptVariant,
                responseType: "ask",
                comment: nil
            )

            await MainActor.run {
                if success {
                    feedbackSubmitted = rating
                    showFeedbackThanks = true

                    Task {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        await MainActor.run {
                            showFeedbackThanks = false
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Feedback Buttons View

struct FeedbackButtonsView: View {
    @Binding var feedbackSubmitted: FeedbackRating?
    @Binding var showThanks: Bool
    let onFeedback: (FeedbackRating) -> Void

    var body: some View {
        VStack(spacing: 8) {
            if showThanks {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Thanks for your feedback!")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .transition(.opacity)
            } else if feedbackSubmitted == nil {
                HStack(spacing: 16) {
                    Text("Was this helpful?")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Button(action: { onFeedback(.positive) }) {
                        HStack(spacing: 4) {
                            Image(systemName: "hand.thumbsup.fill")
                            Text("Yes")
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(16)
                    }

                    Button(action: { onFeedback(.negative) }) {
                        HStack(spacing: 4) {
                            Image(systemName: "hand.thumbsdown.fill")
                            Text("No")
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.2))
                        .foregroundColor(.red)
                        .cornerRadius(16)
                    }
                }
            } else {
                HStack {
                    Image(systemName: feedbackSubmitted == .positive ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                        .foregroundColor(feedbackSubmitted == .positive ? .green : .red)
                    Text("Feedback recorded")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .animation(.easeInOut, value: feedbackSubmitted)
        .animation(.easeInOut, value: showThanks)
    }
}

// MARK: - Previews

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

#if compiler(>=5.9)
#Preview("Empty State") {
    ContentView()
}

#Preview("With Response") {
    ContentView_WithResponse()
}

struct ContentView_WithResponse: View {
    var body: some View {
        ContentView(
            breadQuery: "What is sourdough?",
            response: "Sourdough bread is made by fermenting dough using naturally occurring wild yeast and lactic acid bacteria."
        )
    }
}
#endif
