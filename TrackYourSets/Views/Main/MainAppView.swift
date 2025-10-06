//
//  MainAppView.swift
//  TrackYourSets
//
//  Created by Christopher Gonzalez on 2025-10-03.
//

import SwiftUI

struct MainAppView: View {
    @EnvironmentObject var  authViewModel: AuthViewModel
    
    var body: some View {
        TabView {
            Tab.init("Home", systemImage: "house") {
                HomeView()
            }
            
            Tab.init("Tracking", systemImage: "list.bullet.clipboard") {
                TrackingView()
            }
            
            Tab.init("Workouts", systemImage: "figure.strengthtraining.traditional") {
                WorkoutsView()
            }
            
            Tab.init("Settings", systemImage: "gearshape", role: .search) {
                SettingsView()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        
        
    }
}

#Preview {
    MainAppView()
}
