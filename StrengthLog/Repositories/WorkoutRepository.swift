import Foundation
import SwiftData

struct WorkoutSetInput {
    let measurement: WeightMeasurement?
    let reps: Int
}

protocol WorkoutRepository {
    @MainActor
    func fetchAllWorkouts() throws -> [WorkoutRecord]
    @MainActor
    func createWorkout(for exercise: ExerciseDefinition, on date: Date, sets: [WorkoutSetInput]) throws -> WorkoutRecord
    @MainActor
    func appendSet(to workout: WorkoutRecord, input: WorkoutSetInput) throws
    @MainActor
    func update(set: SetEntry, with input: WorkoutSetInput) throws
    @MainActor
    func delete(set: SetEntry, from workout: WorkoutRecord) throws
    @MainActor
    func updateWorkoutDate(_ workout: WorkoutRecord, to newDate: Date) throws
    @MainActor
    func save() throws
}

@MainActor
final class SwiftDataWorkoutRepository: WorkoutRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAllWorkouts() throws -> [WorkoutRecord] {
        let descriptor = FetchDescriptor<WorkoutRecord>(
            sortBy: [SortDescriptor(\WorkoutRecord.date, order: .reverse)])
        return try context.fetch(descriptor)
    }

    func createWorkout(for exercise: ExerciseDefinition, on date: Date, sets: [WorkoutSetInput]) throws -> WorkoutRecord {
        let workout = WorkoutRecord(date: date.midnight, exerciseDefinition: exercise)
        context.insert(workout)
        for input in sets {
            let setEntry = makeSetEntry(from: input, workout: workout)
            workout.setEntries.append(setEntry)
        }
        try context.save()
        return workout
    }

    func appendSet(to workout: WorkoutRecord, input: WorkoutSetInput) throws {
        let setEntry = makeSetEntry(from: input, workout: workout)
        workout.setEntries.append(setEntry)
        try context.save()
    }

    func update(set: SetEntry, with input: WorkoutSetInput) throws {
        if let measurement = input.measurement {
            set.updateWeight(kilograms: measurement.kilograms, pounds: measurement.pounds)
        } else {
            set.updateWeight(kilograms: nil, pounds: nil)
        }
        set.reps = input.reps
        set.updateOneRepMax()
        try context.save()
    }

    func delete(set: SetEntry, from workout: WorkoutRecord) throws {
        if let index = workout.setEntries.firstIndex(where: { $0.id == set.id }) {
            workout.setEntries.remove(at: index)
        }
        context.delete(set)
        try context.save()
    }

    func updateWorkoutDate(_ workout: WorkoutRecord, to newDate: Date) throws {
        workout.date = newDate.midnight
        try context.save()
    }

    func save() throws {
        try context.save()
    }

    private func makeSetEntry(from input: WorkoutSetInput, workout: WorkoutRecord) -> SetEntry {
        let measurement = input.measurement
        return SetEntry(
            weight: measurement?.kilograms,
            weightInPounds: measurement?.pounds,
            reps: input.reps,
            workoutRecord: workout
        )
    }
}

final class UnimplementedWorkoutRepository: WorkoutRepository {
    func fetchAllWorkouts() throws -> [WorkoutRecord] {
        fatalError("WorkoutRepository not injected")
    }

    func createWorkout(for exercise: ExerciseDefinition, on date: Date, sets: [WorkoutSetInput]) throws -> WorkoutRecord {
        fatalError("WorkoutRepository not injected")
    }

    func appendSet(to workout: WorkoutRecord, input: WorkoutSetInput) throws {
        fatalError("WorkoutRepository not injected")
    }

    func update(set: SetEntry, with input: WorkoutSetInput) throws {
        fatalError("WorkoutRepository not injected")
    }

    func delete(set: SetEntry, from workout: WorkoutRecord) throws {
        fatalError("WorkoutRepository not injected")
    }

    func updateWorkoutDate(_ workout: WorkoutRecord, to newDate: Date) throws {
        fatalError("WorkoutRepository not injected")
    }

    func save() throws {
        fatalError("WorkoutRepository not injected")
    }
}
