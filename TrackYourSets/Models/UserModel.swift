//
//  UserModel.swift
//  TrackYourSets
//
//  Created by Christopher Gonzalez on 2025-10-02.
//

import Foundation
import FirebaseFirestore

struct UserModel: Identifiable, Codable {
    @DocumentID var id: String? //ID del documento (el mismo que el UID del usuario)

    var email: String
    var displayName: String
    var profileImageURL: String?
    var createdAt: Date?
}
