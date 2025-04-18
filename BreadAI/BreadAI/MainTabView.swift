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
                                                .opacity(bread.isSourdough ? 1.0 : 0.5) // Apply reduced opacity to all except Sourdough
                                                .disabled(!bread.isSourdough) // Disable all except Sourdough
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
    // User profile data
    @State private var userProfile = UserProfile(name: "Bread Baker", level: 1, currentPoints: 60, pointsToNextLevel: 200, profileImage: "person.crop.circle.fill")
    
    // Badge categories and data
    private let badgeCategories = [
        BadgeCategory(name: "Skill-Based Badges", badges: [
            Badge(name: "The Rise Master", description: "Perfect your bread rise technique", icon: "arrow.up.and.down", color: .orange, isUnlocked: true, points: 50),
            Badge(name: "Crust King/Queen", description: "Create perfect golden crusts", icon: "allergens", color: .breadBrown, isUnlocked: false, points: 100)
        ]),
        BadgeCategory(name: "Consistency Badges", badges: [
            Badge(name: "Daily Dough", description: "Bake bread 7 days in a row", icon: "calendar.badge.clock", color: .red, isUnlocked: false, points: 150)
        ])
    ]
    
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
                        
                        // User profile header with progress
                        UserProfileHeader(profile: userProfile)
                            .padding(.top, 10)
                        
                        // Badge categories sections
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(badgeCategories) { category in
                                BadgeCategoryHeader(title: category.name)
                                
                                // Horizontal scroll for badges in this category
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(category.badges) { badge in
                                            NavigationLink(destination: BadgeDetailView(badge: badge)) {
                                                BadgeCard(badge: badge)
                                            }
                                            .buttonStyle(PlainButtonStyle()) // Prevents the navigation link from changing appearance
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.bottom, 10)
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

// Add temporary models and views until we can properly reference the actual files

// Badge models
struct Badge: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String  // SF Symbol name
    let color: Color
    let isUnlocked: Bool
    let points: Int
}

struct BadgeCategory: Identifiable {
    let id = UUID()
    let name: String
    let badges: [Badge]
}

struct UserProfile {
    var name: String
    var level: Int
    var currentPoints: Int
    var pointsToNextLevel: Int
    var profileImage: String  // Default SF Symbol for profile
    
    var progressToNextLevel: Double {
        Double(currentPoints) / Double(pointsToNextLevel)
    }
}

// Temporary model for bread categories and types
struct BreadCategory: Identifiable {
    let id = UUID()
    let name: String
    let breads: [Bread]
}

struct Bread: Identifiable {
    let id = UUID()
    let name: String
    let isSourdough: Bool
    let image: String // Image name in assets
    
    init(name: String, isSourdough: Bool = false, image: String = "bread.ai logo no background") {
        self.name = name
        self.isSourdough = isSourdough
        self.image = image
    }
}

// Temporary BreadData class
class BreadData {
    static let categories: [BreadCategory] = [
        BreadCategory(name: "Yeast-Based Breads", breads: [
            Bread(name: "Sourdough", isSourdough: true), // Moved to first position
            Bread(name: "White Sandwich Bread"),
            Bread(name: "Whole Wheat Bread"),
            Bread(name: "Brioche"),
            Bread(name: "Challah"),
            Bread(name: "Focaccia"),
            Bread(name: "Ciabatta"),
            Bread(name: "Bagels"),
            Bread(name: "Dinner Rolls")
        ]),
        BreadCategory(name: "Flatbreads", breads: [
            Bread(name: "Naan"),
            Bread(name: "Pita"),
            Bread(name: "Tortillas"),
            Bread(name: "Lefse")
        ]),
        BreadCategory(name: "Quick Breads (No Yeast)", breads: [
            Bread(name: "Banana Bread"),
            Bread(name: "Zucchini Bread"),
            Bread(name: "Pumpkin Bread"),
            Bread(name: "Cornbread"),
            Bread(name: "Beer Bread")
        ]),
        BreadCategory(name: "Specialty and Ethnic Breads", breads: [
            Bread(name: "Rye Bread"),
            Bread(name: "Irish Soda Bread"),
            Bread(name: "Lavash"),
            Bread(name: "Anadama Bread")
        ])
    ]
}

// Temporary BreadCardView
struct BreadCardView: View {
    let bread: Bread
    
    var body: some View {
        VStack {
            Image(bread.image)
                .resizable()
                .scaledToFit()
                .frame(height: 80)
                .padding(.top, 10)
            
            Text(bread.name)
                .font(.system(size: 14, weight: .medium))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
        }
        .frame(width: 120, height: 140)
        .background(Color.white.opacity(0.9))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.vertical, 5)
        .padding(.horizontal, 5)
    }
}

// Temporary RecipeDetailView
struct RecipeDetailView: View {
    let bread: Bread
    
    var body: some View {
        if bread.isSourdough {
            SourdoughRecipeView()
        } else {
            ComingSoonRecipeView(breadType: bread.name)
        }
    }
}

struct SourdoughRecipeView: View {
    var body: some View {
        ZStack {
            Color.breadBeige.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Sourdough Bread")
                        .font(.largeTitle.bold())
                        .foregroundColor(.breadBrown)
                        .padding()
                    
                    Text("Full recipe coming soon!")
                        .padding()
                    
                    Spacer()
                }
            }
        }
        .navigationTitle("Sourdough Recipe")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ComingSoonRecipeView: View {
    let breadType: String
    
    var body: some View {
        ZStack {
            Color.breadBeige.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Image("bread.ai logo no background")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120)
                
                Text(breadType)
                    .font(.largeTitle.bold())
                    .foregroundColor(.breadBrown)
                
                Text("Recipe Coming Soon!")
                    .font(.title2)
                    .foregroundColor(.gray)
                    .padding()
                
                Spacer()
            }
            .padding(.top, 50)
        }
        .navigationTitle(breadType)
        .navigationBarTitleDisplayMode(.inline)
    }
}
struct CategoryHeaderView: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.title2.bold())
                .foregroundColor(.breadBrown)
                .padding(.leading)
            
            Spacer()
        }
        .padding(.top)
    }
}

// Implementation of missing views
struct UserProfileHeader: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(spacing: 15) {
            // Profile Image
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 110, height: 110)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 3)
                
                if profile.profileImage.hasPrefix("person") {
                    // Use SF Symbol for default profile
                    Image(systemName: profile.profileImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90, height: 90)
                        .foregroundColor(.breadBrown)
                } else {
                    // Use image from assets
                    Image(profile.profileImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                }
                
                // Camera icon to suggest photo can be changed
                Image(systemName: "camera.fill")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Circle().fill(Color.breadBrown))
                    .offset(x: 40, y: 35)
            }
            .padding(.top, 20)
            
            // User name and level
            Text(profile.name)
                .font(.title2.bold())
            
            Text("Level \(profile.level)")
                .font(.headline)
                .foregroundColor(.breadBrown)
            
            // Progress bar to next level
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("\(profile.currentPoints) / \(profile.pointsToNextLevel) XP")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("Level \(profile.level + 1)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 15)
                        
                        // Progress
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.breadBrown)
                            .frame(width: geometry.size.width * profile.progressToNextLevel, height: 15)
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

struct BadgeCard: View {
    let badge: Badge
    
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
    }
}

struct BadgeIconView: View {
    let badge: Badge
    
    var body: some View {
        let iconSize: CGFloat = 80
        let circleSize: CGFloat = 180
        let bgOpacity: Double = 0.2
        
        return Image(systemName: badge.icon)
            .font(.system(size: iconSize))
            .foregroundColor(badge.color)
            .padding()
            .background(
                Circle()
                    .fill(badge.color.opacity(bgOpacity))
                    .frame(width: circleSize, height: circleSize)
            )
            .padding(.top, 30)
    }
}

struct BadgeUnlockOverlay: View {
    let isUnlocked: Bool
    
    var body: some View {
        if !isUnlocked {
            return AnyView(
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
            return AnyView(EmptyView())
        }
    }
}
