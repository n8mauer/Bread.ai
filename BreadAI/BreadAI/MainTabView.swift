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
    @ObservedObject private var timerManager = TimerManager.shared
    @State private var showingCustomTimer = false
    @State private var customMinutes = ""
    @State private var customTimerName = ""

    var body: some View {
        ZStack {
            Color.breadBeige.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    Text("Timer")
                        .font(.largeTitle.bold())
                        .foregroundColor(.breadBrown)
                        .padding(.top, 15)

                    Image("bread.ai logo no background")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100)
                        .padding(.bottom, 10)

                    // Active Timer Display
                    if timerManager.timeRemaining > 0 || timerManager.isRunning {
                        ActiveTimerCard(timerManager: timerManager)
                            .padding(.horizontal)
                    } else {
                        // Preset Timers
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Preset Timers")
                                .font(.title2.bold())
                                .foregroundColor(.breadBrown)
                                .padding(.horizontal)

                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(TimerManager.presets) { preset in
                                    PresetTimerButton(preset: preset)
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Custom Timer Button
                        Button(action: { showingCustomTimer = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                Text("Custom Timer")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.breadBrown)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                    }

                    Spacer()
                }
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showingCustomTimer) {
            CustomTimerSheet(
                minutes: $customMinutes,
                timerName: $customTimerName,
                onStart: {
                    if let mins = Int(customMinutes), mins > 0 {
                        let duration = TimeInterval(mins * 60)
                        let name = customTimerName.isEmpty ? "Custom Timer" : customTimerName
                        timerManager.start(duration: duration, name: name)
                        showingCustomTimer = false
                        customMinutes = ""
                        customTimerName = ""
                    }
                }
            )
        }
    }
}

struct ActiveTimerCard: View {
    @ObservedObject var timerManager: TimerManager

    var body: some View {
        VStack(spacing: 20) {
            // Timer name
            Text(timerManager.timerName)
                .font(.title2.bold())
                .foregroundColor(.breadBrown)

            // Circular progress
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    .frame(width: 250, height: 250)

                Circle()
                    .trim(from: 0, to: CGFloat(timerManager.progress))
                    .stroke(Color.breadBrown, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 250, height: 250)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: timerManager.progress)

                VStack(spacing: 5) {
                    Text(timerManager.timeRemaining.formattedTime)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.breadBrown)
                        .monospacedDigit()

                    Text(timerManager.isRunning ? "Running" : "Paused")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }

            // Control buttons
            HStack(spacing: 20) {
                if timerManager.isRunning {
                    Button(action: { timerManager.pause() }) {
                        Label("Pause", systemImage: "pause.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(12)
                    }
                } else {
                    Button(action: { timerManager.resume() }) {
                        Label("Resume", systemImage: "play.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                }

                Button(action: { timerManager.reset() }) {
                    Label("Reset", systemImage: "arrow.clockwise")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct PresetTimerButton: View {
    let preset: TimerPreset
    @ObservedObject private var timerManager = TimerManager.shared

    var body: some View {
        Button(action: {
            timerManager.start(duration: preset.duration, name: preset.name)
        }) {
            VStack(spacing: 12) {
                Image(systemName: preset.icon)
                    .font(.system(size: 40))
                    .foregroundColor(preset.color)

                Text(preset.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(preset.duration.shortFormattedTime)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white.opacity(0.9))
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
}

struct CustomTimerSheet: View {
    @Binding var minutes: String
    @Binding var timerName: String
    let onStart: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.breadBeige.ignoresSafeArea()

                VStack(spacing: 25) {
                    Text("Create Custom Timer")
                        .font(.title2.bold())
                        .foregroundColor(.breadBrown)
                        .padding(.top)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Timer Name")
                            .font(.headline)
                            .foregroundColor(.breadBrown)

                        TextField("e.g., Final Proof", text: $timerName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                    }
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Duration (minutes)")
                            .font(.headline)
                            .foregroundColor(.breadBrown)

                        TextField("Enter minutes", text: $minutes)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .padding(.horizontal)
                    }
                    .padding(.horizontal)

                    Button(action: {
                        onStart()
                    }) {
                        Text("Start Timer")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                (Int(minutes) ?? 0) > 0 ? Color.breadBrown : Color.gray
                            )
                            .cornerRadius(12)
                    }
                    .disabled((Int(minutes) ?? 0) <= 0)
                    .padding(.horizontal)

                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.breadBrown)
                }
            }
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
