//
//  SettingsView.swift
//  TrackYourSets
//
//  Created by Christopher Gonzalez on 2025-10-06.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var  authViewModel: AuthViewModel
    
    var body: some View {
        VStack {
            Text("Settings View")
            
            Button("Sign Out") {
                Task {
                    await authViewModel.signOut()
                }
            }
            .padding()
            .buttonStyle(.glass)
            .foregroundStyle(.red)
            
        }
    }
}

#Preview {
    SettingsView()
}
