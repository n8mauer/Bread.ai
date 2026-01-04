import SwiftUI
import Foundation

struct MainTabView: View {
    @State private var selectedTab = 0 // Start with Recipes tab selected
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Recipes Tab
            RecipesView()
                .tabItem {
                    Image(systemName: "book")
                    Text("Recipes")
                }
                .tag(0)
            
            // Timer Tab
            TimerView()
                .tabItem {
                    Image(systemName: "timer")
                    Text("Timer")
                }
                .tag(1)
            
            // Resources Tab (This is our ContentView)
            ContentView(breadQuery: "", response: "", isLoading: false)
                .tabItem {
                    Image(systemName: "questionmark.circle")
                    Text("Resources")
                }
                .tag(2)
            
            // Badges Tab
            BadgesView()
                .tabItem {
                    Image(systemName: "rosette")
                    Text("Badges")
                }
                .tag(3)
        }
        .accentColor(.breadBrown) // Use our custom color for selected tabs
    }
}

// Placeholder views for the other tabs
// These will be replaced with actual implementations later

struct TimerView: View {
    var body: some View {
        ZStack {
            Color.breadBeige.ignoresSafeArea()
            
            VStack {
                Image("bread.ai logo no background")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100)
                    .padding(.top, 40)
                
                Text("Timer")
                    .font(.largeTitle.bold())
                    .foregroundColor(.breadBrown)
                    .padding()
                
                Text("Coming Soon!")
                    .font(.title2)
                    .foregroundColor(.gray)
                    .padding()
                
                Text("Track your bread rising and baking times")
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .padding()
        }
    }
}

struct RecipesView: View {
    private let breadCategories = BreadData.categories
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .center, spacing: 0) {
                    // Title and Logo
                    Text("Recipes")
                        .font(.largeTitle.bold())
                        .foregroundColor(.breadBrown)
                        .padding(.top, 15)
                    
                    Image("bread.ai logo no background")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100)
                        .padding(.top, 5)
                        .padding(.bottom, 8) // Reduced padding between logo and first ScrollView
                    
                    // Categories with horizontal scrolling bread types
                    VStack(alignment: .leading, spacing: 15) {
                        ForEach(breadCategories) { category in
                            CategoryHeaderView(title: category.name)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(category.breads) { bread in
                                        NavigationLink(destination: RecipeDetailView(bread: bread)) {
                                            BreadCardView(bread: bread)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 10)
                            }
                        }
                    }
                }
            }
            .background(Color.breadBeige.ignoresSafeArea())
            // This empty navigation bar helps with the navigation transitions
            .navigationBarHidden(true)
        }
        // Use inline display mode for better aesthetics when navigating
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct BadgesView: View {
    @ObservedObject private var gamification = GamificationManager.shared

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.breadBeige.ignoresSafeArea()

                // Main scroll view for all content
                ScrollView {
                    VStack(spacing: 0) {
                        // Title
                        Text("Badges")
                            .font(.largeTitle.bold())
                            .foregroundColor(.breadBrown)
                            .padding(.top, 10)

                        // Stats summary
                        HStack(spacing: 20) {
                            StatBadge(value: "\(gamification.getUnlockedBadgesCount())", label: "Unlocked")
                            StatBadge(value: "\(gamification.getTotalBadgesCount())", label: "Total")
                            StatBadge(value: "\(gamification.userStats.totalLoavesBaked)", label: "Bakes")
                        }
                        .padding(.top, 10)

                        // User profile header with progress
                        GamificationProfileHeader(profile: gamification.getUserProfile())
                            .padding(.top, 10)

                        // Badge categories sections
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(BadgeCategoryType.allCases, id: \.rawValue) { category in
                                let badges = gamification.getBadgesForCategory(category)
                                if !badges.isEmpty {
                                    BadgeCategoryHeader(title: category.rawValue)

                                    // Horizontal scroll for badges in this category
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(badges) { badge in
                                                NavigationLink(destination: UnlockableBadgeDetailView(badge: badge)) {
                                                    UnlockableBadgeCard(badge: badge)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            }
                                        }
                                        .padding(.horizontal)
                                        .padding(.bottom, 10)
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct StatBadge: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundColor(.breadBrown)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(width: 80)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.8))
        .cornerRadius(10)
    }
}

struct GamificationProfileHeader: View {
    let profile: GamificationUserProfile

    var body: some View {
        VStack(spacing: 15) {
            // Profile Image
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 110, height: 110)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 3)

                Image(systemName: profile.profileImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 90)
                    .foregroundColor(.breadBrown)
            }
            .padding(.top, 20)

            // User name and level
            Text(profile.name)
                .font(.title2.bold())

            Text("Level \(profile.level)")
                .font(.headline)
                .foregroundColor(.breadBrown)

            // Total points
            Text("\(profile.currentPoints) Total XP")
                .font(.subheadline)
                .foregroundColor(.gray)

            // Progress bar to next level
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("\(profile.pointsInLevel) / \(profile.pointsToNextLevel) XP to next level")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Spacer()

                    Text("Level \(profile.level + 1)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 15)

                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.breadBrown)
                            .frame(width: geometry.size.width * min(profile.progressToNextLevel, 1.0), height: 15)
                    }
                }
                .frame(height: 15)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.6))
        .cornerRadius(20)
        .padding(.horizontal)
        .padding(.top, 10)
    }
}

struct UnlockableBadgeCard: View {
    let badge: UnlockableBadge

    var body: some View {
        VStack {
            Image(systemName: badge.icon)
                .font(.system(size: 32))
                .foregroundColor(badge.color)
                .padding()
                .background(
                    Circle()
                        .fill(badge.color.opacity(0.2))
                        .frame(width: 70, height: 70)
                )
                .padding(.bottom, 5)

            Text(badge.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 5)

            Text("\(badge.points) pts")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.top, 1)
        }
        .frame(width: 130, height: 160)
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.9))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .opacity(badge.isUnlocked ? 1.0 : 0.5)
        .overlay(
            badge.isUnlocked ?
                AnyView(
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .background(Circle().fill(Color.white))
                        .offset(x: 50, y: -65)
                ) : AnyView(EmptyView())
        )
    }
}

struct UnlockableBadgeDetailView: View {
    let badge: UnlockableBadge

    var body: some View {
        ZStack {
            Color.breadBeige.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 25) {
                    // Badge icon
                    Image(systemName: badge.icon)
                        .font(.system(size: 80))
                        .foregroundColor(badge.color)
                        .padding()
                        .background(
                            Circle()
                                .fill(badge.color.opacity(0.2))
                                .frame(width: 180, height: 180)
                        )
                        .padding(.top, 30)

                    // Badge name
                    Text(badge.name)
                        .font(.title.bold())
                        .foregroundColor(.breadBrown)
                        .multilineTextAlignment(.center)

                    // Badge description
                    Text(badge.description)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // Badge status
                    HStack {
                        Image(systemName: badge.isUnlocked ? "checkmark.circle.fill" : "lock.fill")
                            .foregroundColor(badge.isUnlocked ? .green : .gray)

                        Text(badge.isUnlocked ? "Unlocked" : "Locked")
                            .font(.headline)
                            .foregroundColor(badge.isUnlocked ? .green : .gray)
                    }
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(15)

                    // Badge points
                    VStack {
                        Text("Point Value")
                            .font(.headline)
                            .foregroundColor(.gray)

                        Text("\(badge.points) XP")
                            .font(.title)
                            .foregroundColor(.breadBrown)
                            .fontWeight(.bold)
                    }
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(15)

                    Spacer()
                }
                .padding()
            }
        }
        .navigationTitle(badge.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Detail view for when a badge is tapped
struct BadgeDetailView: View {
    let badge: Badge
    
    var body: some View {
        ZStack {
            Color.breadBeige.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 25) {
                    // Badge icon
                    BadgeIconView(badge: badge)
                    
                    // Badge name
                    Text(badge.name)
                        .font(.title.bold())
                        .foregroundColor(.breadBrown)
                        .multilineTextAlignment(.center)
                    
                    // Badge description
                    Text(badge.description)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding([.horizontal])
                    
                    // Badge status
                    HStack {
                        Image(systemName: badge.isUnlocked ? "checkmark.circle.fill" : "lock.fill")
                            .foregroundColor(badge.isUnlocked ? .green : .gray)
                        
                        Text(badge.isUnlocked ? "Unlocked" : "Locked")
                            .font(.headline)
                            .foregroundColor(badge.isUnlocked ? .green : .gray)
                    }
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(15)
                    
                    // Badge points
                    VStack {
                        Text("Point Value")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("\(badge.points) XP")
                            .font(.title)
                            .foregroundColor(.breadBrown)
                            .fontWeight(.bold)
                    }
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(15)
                    
                    Spacer()
                }
                .padding()
                .opacity(badge.isUnlocked ? 1.0 : 0.8)
                .overlay(BadgeUnlockOverlay(isUnlocked: badge.isUnlocked))
            }
        }
        .navigationTitle(badge.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}

#if compiler(>=5.9)
#Preview {
    MainTabView()
}
#endif

// MARK: - Helper Views for MainTabView

struct BadgeCategoryHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.title2.bold())
                .foregroundColor(.breadBrown)
                .padding(.leading)

            Spacer()
        }
        .padding(.top, 15)
        .padding(.bottom, 5)
    }
}

struct BadgeIconView: View {
    let badge: Badge

    var body: some View {
        Image(systemName: badge.icon)
            .font(.system(size: 80))
            .foregroundColor(badge.color)
            .padding()
            .background(
                Circle()
                    .fill(badge.color.opacity(0.2))
                    .frame(width: 180, height: 180)
            )
            .padding(.top, 30)
    }
}

struct BadgeUnlockOverlay: View {
    let isUnlocked: Bool

    var body: some View {
        if !isUnlocked {
            AnyView(
                Text("Complete this challenge to unlock")
                    .font(.headline)
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.bottom, 50)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            )
        } else {
            AnyView(EmptyView())
        }
    }
}
