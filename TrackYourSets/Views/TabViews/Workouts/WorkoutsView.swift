//
//  WorkoutsView.swift
//  TrackYourSets
//
//  Created by Christopher Gonzalez on 2025-10-06.
//

import SwiftUI

struct WorkoutsView: View {
    @EnvironmentObject var authVm: AuthViewModel
    @StateObject private var vm = ExercisesViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                // Recorremos todos los grupos conocidos
                ForEach(MuscleGroup.allCases) { group in
                    let count = vm.grouped[group]?.count ?? 0
                    
                    NavigationLink(value: group) {
                        HStack {
                            Text(group.emoji)
                            Text(group.rawValue)
                            Spacer()
                            if count > 0 {
                                Text("(\(count))")
                                    .font(.footnote).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Exercise Library")
            .navigationDestination(for: MuscleGroup.self) { group in
                ExerciseListView(group: group, vm: vm)
            }
            .overlay {
                if vm.isLoading {
                    ProgressView().scaleEffect(1.2)
                }
            }
            .task {
                // Inicia escucha en Firestore cuando haya usuario
                if let uid = authVm.currentUser?.id {
                    vm.start(for: uid)
                }
            }
            
        }
    }
}

#Preview {
    WorkoutsView()
        .environmentObject(AuthViewModel())
}
