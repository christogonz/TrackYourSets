//
//  MuscleGroup.swift
//  TrackYourSets
//
//  Created by Christopher Gonzalez on 2025-10-06.
//

import Foundation

enum MuscleGroup: String, CaseIterable, Codable, Identifiable {
    case legs = "Legs"
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case core = "Core"
    case glutes = "Glutes"
    case calves = "Calves"
    
    var id: String { rawValue }
    
    var emoji: String {
            switch self {
            case .legs: "🦵"
            case .chest: "🫁"
            case .back: "🦴"
            case .shoulders: "🏋️"
            case .biceps: "💪"
            case .triceps: "🛠️"
            case .core: "🧱"
            case .glutes: "🍑"
            case .calves: "🧦"
            }
        }}
