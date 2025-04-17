import SwiftUI

// Custom brown color for iOS 14+ compatibility
extension Color {
    static let breadBrown = Color(red: 0.6, green: 0.4, blue: 0.2)
}

struct ContentView: View {
    @State private var breadQuery: String = ""
    @State private var response: String = ""
    @State private var isLoading: Bool = false
    
    var body: some View {
        VStack {
            Text("Bread.ai")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            Image(systemName: "birthday.cake")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.breadBrown)
                .padding()
            
            TextField("Ask about bread...", text: $breadQuery)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(isLoading)
            
            Button(action: {
                if !breadQuery.isEmpty {
                    isLoading = true
                    BreadService.shared.askAboutBread(query: breadQuery) { result in
                        response = result
                        isLoading = false
                    }
                }
            }) {
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
            }
            .disabled(breadQuery.isEmpty || isLoading)
            .padding()
            
            if !response.isEmpty {
                ScrollView {
                    Text(response)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

#if compiler(>=5.9)
#Preview {
    ContentView()
}
#endif
