//
//  EditExerciseSheet.swift
//  TrackYourSets
//
//  Created by Christopher Gonzalez on 2025-10-08.
//

import SwiftUI
import PhotosUI

struct EditExerciseSheet: View {
    let uid: String
    let original: Exercise
    @ObservedObject var vm: ExercisesViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var pickedItem: PhotosPickerItem?
    @State private var pickedImage: UIImage?
    @State private var isSaving = false
    @State private var error: String?
    
    init(uid: String, exercise: Exercise, vm: ExercisesViewModel) {
        self.uid = uid
        self.original = exercise
        self.vm = vm
        _name = State(initialValue: exercise.name)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Excersises name", text: $name)
                }
                Section("Image") {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8).fill(.gray.opacity(0.12))
                            if let img = pickedImage {
                                Image(uiImage: img).resizable().scaledToFill()
                            } else if let urlStr = original.photoURL, let url = URL(string: urlStr) {
                                AsyncImage(url: url) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    ProgressView()
                                }
                            } else {
                                Text(original.muscleGroups.emoji).font(.largeTitle)
                            }
                        }
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        PhotosPicker(selection: $pickedItem, matching: .images) {
                            Label("Choose new image", systemImage: "photo.on.rectangle")
                        }
                        .onChange(of: pickedItem) { _, item in
                            Task {
                                if let data = try? await item?.loadTransferable(type: Data.self),
                                   let img = UIImage(data: data) {
                                    pickedImage = img
                                }
                            }
                        }
                    }
                    Button("Remove Image") { pickedImage = nil }
                }
                
                if let error { Text(error).foregroundStyle(.red).font(.caption)}
            }
            .navigationTitle("Edit Workout")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(isSaving || name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        
    }
    
    private func save() async {
        isSaving = true; defer { isSaving = false }
        do {
            let data = pickedImage.flatMap { vm.jpegData(from: $0, quality: 0.8) }
            try await vm.updateExercise(uid: uid, exercise: original, newName: name.trimmingCharacters(in: .whitespaces), newImageData: data)
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
    
}



#Preview {
    // Mock de VM y Exercise para el preview
    let vm = ExercisesViewModel()
    let mockExercise = Exercise(
        id: "preview-ex-1",
        name: "Back Squat",
        muscleGroups: .legs,
        photoURL: nil,
        createdAt: Date(),
        updatedAt: Date()
    )
    return EditExerciseSheet(uid: "preview-uid", exercise: mockExercise, vm: vm)
}
