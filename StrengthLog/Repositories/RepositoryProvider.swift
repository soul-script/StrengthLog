import Foundation
import SwiftData

@MainActor
final class RepositoryProvider: ObservableObject {
    let exerciseRepository: ExerciseRepository
    let workoutRepository: WorkoutRepository
    let settingsRepository: SettingsRepository

    init(context: ModelContext) {
        self.exerciseRepository = SwiftDataExerciseRepository(context: context)
        self.workoutRepository = SwiftDataWorkoutRepository(context: context)
        self.settingsRepository = SwiftDataSettingsRepository(context: context)
    }
}
