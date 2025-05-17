import Foundation
import SwiftData

@Model
final class SetEntry: Identifiable {
    @Attribute(.unique) var id: UUID
    var weight: Double
    var reps: Int
    var calculatedOneRepMax: Double
    
    @Relationship(deleteRule: .nullify) var workoutRecord: WorkoutRecord?
    
    init(weight: Double, reps: Int, workoutRecord: WorkoutRecord? = nil) {
        self.id = UUID()
        self.weight = weight
        self.reps = reps
        self.workoutRecord = workoutRecord
        
        // Apply the 1RM calculation based on reps
        if reps == 1 {
            self.calculatedOneRepMax = weight
        } else {
            self.calculatedOneRepMax = weight * (1 + Double(reps) / 30.0)
        }
    }
    
    // Update one-rep max when weight or reps change
    func updateOneRepMax() {
        self.calculatedOneRepMax = calculateOneRepMax(weight: weight, reps: reps)
    }
    
    // Epley formula: 1RM = weight × (1 + reps / 30)
    private func calculateOneRepMax(weight: Double, reps: Int) -> Double {
        return weight * (1 + Double(reps) / 30)
    }
} 