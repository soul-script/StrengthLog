import Foundation
import SwiftData

@Model
final class WorkoutRecord {
    @Attribute(.unique) var id: UUID
    var date: Date
    
    @Relationship(deleteRule: .nullify) var exerciseDefinition: ExerciseDefinition?
    @Relationship(deleteRule: .cascade) var setEntries: [SetEntry] = []
    
    init(date: Date = Date(), exerciseDefinition: ExerciseDefinition? = nil) {
        self.id = UUID()
        self.date = date
        self.exerciseDefinition = exerciseDefinition
    }
    
    var totalVolume: Double {
        setEntries.reduce(0) { $0 + $1.weight * Double($1.reps) }
    }
}

// MARK: - Phase 5: Basic Progress Visualization
extension WorkoutRecord {
    var bestOneRepMaxInSession: Double {
        guard !setEntries.isEmpty else { return 0.0 }
        return setEntries.reduce(0.0) { max($0, $1.calculatedOneRepMax) }
    }
} 