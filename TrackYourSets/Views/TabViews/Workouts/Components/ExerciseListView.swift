//
//  ExerciseListView.swift
//  TrackYourSets
//
//  Created by Christopher Gonzalez on 2025-10-06.
//

import SwiftUI

struct ExerciseListView: View {
    let group: MuscleGroup
    @ObservedObject var vm: ExercisesViewModel
    @EnvironmentObject var authVm: AuthViewModel

    @State private var showAdd = false
    @State private var editTarget: Exercise?    // para la sheet de editar
    @State private var isDeleting = false       // opcional para deshabilitar mientras borra
    @State private var localError: String?

    var filtered: [Exercise] { vm.grouped[group] ?? [] }

    var body: some View {
        List {
            if filtered.isEmpty {
                ContentUnavailableView(
                    "No exercises in this group",
                    systemImage: "list.bullet",
                    description: Text("Add some exercises to this group to get started!")
                )
            } else {
                ForEach(filtered) { ex in
                    HStack(spacing: 12) {
                        ExerciseAvatar(photoURL: ex.photoURL, fallback: group.emoji)
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading) {
                            Text(ex.name).font(.headline)
                            Text(group.rawValue).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button("Edit") { editTarget = ex }
                            .tint(.blue)

                        Button(role: .destructive) {
                            Task { await delete(ex) }
                        } label: {
                            Text("Delete")
                        }
                        .disabled(isDeleting)
                    }
                }
            }
        }
        .navigationTitle(group.rawValue)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showAdd) {
            if let uid = authVm.currentUser?.id {
                AddExerciseSheet(vm: vm, uid: uid, group: group)
                    .presentationDetents([.medium, .large])
            } else {
                Text("inicia sesion").padding()
            }
        }
        .sheet(item: $editTarget, onDismiss: { editTarget = nil }) { exercise in
            if let uid = authVm.currentUser?.id {
                EditExerciseSheet(uid: uid, exercise: exercise, vm: vm)
                    .presentationDetents([.medium, .large])
            } else {
                Text("inicia sesion").padding()
            }
        }
        .alert("Error", isPresented: .constant(localError != nil)) {
            Button("OK") { localError = nil }
        } message: {
            Text(localError ?? "")
        }
    }

    private func delete(_ ex: Exercise) async {
        guard let uid = authVm.currentUser?.id else { return }
        isDeleting = true; defer { isDeleting = false }
        do {
            // Verify actual API name in ExercisesViewModel; change to deleteExercise if that's the correct one.
            try await vm.deteleExercise(uid: uid, exercises: ex)
        } catch {
            localError = error.localizedDescription
        }
    }
}


//struct ExerciseListView: View {
//    let group: MuscleGroup
//    @ObservedObject var vm: ExercisesViewModel
//    @EnvironmentObject var authVm: AuthViewModel
//    
//    @State private var showAdd = false
//    @State private var editTarget = Exercise?
//    @State private var isDeleting = false
//    @State private var localError = String?
//    
//    var filtered: [Exercise] {
//        vm.grouped[group] ?? []
//    }
//    
//    var body: some View {
//        List {
//            if filtered.isEmpty {
//                ContentUnavailableView(
//                    "No exercises in this group",
//                    systemImage: "list.bullet",
//                    description: Text("Add some exercises to this group to get started!")
//                )
//            } else {
//                ForEach(filtered, id: \.id) { ex in
//                    HStack(spacing: 12) {
//                        ExerciseAvatar(photoURL: ex.photoURL, fallback: group.emoji)
//                            .frame(width: 40, height: 40)
//                            .clipShape(RoundedRectangle(cornerRadius: 8))
//                        
//                        VStack(alignment: .leading) {
//                            Text(ex.name).font(.headline)
//                            Text(group.rawValue).font(.caption).foregroundStyle(.secondary)
//                        }
//                    }
//                }
//            }
//        }
//        .navigationTitle(group.rawValue)
//        .toolbar {
//            ToolbarItem(placement: .topBarTrailing) {
//                Button {
//                    showAdd = true
//                } label: {
//                    Image(systemName: "plus")
//                }
//            }
//        }
//        .sheet(isPresented: $showAdd) {
//            if let uid = authVm.currentUser?.id {
//                AddExerciseSheet(
//                    vm: vm,
//                    uid: uid,
//                    group: group,
//                )
//                .presentationDetents([.medium, .large])
//            } else {
//                Text("inicia sesion").padding()
//            }
//        }
//        .sheet(item: $editTarget, onDismiss: { editTarget = nil }) { exercise in
//            
//            if  let uid = authVm.currentUser?.id {
//                EditExerciseSheet(uid: uid, exercise: exercise, vm: vm)
//                    .presentationDetents([.medium, .large])
//            } else {
//                Text("Sign In").padding()
//            }
//        }
//        .alert("error", isPresented: .constant(localError != nil)) {
//            Button("OK") {
//                localError = nil
//            } message: {
//                Text(localError ?? "")
//            }
//        }
//    }
//    
//    private func delete(_ ex: Exercise) async {
//        guard let uid = authVm.currentUser?.id else { return }
//        isDeleting = true; defer { isDeleting = false }
//        do {
//            try await vm.deleteExercise(uid: uid, exercise: ex)
//        } catch {
//            localError = error.localizedDescription
//        }
//    }
//}

#Preview {
    ExerciseListView(group: .chest, vm: ExercisesViewModel())
}
