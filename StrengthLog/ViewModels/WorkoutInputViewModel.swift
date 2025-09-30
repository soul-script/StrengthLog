import Foundation
import SwiftUI
import OSLog

@MainActor
final class WorkoutInputViewModel: ObservableObject {
    struct TemporarySetEntry: Identifiable {
        let id = UUID()
        var measurement: WeightMeasurement?
        var reps: Int

        var isWeighted: Bool {
            measurement != nil
        }

        func weight(in unit: WeightUnit) -> Double? {
            measurement?.value(in: unit)
        }

        var oneRepMaxKilograms: Double {
            guard let measurement else { return 0 }
            return calculateOneRepMax(weight: measurement.kilograms, reps: reps)
        }

        func displayOneRepMax(in unit: WeightUnit) -> Int? {
            guard measurement != nil else { return nil }
            return Int(convertOneRepMax(oneRepMaxKilograms, to: unit))
        }
    }

    @Published var workoutDate: Date = Date.todayAtMidnight
    @Published private(set) var sets: [TemporarySetEntry] = []
    @Published var weightInput: String = ""
    @Published var repsInput: String = ""
    @Published var isBodyweightExercise = false
    @Published private(set) var saveErrorMessage: String?
    @Published private(set) var isSaving = false

    private let exercise: ExerciseDefinition
    private var workoutRepository: WorkoutRepository?
    private let logger = Logger(subsystem: "com.adityamishra.StrengthLog", category: "WorkoutInputViewModel")

    init(exercise: ExerciseDefinition) {
        self.exercise = exercise
    }

    func configureIfNeeded(repository: WorkoutRepository) {
        guard workoutRepository == nil else { return }
        workoutRepository = repository
    }

    func resetError() {
        saveErrorMessage = nil
    }

    func setBodyweight(_ isBodyweight: Bool) {
        isBodyweightExercise = isBodyweight
        if isBodyweight {
            weightInput = ""
        }
    }

    func isValidInput(preferredUnit: WeightUnit) -> Bool {
        guard let reps = Int(repsInput.trimmingCharacters(in: .whitespaces)), reps > 0 else {
            return false
        }

        if isBodyweightExercise {
            return true
        }

        guard let rawWeight = Double(weightInput.trimmingCharacters(in: .whitespaces)) else {
            return false
        }

        return WeightConversionService.shared.measurement(from: rawWeight, unit: preferredUnit) != nil
    }

    func addSet(preferredUnit: WeightUnit) {
        guard let reps = Int(repsInput.trimmingCharacters(in: .whitespaces)), reps > 0 else {
            return
        }

        let measurement: WeightMeasurement?
        if isBodyweightExercise {
            measurement = nil
        } else {
            guard
                let rawWeight = Double(weightInput.trimmingCharacters(in: .whitespaces)),
                let normalized = WeightConversionService.shared.measurement(from: rawWeight, unit: preferredUnit)
            else {
                return
            }
            measurement = normalized
        }

        let newSet = TemporarySetEntry(measurement: measurement, reps: reps)
        sets.append(newSet)
        weightInput = ""
        repsInput = ""
    }

    func deleteSet(at offsets: IndexSet) {
        sets.remove(atOffsets: offsets)
    }

    func totalVolume(in unit: WeightUnit) -> Double {
        sets.reduce(0) { total, set in
            if let weight = set.weight(in: unit) {
                return total + weight * Double(set.reps)
            }
            return total + Double(set.reps)
        }
    }

    func persistWorkout(preferredUnit: WeightUnit, dismiss: () -> Void) {
        resetError()
        guard let repository = workoutRepository else {
            logger.error("Workout repository missing; cannot save")
            saveErrorMessage = "Unable to save workout."
            return
        }

        guard !sets.isEmpty else {
            saveErrorMessage = "Add at least one set before saving."
            return
        }

        let inputs = sets.map { WorkoutSetInput(measurement: $0.measurement, reps: $0.reps) }
        isSaving = true
        do {
            _ = try repository.createWorkout(for: exercise, on: workoutDate, sets: inputs)
            dismiss()
        } catch {
            logger.error("Failed to save workout: \(String(describing: error))")
            saveErrorMessage = "Failed to save workout. Please try again."
        }
        isSaving = false
    }
}
