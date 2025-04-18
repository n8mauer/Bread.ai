import SwiftUI

// Badge model
struct Badge: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String  // SF Symbol name
    let color: Color
    let isUnlocked: Bool
    let points: Int
}

// Badge category
struct BadgeCategory: Identifiable {
    let id = UUID()
    let name: String
    let badges: [Badge]
}

// Badge data
class BadgeData {
    static let categories: [BadgeCategory] = [
        // Skill-Based Badges
        BadgeCategory(name: "Skill-Based Badges", badges: [
            Badge(name: "The Rise Master", description: "Perfect your bread rise technique", icon: "arrow.up.and.down", color: .orange, isUnlocked: true, points: 50),
            Badge(name: "Crust King/Queen", description: "Create perfect golden crusts", icon: "allergens", color: .brown, isUnlocked: false, points: 100),
            Badge(name: "Knead for Speed", description: "Develop efficient kneading technique", icon: "hand.raised.fill", color: .green, isUnlocked: false, points: 75),
            Badge(name: "Proof Positive", description: "Master dough proofing", icon: "clock.fill", color: .blue, isUnlocked: false, points: 80),
            Badge(name: "Precision Baker", description: "Bake with exact measurements and timing", icon: "scalemass.fill", color: .purple, isUnlocked: false, points: 120)
        ]),
        
        // Consistency & Habit Badges
        BadgeCategory(name: "Consistency & Habit Badges", badges: [
            Badge(name: "Daily Dough", description: "Bake bread 7 days in a row", icon: "calendar.badge.clock", color: .red, isUnlocked: false, points: 150),
            Badge(name: "Weekend Warrior", description: "Bake on 4 consecutive weekends", icon: "calendar.badge.exclamationmark", color: .blue, isUnlocked: false, points: 100),
            Badge(name: "Starter Guardian", description: "Maintain your sourdough starter for 30 days", icon: "house.fill", color: .green, isUnlocked: false, points: 200),
            Badge(name: "Streak Saver", description: "Bake 30 days in a row", icon: "flame.fill", color: .orange, isUnlocked: false, points: 250)
        ]),
        
        // Creativity & Exploration Badges
        BadgeCategory(name: "Creativity & Exploration Badges", badges: [
            Badge(name: "Bread Explorer", description: "Try 5 different bread types", icon: "binoculars.fill", color: .purple, isUnlocked: false, points: 80),
            Badge(name: "Freestyle Flour", description: "Experiment with 3 alternative flours", icon: "leaf.fill", color: .green, isUnlocked: false, points: 90),
            Badge(name: "Pan Artist", description: "Create decorative bread scoring patterns", icon: "scribble", color: .blue, isUnlocked: false, points: 70),
            Badge(name: "Seasonal Star", description: "Bake bread with seasonal ingredients", icon: "sun.max.fill", color: .orange, isUnlocked: false, points: 60)
        ]),
        
        // Community & Social Badges
        BadgeCategory(name: "Community & Social Badges", badges: [
            Badge(name: "First Share", description: "Share your first bread on social media", icon: "square.and.arrow.up", color: .blue, isUnlocked: false, points: 30),
            Badge(name: "Feedback Friend", description: "Give feedback on 5 other bakers' breads", icon: "text.bubble.fill", color: .purple, isUnlocked: false, points: 50),
            Badge(name: "Challenge Accepted", description: "Complete a community bread challenge", icon: "flag.fill", color: .green, isUnlocked: false, points: 100),
            Badge(name: "Inspiration Giver", description: "Have your bread featured as inspiration", icon: "star.fill", color: .yellow, isUnlocked: false, points: 150)
        ]),
        
        // Milestone Badges
        BadgeCategory(name: "Milestone Badges", badges: [
            Badge(name: "Rookie Baker", description: "Bake your first loaf", icon: "1.circle.fill", color: .green, isUnlocked: true, points: 10),
            Badge(name: "10 Bakes Later...", description: "Bake 10 loaves of bread", icon: "10.circle.fill", color: .blue, isUnlocked: false, points: 100),
            Badge(name: "Master Mixer", description: "Bake 50 loaves of bread", icon: "50.circle.fill", color: .purple, isUnlocked: false, points: 500),
            Badge(name: "Flour Fanatic", description: "Bake 100 loaves of bread", icon: "100.circle.fill", color: .orange, isUnlocked: false, points: 1000)
        ])
    ]
}

// User profile model
struct UserProfile {
    var name: String = "Bread Baker"
    var level: Int = 1
    var currentPoints: Int = 60
    var pointsToNextLevel: Int = 200
    var profileImage: String = "person.crop.circle.fill" // Default SF Symbol for profile
    
    var progressToNextLevel: Double {
        Double(currentPoints) / Double(pointsToNextLevel)
    }
}