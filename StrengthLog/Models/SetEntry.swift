import Foundation
import SwiftData

@Model
final class SetEntry: Identifiable {
    @Attribute(.unique) var id: UUID
    var weight: Double?  // Make weight optional for bodyweight exercises
    var reps: Int
    var calculatedOneRepMax: Double
    
    @Relationship(deleteRule: .nullify) var workoutRecord: WorkoutRecord?
    
    init(weight: Double? = nil, reps: Int, workoutRecord: WorkoutRecord? = nil) {
        self.id = UUID()
        self.weight = weight
        self.reps = reps
        self.workoutRecord = workoutRecord
        
        // Apply the 1RM calculation based on reps
        // For bodyweight exercises (no weight), 1RM calculation doesn't apply
        if let weight = weight {
            if reps == 1 {
                self.calculatedOneRepMax = weight
            } else {
                self.calculatedOneRepMax = weight * (1 + Double(reps) / 30.0)
            }
        } else {
            // For bodyweight exercises, we don't calculate 1RM
            self.calculatedOneRepMax = 0.0
        }
    }
    
    // Update one-rep max when weight or reps change
    func updateOneRepMax() {
        if let weight = weight {
            self.calculatedOneRepMax = calculateOneRepMax(weight: weight, reps: reps)
        } else {
            self.calculatedOneRepMax = 0.0
        }
    }
} 