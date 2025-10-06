//
//  TrackYourSetsApp.swift
//  TrackYourSets
//
//  Created by Christopher Gonzalez on 2025-10-02.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
      FirebaseApp.configure()
    return true
  }
}

@main
struct TrackYourSetsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel =  AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
           ContentView()
                .environmentObject(authViewModel)
                .task {
                    await authViewModel.loadCurrentUser()
                }
                .onOpenURL { url in
                    // Handle Google Sign-In callback via UIScene lifecycle
                    _ = GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
