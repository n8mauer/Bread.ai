import SwiftUI

struct ContentView: View {
    @State private var breadQuery: String
    @State private var response: String
    @State private var isLoading: Bool
    
    init(breadQuery: String = "", response: String = "", isLoading: Bool = false) {
        self._breadQuery = State(initialValue: breadQuery)
        self._response = State(initialValue: response)
        self._isLoading = State(initialValue: isLoading)
    }
    
    var body: some View {
        ZStack {
            // Set background color for the entire view
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
                    .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
                }
                .disabled(breadQuery.isEmpty || isLoading)
                .padding()
            
                if !response.isEmpty {
                    ScrollView {
                        Text(response)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
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
}

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
    @State private var response: String = "Sourdough bread is made by fermenting dough using naturally occurring wild yeast and lactic acid bacteria. This gives it a slightly sour taste and improved keeping qualities. The starter culture used for sourdough contains a mixture of yeast and bacteria that work together to leaven the bread and develop its characteristic flavor profile."
    @State private var isLoading: Bool = false
    
    var body: some View {
        ContentView(breadQuery: breadQuery, response: response, isLoading: isLoading)
    }
}
#endif
