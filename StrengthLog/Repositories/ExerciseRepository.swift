import Foundation
import SwiftData

protocol ExerciseRepository {
    @MainActor
    func fetchExercises() throws -> [ExerciseDefinition]
    @MainActor
    func fetchCategories() throws -> [WorkoutCategoryTag]
    @MainActor
    func fetchMajorMuscleGroups() throws -> [MajorMuscleGroup]
    @MainActor
    func delete(_ exercise: ExerciseDefinition) throws
}

@MainActor
final class SwiftDataExerciseRepository: ExerciseRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchExercises() throws -> [ExerciseDefinition] {
        let descriptor = FetchDescriptor<ExerciseDefinition>(
            sortBy: [SortDescriptor(\ExerciseDefinition.name)])
        return try context.fetch(descriptor)
    }

    func fetchCategories() throws -> [WorkoutCategoryTag] {
        let descriptor = FetchDescriptor<WorkoutCategoryTag>(
            sortBy: [SortDescriptor(\WorkoutCategoryTag.name)])
        return try context.fetch(descriptor)
    }

    func fetchMajorMuscleGroups() throws -> [MajorMuscleGroup] {
        let descriptor = FetchDescriptor<MajorMuscleGroup>(
            sortBy: [SortDescriptor(\MajorMuscleGroup.name)])
        return try context.fetch(descriptor)
    }

    func delete(_ exercise: ExerciseDefinition) throws {
        context.delete(exercise)
        try context.save()
    }
}

final class UnimplementedExerciseRepository: ExerciseRepository {
    func fetchExercises() throws -> [ExerciseDefinition] {
        fatalError("ExerciseRepository not injected")
    }

    func fetchCategories() throws -> [WorkoutCategoryTag] {
        fatalError("ExerciseRepository not injected")
    }

    func fetchMajorMuscleGroups() throws -> [MajorMuscleGroup] {
        fatalError("ExerciseRepository not injected")
    }

    func delete(_ exercise: ExerciseDefinition) throws {
        fatalError("ExerciseRepository not injected")
    }
}
