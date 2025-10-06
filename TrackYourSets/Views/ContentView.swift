//
//  ContentView.swift
//  TrackYourSets
//
//  Created by Christopher Gonzalez on 2025-10-02.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            if authViewModel.currentUser != nil {
                MainAppView()
            } else {
                AuthView()
            }
        }
    }
}

#Preview {
    ContentView()
}
