//
//  Exercise.swift
//  TrackYourSets
//
//  Created by Christopher Gonzalez on 2025-10-06.
//

import Foundation
import FirebaseFirestore

struct Exercise: Identifiable, Codable {
    @DocumentID var id: String? // ID generado por Firestore
    var name : String
    var muscleGroups: MuscleGroup
    var photoURL: String?
    var createdAt: Date
    var updatedAt: Date
}
