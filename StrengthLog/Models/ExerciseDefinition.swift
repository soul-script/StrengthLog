import Foundation
import SwiftData

@Model
final class ExerciseDefinition {
    @Attribute(.unique) var id: UUID
    var name: String
    var dateAdded: Date
    
    @Relationship(deleteRule: .cascade) var workoutRecords: [WorkoutRecord] = []
    
    init(name: String, dateAdded: Date = Date()) {
        self.id = UUID()
        self.name = name
        self.dateAdded = dateAdded
    }
} 