import SwiftUI

private struct ExerciseRepositoryKey: EnvironmentKey {
    static let defaultValue: ExerciseRepository = UnimplementedExerciseRepository()
}

private struct WorkoutRepositoryKey: EnvironmentKey {
    static let defaultValue: WorkoutRepository = UnimplementedWorkoutRepository()
}

private struct SettingsRepositoryKey: EnvironmentKey {
    static let defaultValue: SettingsRepository = UnimplementedSettingsRepository()
}

extension EnvironmentValues {
    var exerciseRepository: ExerciseRepository {
        get { self[ExerciseRepositoryKey.self] }
        set { self[ExerciseRepositoryKey.self] = newValue }
    }

    var workoutRepository: WorkoutRepository {
        get { self[WorkoutRepositoryKey.self] }
        set { self[WorkoutRepositoryKey.self] = newValue }
    }

    var settingsRepository: SettingsRepository {
        get { self[SettingsRepositoryKey.self] }
        set { self[SettingsRepositoryKey.self] = newValue }
    }
}
