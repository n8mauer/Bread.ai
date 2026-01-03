import SwiftUI

struct ContentView: View {
    @State private var breadQuery: String
    @State private var response: String
    @State private var isLoading: Bool
    @State private var currentResponseId: String = ""
    @State private var currentPromptVariant: String = ""
    @State private var feedbackSubmitted: FeedbackRating?
    @State private var showFeedbackThanks: Bool = false
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
                            Text(response)
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
        guard !breadQuery.isEmpty else { return }

        isLoading = true
        feedbackSubmitted = nil
        showFeedbackThanks = false
        gamification.logQuestionAsked()

        let query = breadQuery

        BreadService.shared.askAboutBread(query: query) { aiResponse in
            isLoading = false

            if let aiResponse = aiResponse {
                response = aiResponse.response
                currentResponseId = aiResponse.responseId
                currentPromptVariant = aiResponse.promptVariant
            } else {
                response = "Sorry, I couldn't process that request. Please try again."
                currentResponseId = ""
                currentPromptVariant = ""
            }
        }
    }

    private func submitFeedback(rating: FeedbackRating) {
        BreadService.shared.submitFeedback(
            responseId: currentResponseId,
            query: breadQuery,
            response: response,
            rating: rating,
            promptVariant: currentPromptVariant,
            responseType: "ask",
            comment: nil
        ) { success in
            if success {
                feedbackSubmitted = rating
                showFeedbackThanks = true

                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showFeedbackThanks = false
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
    @State private var breadQuery: String = "What is sourdough?"
    @State private var response: String = "Sourdough bread is made by fermenting dough using naturally occurring wild yeast and lactic acid bacteria. This gives it a slightly sour taste and improved keeping qualities."
    @State private var isLoading: Bool = false

    var body: some View {
        ContentView(breadQuery: breadQuery, response: response, isLoading: isLoading)
    }
}
#endif
