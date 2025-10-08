//
//  ExerciseAvatar.swift
//  TrackYourSets
//
//  Created by Christopher Gonzalez on 2025-10-06.
//

import SwiftUI

struct ExerciseAvatar: View {
    let photoURL: String?
    let fallback: String
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.15))
            if let urlString = photoURL, let url = URL(string: urlString) {
                // Para ahora, usa AsyncImage. Luego optimizamos cache.
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Text(fallback)
                        .font(.title3)
                        .opacity(0.6)
                }
            } else {
                Text(fallback)
                    .font(.title3)
                    .opacity(0.6)
            }
        }
    }
}

#Preview {
    ExerciseAvatar(photoURL: nil, fallback: "EX")
}
