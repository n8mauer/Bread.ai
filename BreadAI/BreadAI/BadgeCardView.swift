import SwiftUI

struct BadgeCardView: View {
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

struct BadgeCategoryHeaderView: View {
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

struct UserProfileHeaderView: View {
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

#if compiler(>=5.9)
#Preview {
    VStack {
        BadgeCardView(badge: Badge(
            name: "The Rise Master",
            description: "Perfect your bread rise technique",
            icon: "arrow.up.and.down",
            color: .orange,
            isUnlocked: true,
            points: 50
        ))
        
        BadgeCardView(badge: Badge(
            name: "Crust King/Queen",
            description: "Create perfect golden crusts",
            icon: "allergens",
            color: .brown,
            isUnlocked: false,
            points: 100
        ))
    }
    .padding()
    .previewLayout(.sizeThatFits)
    .background(Color.breadBeige)
}
#endif