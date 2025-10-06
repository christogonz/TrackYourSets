//
//  AuthView.swift
//  TrackYourSets
//
//  Created by Christopher Gonzalez on 2025-10-03.
//

import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    
    @State private var email  = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var isRegistering = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                RadialGradient(
                    colors: [Color.accentColor.opacity(0.03), Color.clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 300,
                )
                .blur(radius: 60)
                .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    Image(systemName: "figure.step.training.circle")
                        .font(.system(size: 100, weight: .light, design: .rounded))
                    
                    Text("Trackie")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color.accentColor)
                        
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text(isRegistering ? "Sign Up" : "Sign In")
                                .foregroundStyle(Color.accentColor)
                            
                            Text("with email")
                        }
                        
                        Text("Enter your Credentials to start")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom)
                    
                    
                    MyTextField(
                        icon: "envelope",
                        placeholder: "Email",
                        text: $email
                    )
                    
                    MyTextField(
                        icon: "lock",
                        placeholder: "Password",
                        text: $password
                    )
                    
                    if isRegistering {
                        MyTextField(
                            icon: "person",
                            placeholder: "Name",
                            text: $displayName
                        )
                    }
                    
                    Button {
                        Task {
                            if isRegistering {
                                await viewModel.signUp(email: email, password: password, displayName: displayName)
                            } else {
                                await viewModel.signIn(email: email, password: password)
                            }
                        }
                    } label: {
                        Text(isRegistering ? "Create Account" : "Sign In")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.semibold)
                            .padding()
                            .glassEffect(.regular.interactive())
                    }
                    .disabled(viewModel.isLoading)
                    
                    Divider()
                    
                    Button {
                        withAnimation {
                            isRegistering.toggle()
                        }
                    } label: {
                        HStack {
                            Text(isRegistering ? "Already have an account?" : "Dont have an account?")
                                .foregroundStyle(.text)
                            
                            Text(isRegistering ? "Sign in" : "Sign Up")
                                .font(.footnote)
                                .foregroundStyle(.accent)
                        }
                    }
                    
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                            .padding(.top, 8)
                    }
                    Spacer()
                    
                    SignInWithAppleButton(.signIn) {
                        request in
                        viewModel.configureAppleRequest(request)
                    } onCompletion: { result in
                        Task { await viewModel.handleAppleCompletion(result)}
                    }
                    .frame(maxWidth: .infinity,maxHeight: 50)
                    .fontWeight(.semibold)
                    .clipShape(Capsule())
                    
//                    .frame(maxWidth: .infinity, maxHeight: 50)
//                    .clipShape(Capsule())
//                    .padding(.top, 4)
                    
                    
                    Button {
                        Task {
                            await viewModel.signInWithGoogle()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "g.circle")
                            Text("Sign in with Google")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity,maxHeight: 50)
                        .background(.white)
                        .foregroundStyle(.black)
                        .fontWeight(.semibold)
                        .clipShape(Capsule())

                        
                        
                        
                    }
                }
                .padding()
            }
            .fontDesign(.rounded)
            .background(Color.bg)
            
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthViewModel())
}
