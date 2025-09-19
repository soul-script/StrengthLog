import Foundation
import SwiftData

@Model
final class MajorMuscleGroup {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var name: String
    var info: String?

    @Relationship(deleteRule: .cascade, inverse: \SpecificMuscle.majorGroup)
    var specificMuscles: [SpecificMuscle] = []

    init(name: String, info: String? = nil) {
        self.id = UUID()
        self.name = name
        self.info = info
    }
}

@Model
final class SpecificMuscle {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var name: String
    var notes: String?

    @Relationship var majorGroup: MajorMuscleGroup?

    init(name: String, majorGroup: MajorMuscleGroup? = nil, notes: String? = nil) {
        self.id = UUID()
        self.name = name
        self.majorGroup = majorGroup
        self.notes = notes
    }
}

@Model
final class WorkoutCategoryTag {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var name: String

    @Relationship(inverse: \ExerciseDefinition.categories)
    var exercises: [ExerciseDefinition] = []

    init(name: String) {
        self.id = UUID()
        self.name = name
    }
}

@Model
final class ExerciseMajorContribution {
    @Attribute(.unique) var id: UUID
    var share: Int

    @Relationship var exercise: ExerciseDefinition?
    @Relationship var majorGroup: MajorMuscleGroup?

    init(exercise: ExerciseDefinition, majorGroup: MajorMuscleGroup, share: Int) {
        self.id = UUID()
        self.exercise = exercise
        self.majorGroup = majorGroup
        self.share = share
    }
}

@Model
final class ExerciseSpecificContribution {
    @Attribute(.unique) var id: UUID
    var share: Int

    @Relationship var exercise: ExerciseDefinition?
    @Relationship var specificMuscle: SpecificMuscle?

    init(exercise: ExerciseDefinition, specificMuscle: SpecificMuscle, share: Int) {
        self.id = UUID()
        self.exercise = exercise
        self.specificMuscle = specificMuscle
        self.share = share
    }
}
