//
//  ExercisesViewModel.swift
//  TrackYourSets
//
//  Created by Christopher Gonzalez on 2025-10-06.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseStorage
import UIKit

@MainActor
final class ExercisesViewModel: ObservableObject {
    @Published var exercises: [Exercise] = []
    @Published var grouped: [MuscleGroup: [Exercise]] = [:]
    @Published var errorMessage: String? = nil
    @Published var isLoading: Bool = false

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var uid: String?

    // Empieza a escuchar cambios en users/{uid}/exercises
    func start(for uid: String) {
        guard self.uid != uid else { return }   // ya estamos escuchando ese uid
        stop()
        self.uid = uid
        isLoading = true
        errorMessage = nil

        let ref = db.collection("users").document(uid).collection("exercises")
            .order(by: "name", descending: false)

        listener = ref.addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }
            if let error {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                return
            }
            guard let docs = snapshot?.documents else {
                self.exercises = []
                self.grouped = [:]
                self.isLoading = false
                return
            }
            let items: [Exercise] = docs.compactMap { try? $0.data(as: Exercise.self) }
            self.exercises = items
            self.grouped = Dictionary(grouping: items, by: { $0.muscleGroups })
            self.isLoading = false
        }
    }

    func stop() {
        listener?.remove()
        listener = nil
        uid = nil
        exercises = []
        grouped = [:]
        errorMessage = nil
        isLoading = false
    }
}


extension ExercisesViewModel {
    /// Crea un ejercicio con nombre, grupo y foto opcional (imageData puede ser nil)
    func createExercise(uid: String, name: String, group: MuscleGroup, imageData: Data?) async throws {
        // 1) Crear doc para obtener ID
        let col = db.collection("users").document(uid).collection("exercises")
        let docRef = col.document() // ID automático

        var photoURL: String? = nil

        // 2) Subir imagen (si existe)
        if let data = imageData, !data.isEmpty {
            let storageRef = Storage.storage().reference()
                .child("users/\(uid)/exercises/\(docRef.documentID).jpg")
            // subimos con metadata simple
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            _ = try await storageRef.putDataAsync(data, metadata: metadata)
            photoURL = try await (storageRef.downloadURL()).absoluteString
        }

        // 3) Escribir documento completo
        let now = Date()
        let exercise = Exercise(
            id: docRef.documentID,
            name: name,
            muscleGroups: group,
            photoURL: photoURL,
            createdAt: now,
            updatedAt: now
        )

        try docRef.setData(from: exercise)
        // el listener actualizará `exercises` y `grouped` automáticamente
    }
    
    func updateExercise(uid: String,
                            exercise: Exercise,
                            newName: String,
                            newImageData: Data?) async throws {
            guard let id = exercise.id else { return }
            let docRef = db.collection("users").document(uid).collection("exercises").document(id)

            var photoURL = exercise.photoURL

            // Si llega una foto nueva, súbela y (opcional) borra la anterior
            if let data = newImageData, !data.isEmpty {
                // 1) subir nueva
                let storageRef = Storage.storage().reference().child("users/\(uid)/exercises/\(id).jpg")
                let meta = StorageMetadata(); meta.contentType = "image/jpeg"
                _ = try await storageRef.putDataAsync(data, metadata: meta)
                let newURL = try await (storageRef.downloadURL()).absoluteString

                // 2) actualizar referencia
                photoURL = newURL
            }

            try await docRef.updateData([
                "name": newName,
                "photoURL": photoURL as Any,
                "updatedAt": Date()
            ])
            // El listener actualizará la lista solo
        }
    
    
    // Borra el ejercicio y su foto (si tiene).
    func deteleExercise(uid: String, exercises: Exercise) async throws {
        guard let id = exercises.id else { return }
        let docRef = db.collection("users").document(uid).collection("exercises").document(id)
        
        // Borra foto en Storage si existe
        if let url = exercises.photoURL, !url.isEmpty {
            // reference(forURL:) acepta url https del download
            let storageRef = Storage.storage().reference(forURL: url)
            do { try await storageRef.delete()} catch { print("Error al borrar foto de Storage: \(error)")
            }
            
            try await docRef.delete()
            // El listener sacará el item de la lista
        }
    }

    /// Utilidad: comprime una UIImage en JPEG (0.8 por defecto)
    func jpegData(from image: UIImage, quality: CGFloat = 0.8) -> Data? {
        image.jpegData(compressionQuality: quality)
    }
    
    
}

