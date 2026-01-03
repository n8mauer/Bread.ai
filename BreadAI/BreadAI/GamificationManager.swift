import Foundation
import SwiftUI
import Combine

// MARK: - User Statistics Model
struct UserStats: Codable {
    var totalLoavesBaked: Int = 0
    var recipesViewed: Set<String> = []
    var questionsAsked: Int = 0
    var consecutiveBakingDays: Int = 0
    var lastBakeDate: Date?
    var weekendBakes: Int = 0
    var starterDaysActive: Int = 0
    var starterStartDate: Date?
    var alternativeFloursUsed: Set<String> = []
    var seasonalBakes: Int = 0
    var socialShares: Int = 0
    var feedbackGiven: Int = 0
    var challengesCompleted: Int = 0
    var totalPoints: Int = 0
    var level: Int = 1
    var unlockedBadgeIds: Set<String> = []

    // Track dates for streak calculation
    var bakingDates: [Date] = []
}

// MARK: - Badge Definition with Unlock Criteria
struct BadgeDefinition: Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let color: Color
    let points: Int
    let category: BadgeCategoryType
    let unlockCriteria: (UserStats) -> Bool

    func toBadge(isUnlocked: Bool) -> UnlockableBadge {
        UnlockableBadge(
            id: id,
            name: name,
            description: description,
            icon: icon,
            color: color,
            points: points,
            isUnlocked: isUnlocked
        )
    }
}

struct UnlockableBadge: Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let color: Color
    let points: Int
    let isUnlocked: Bool
}

enum BadgeCategoryType: String, CaseIterable {
    case skillBased = "Skill-Based Badges"
    case consistency = "Consistency & Habit Badges"
    case creativity = "Creativity & Exploration Badges"
    case community = "Community & Social Badges"
    case milestone = "Milestone Badges"
}

// MARK: - Gamification Manager
class GamificationManager: ObservableObject {
    static let shared = GamificationManager()

    @Published var userStats: UserStats
    @Published var recentlyUnlockedBadge: UnlockableBadge?
    @Published var showBadgeUnlockAlert: Bool = false

    private let userDefaultsKey = "BreadAI_UserStats"
    private var cancellables = Set<AnyCancellable>()

    // All badge definitions with unlock criteria
    let badgeDefinitions: [BadgeDefinition] = [
        // MARK: Skill-Based Badges
        BadgeDefinition(
            id: "rise_master",
            name: "The Rise Master",
            description: "Perfect your bread rise technique",
            icon: "arrow.up.and.down",
            color: .orange,
            points: 50,
            category: .skillBased,
            unlockCriteria: { stats in stats.totalLoavesBaked >= 3 }
        ),
        BadgeDefinition(
            id: "crust_royalty",
            name: "Crust King/Queen",
            description: "Create perfect golden crusts",
            icon: "allergens",
            color: .brown,
            points: 100,
            category: .skillBased,
            unlockCriteria: { stats in stats.totalLoavesBaked >= 10 }
        ),
        BadgeDefinition(
            id: "knead_speed",
            name: "Knead for Speed",
            description: "Develop efficient kneading technique",
            icon: "hand.raised.fill",
            color: .green,
            points: 75,
            category: .skillBased,
            unlockCriteria: { stats in stats.totalLoavesBaked >= 5 }
        ),
        BadgeDefinition(
            id: "proof_positive",
            name: "Proof Positive",
            description: "Master dough proofing",
            icon: "clock.fill",
            color: .blue,
            points: 80,
            category: .skillBased,
            unlockCriteria: { stats in stats.recipesViewed.count >= 5 && stats.totalLoavesBaked >= 5 }
        ),
        BadgeDefinition(
            id: "precision_baker",
            name: "Precision Baker",
            description: "Bake with exact measurements and timing",
            icon: "scalemass.fill",
            color: .purple,
            points: 120,
            category: .skillBased,
            unlockCriteria: { stats in stats.totalLoavesBaked >= 15 }
        ),

        // MARK: Consistency & Habit Badges
        BadgeDefinition(
            id: "daily_dough",
            name: "Daily Dough",
            description: "Bake bread 7 days in a row",
            icon: "calendar.badge.clock",
            color: .red,
            points: 150,
            category: .consistency,
            unlockCriteria: { stats in stats.consecutiveBakingDays >= 7 }
        ),
        BadgeDefinition(
            id: "weekend_warrior",
            name: "Weekend Warrior",
            description: "Bake on 4 consecutive weekends",
            icon: "calendar.badge.exclamationmark",
            color: .blue,
            points: 100,
            category: .consistency,
            unlockCriteria: { stats in stats.weekendBakes >= 4 }
        ),
        BadgeDefinition(
            id: "starter_guardian",
            name: "Starter Guardian",
            description: "Maintain your sourdough starter for 30 days",
            icon: "house.fill",
            color: .green,
            points: 200,
            category: .consistency,
            unlockCriteria: { stats in stats.starterDaysActive >= 30 }
        ),
        BadgeDefinition(
            id: "streak_saver",
            name: "Streak Saver",
            description: "Bake 30 days in a row",
            icon: "flame.fill",
            color: .orange,
            points: 250,
            category: .consistency,
            unlockCriteria: { stats in stats.consecutiveBakingDays >= 30 }
        ),

        // MARK: Creativity & Exploration Badges
        BadgeDefinition(
            id: "bread_explorer",
            name: "Bread Explorer",
            description: "Try 5 different bread types",
            icon: "binoculars.fill",
            color: .purple,
            points: 80,
            category: .creativity,
            unlockCriteria: { stats in stats.recipesViewed.count >= 5 }
        ),
        BadgeDefinition(
            id: "freestyle_flour",
            name: "Freestyle Flour",
            description: "Experiment with 3 alternative flours",
            icon: "leaf.fill",
            color: .green,
            points: 90,
            category: .creativity,
            unlockCriteria: { stats in stats.alternativeFloursUsed.count >= 3 }
        ),
        BadgeDefinition(
            id: "pan_artist",
            name: "Pan Artist",
            description: "Create decorative bread scoring patterns",
            icon: "scribble",
            color: .blue,
            points: 70,
            category: .creativity,
            unlockCriteria: { stats in stats.totalLoavesBaked >= 8 }
        ),
        BadgeDefinition(
            id: "seasonal_star",
            name: "Seasonal Star",
            description: "Bake bread with seasonal ingredients",
            icon: "sun.max.fill",
            color: .orange,
            points: 60,
            category: .creativity,
            unlockCriteria: { stats in stats.seasonalBakes >= 1 }
        ),

        // MARK: Community & Social Badges
        BadgeDefinition(
            id: "first_share",
            name: "First Share",
            description: "Share your first bread on social media",
            icon: "square.and.arrow.up",
            color: .blue,
            points: 30,
            category: .community,
            unlockCriteria: { stats in stats.socialShares >= 1 }
        ),
        BadgeDefinition(
            id: "feedback_friend",
            name: "Feedback Friend",
            description: "Give feedback on 5 other bakers' breads",
            icon: "text.bubble.fill",
            color: .purple,
            points: 50,
            category: .community,
            unlockCriteria: { stats in stats.feedbackGiven >= 5 }
        ),
        BadgeDefinition(
            id: "challenge_accepted",
            name: "Challenge Accepted",
            description: "Complete a community bread challenge",
            icon: "flag.fill",
            color: .green,
            points: 100,
            category: .community,
            unlockCriteria: { stats in stats.challengesCompleted >= 1 }
        ),
        BadgeDefinition(
            id: "ask_expert",
            name: "Curious Baker",
            description: "Ask 10 questions to the AI bread expert",
            icon: "questionmark.bubble.fill",
            color: .cyan,
            points: 40,
            category: .community,
            unlockCriteria: { stats in stats.questionsAsked >= 10 }
        ),

        // MARK: Milestone Badges
        BadgeDefinition(
            id: "rookie_baker",
            name: "Rookie Baker",
            description: "Bake your first loaf",
            icon: "1.circle.fill",
            color: .green,
            points: 10,
            category: .milestone,
            unlockCriteria: { stats in stats.totalLoavesBaked >= 1 }
        ),
        BadgeDefinition(
            id: "ten_bakes",
            name: "10 Bakes Later...",
            description: "Bake 10 loaves of bread",
            icon: "10.circle.fill",
            color: .blue,
            points: 100,
            category: .milestone,
            unlockCriteria: { stats in stats.totalLoavesBaked >= 10 }
        ),
        BadgeDefinition(
            id: "master_mixer",
            name: "Master Mixer",
            description: "Bake 50 loaves of bread",
            icon: "50.circle.fill",
            color: .purple,
            points: 500,
            category: .milestone,
            unlockCriteria: { stats in stats.totalLoavesBaked >= 50 }
        ),
        BadgeDefinition(
            id: "flour_fanatic",
            name: "Flour Fanatic",
            description: "Bake 100 loaves of bread",
            icon: "100.circle.fill",
            color: .orange,
            points: 1000,
            category: .milestone,
            unlockCriteria: { stats in stats.totalLoavesBaked >= 100 }
        ),
        BadgeDefinition(
            id: "first_question",
            name: "Inquisitive Mind",
            description: "Ask your first question",
            icon: "lightbulb.fill",
            color: .yellow,
            points: 5,
            category: .milestone,
            unlockCriteria: { stats in stats.questionsAsked >= 1 }
        )
    ]

    private init() {
        self.userStats = UserStats()
        loadStats()
    }

    // MARK: - Persistence
    private func loadStats() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let stats = try? JSONDecoder().decode(UserStats.self, from: data) {
            self.userStats = stats
        }
    }

    private func saveStats() {
        if let data = try? JSONEncoder().encode(userStats) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }

    // MARK: - Badge Evaluation
    func evaluateBadges() {
        var newlyUnlocked: [BadgeDefinition] = []

        for badge in badgeDefinitions {
            let wasUnlocked = userStats.unlockedBadgeIds.contains(badge.id)
            let isNowUnlocked = badge.unlockCriteria(userStats)

            if !wasUnlocked && isNowUnlocked {
                userStats.unlockedBadgeIds.insert(badge.id)
                userStats.totalPoints += badge.points
                newlyUnlocked.append(badge)
            }
        }

        // Update level based on points
        updateLevel()

        // Save after evaluation
        saveStats()

        // Show notification for first newly unlocked badge
        if let firstUnlocked = newlyUnlocked.first {
            DispatchQueue.main.async {
                self.recentlyUnlockedBadge = firstUnlocked.toBadge(isUnlocked: true)
                self.showBadgeUnlockAlert = true
            }
        }
    }

    private func updateLevel() {
        // Level thresholds: 0-199 = L1, 200-499 = L2, 500-999 = L3, etc.
        let thresholds = [0, 200, 500, 1000, 2000, 4000, 7000, 10000]
        for (index, threshold) in thresholds.enumerated() {
            if userStats.totalPoints >= threshold {
                userStats.level = index + 1
            }
        }
    }

    // MARK: - User Actions
    func logBake(breadType: String) {
        userStats.totalLoavesBaked += 1
        userStats.recipesViewed.insert(breadType)

        let today = Calendar.current.startOfDay(for: Date())
        userStats.bakingDates.append(today)

        // Update consecutive days
        updateConsecutiveDays()

        // Check if weekend
        let weekday = Calendar.current.component(.weekday, from: today)
        if weekday == 1 || weekday == 7 {
            userStats.weekendBakes += 1
        }

        evaluateBadges()
    }

    func logRecipeViewed(breadType: String) {
        userStats.recipesViewed.insert(breadType)
        saveStats()
        evaluateBadges()
    }

    func logQuestionAsked() {
        userStats.questionsAsked += 1
        saveStats()
        evaluateBadges()
    }

    func logSocialShare() {
        userStats.socialShares += 1
        saveStats()
        evaluateBadges()
    }

    func logFeedbackGiven() {
        userStats.feedbackGiven += 1
        saveStats()
        evaluateBadges()
    }

    func logChallengeCompleted() {
        userStats.challengesCompleted += 1
        saveStats()
        evaluateBadges()
    }

    func logAlternativeFlourUsed(_ flour: String) {
        userStats.alternativeFloursUsed.insert(flour)
        saveStats()
        evaluateBadges()
    }

    func logSeasonalBake() {
        userStats.seasonalBakes += 1
        saveStats()
        evaluateBadges()
    }

    func startSourdoughStarter() {
        userStats.starterStartDate = Date()
        userStats.starterDaysActive = 0
        saveStats()
    }

    func updateStarterDays() {
        guard let startDate = userStats.starterStartDate else { return }
        let days = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        userStats.starterDaysActive = days
        saveStats()
        evaluateBadges()
    }

    private func updateConsecutiveDays() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Sort dates and remove duplicates
        let uniqueDates = Set(userStats.bakingDates.map { calendar.startOfDay(for: $0) })
        let sortedDates = uniqueDates.sorted(by: >)

        var streak = 0
        var currentDate = today

        for date in sortedDates {
            if date == currentDate {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else if date < currentDate {
                break
            }
        }

        userStats.consecutiveBakingDays = streak
        userStats.lastBakeDate = today
    }

    // MARK: - Getters for UI
    func getBadgesForCategory(_ category: BadgeCategoryType) -> [UnlockableBadge] {
        return badgeDefinitions
            .filter { $0.category == category }
            .map { $0.toBadge(isUnlocked: userStats.unlockedBadgeIds.contains($0.id)) }
    }

    func getAllBadges() -> [UnlockableBadge] {
        return badgeDefinitions.map { $0.toBadge(isUnlocked: userStats.unlockedBadgeIds.contains($0.id)) }
    }

    func getUnlockedBadgesCount() -> Int {
        return userStats.unlockedBadgeIds.count
    }

    func getTotalBadgesCount() -> Int {
        return badgeDefinitions.count
    }

    func getUserProfile() -> GamificationUserProfile {
        let pointsForCurrentLevel = getPointsForLevel(userStats.level)
        let pointsForNextLevel = getPointsForLevel(userStats.level + 1)
        let pointsInCurrentLevel = userStats.totalPoints - pointsForCurrentLevel
        let pointsNeededForNext = pointsForNextLevel - pointsForCurrentLevel

        return GamificationUserProfile(
            name: "Bread Baker",
            level: userStats.level,
            currentPoints: userStats.totalPoints,
            pointsInLevel: pointsInCurrentLevel,
            pointsToNextLevel: pointsNeededForNext,
            profileImage: "person.crop.circle.fill"
        )
    }

    private func getPointsForLevel(_ level: Int) -> Int {
        let thresholds = [0, 0, 200, 500, 1000, 2000, 4000, 7000, 10000, 15000]
        if level < thresholds.count {
            return thresholds[level]
        }
        return thresholds.last! + (level - thresholds.count + 1) * 5000
    }

    // MARK: - Debug/Testing
    func resetAllProgress() {
        userStats = UserStats()
        saveStats()
    }
}

// MARK: - Profile Model for UI
struct GamificationUserProfile {
    var name: String
    var level: Int
    var currentPoints: Int
    var pointsInLevel: Int
    var pointsToNextLevel: Int
    var profileImage: String

    var progressToNextLevel: Double {
        guard pointsToNextLevel > 0 else { return 1.0 }
        return Double(pointsInLevel) / Double(pointsToNextLevel)
    }
}
