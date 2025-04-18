import SwiftUI

struct LoginView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var rememberMe: Bool = false
    @State private var isShowingMainApp: Bool = false
    
    var body: some View {
        NavigationView {
            // This ZStack ensures the background color covers the entire screen
            ZStack {
                Color.breadBeige.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Logo
                    Image("bread.ai logo no background")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200)
                        .padding(.top, 40)
                    
                    Spacer()
                    
                    // Login Form
                    VStack(spacing: 20) {
                        Text("Sign In")
                            .font(.title.bold())
                            .foregroundColor(.breadBrown)
                        
                        TextField("Username", text: $username)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                            .padding(.horizontal)
                        
                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                            .padding(.horizontal)
                        
                        HStack {
                            Toggle("Remember me", isOn: $rememberMe)
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Button("Forgot Password?") {
                                // Forgot password action
                            }
                            .foregroundColor(.breadBrown)
                            .font(.footnote)
                        }
                        .padding(.horizontal)
                        
                        Button(action: {
                            // Perform login validation
                            isShowingMainApp = true
                        }) {
                            Text("CONTINUE")
                                .font(.body.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.breadBrown)
                                .cornerRadius(8)
                        }
                        .padding(.horizontal)
                        
                        HStack {
                            Text("Don't have an account?")
                                .foregroundColor(.gray)
                            
                            Button("Sign Up") {
                                // Sign up action
                            }
                            .foregroundColor(.breadBrown)
                            .font(.body.bold())
                        }
                        .padding(.top, 10)
                    }
                    .padding(.bottom, 40)
                    
                    Spacer()
                }
                // Remove redundant background since we're using ZStack
                .navigationBarHidden(true)
                .fullScreenCover(isPresented: $isShowingMainApp) {
                    MainTabView()
                }
            }
        }
    }
}

// Preview
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}

#if compiler(>=5.9)
#Preview {
    LoginView()
}
#endif
