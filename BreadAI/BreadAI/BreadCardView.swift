import SwiftUI

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

#if compiler(>=5.9)
#Preview {
    BreadCardView(bread: Bread(name: "Sourdough", isSourdough: true))
        .previewLayout(.sizeThatFits)
        .padding()
        .background(Color.breadBeige)
}
#endif