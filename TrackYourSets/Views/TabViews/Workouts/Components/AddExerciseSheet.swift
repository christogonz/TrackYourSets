//
//  AddExerciseSheet.swift
//  TrackYourSets
//
//  Created by Christopher Gonzalez on 2025-10-06.
//

import SwiftUI
import PhotosUI

struct AddExerciseSheet: View {
    @ObservedObject var vm: ExercisesViewModel
    @Environment(\.dismiss) private var dismiss
    
    let uid: String
    let group: MuscleGroup
    
    @State private var name: String = ""
    @State private var pickedImage: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isSaving: Bool = false
    @State private var error: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Squat", text: $name)
                }
                Section("Image (Opcional)") {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8).fill(.gray.opacity(0.12))
                            if let img = selectedImage {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFit()
                            } else {
                                Text(group.emoji).font(.largeTitle)
                            }
                        }
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        PhotosPicker(selection: $pickedImage, matching: .images) {
                            Label("Choose from library", systemImage: "photo.on.rectangle")
                        }
                        .onChange(of: pickedImage) { _, newValue in
                            Task {
                                guard let item = newValue else { return }
                                if let data = try? await item.loadTransferable(type: Data.self),
                                   let img = UIImage(data: data) {
                                    await MainActor.run {
                                        self.selectedImage = img
                                    }
                                }
                            }
                        }
                    }
                }
                
                if let error {
                    Text(error).foregroundStyle(.red).font(.caption)
                }
            }
            .navigationTitle("New Workout")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            await save()
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(isSaving || name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func save() async {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSaving = true; defer { isSaving = false }
        do {
            let data: Data? = {
                if let img = selectedImage { return vm.jpegData(from: img, quality: 0.8) }
                return nil
            }()
            try await vm.createExercise(
                uid: uid,
                name: name.trimmingCharacters(in: .whitespaces),
                group: group,
                imageData: data
            )
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

#Preview {
    // VM “vacío” para preview; no llama a Firestore
    let vm = ExercisesViewModel()
    return AddExerciseSheet(vm: vm, uid: "preview-uid", group: .legs)
}
