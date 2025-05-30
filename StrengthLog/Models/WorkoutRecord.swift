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
        setEntries.reduce(0) { total, setEntry in
            if let weight = setEntry.weight {
                return total + weight * Double(setEntry.reps)
            } else {
                // For bodyweight exercises, volume is just the number of reps
                return total + Double(setEntry.reps)
            }
        }
    }
}

// MARK: - Phase 5: Basic Progress Visualization
extension WorkoutRecord {
    var bestOneRepMaxInSession: Double {
        guard !setEntries.isEmpty else { return 0.0 }
        // Only consider sets with weight for 1RM calculation
        let weightedSets = setEntries.filter { $0.weight != nil }
        guard !weightedSets.isEmpty else { return 0.0 }
        return weightedSets.reduce(0.0) { max($0, $1.calculatedOneRepMax) }
    }
} 