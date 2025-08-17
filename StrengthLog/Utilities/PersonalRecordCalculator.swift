import Foundation

// A struct to represent a specific personal record
struct PersonalRecord: Identifiable {
    let id = UUID()
    let type: PRType
    let value: Double
    let date: Date
    let relatedSet: SetEntry?
    let relatedWorkout: WorkoutRecord?

    enum PRType: String {
        case heaviestWeight = "Heaviest Weight"
        case bestOneRepMax = "Best 1RM"
        case mostReps = "Most Reps"
        case mostVolume = "Most Volume"
    }

    var formattedValue: String {
        switch type {
        case .heaviestWeight, .bestOneRepMax:
            return String(format: "%.1f kg", value)
        case .mostReps:
            return "\(Int(value)) reps"
        case .mostVolume:
            return String(format: "%.1f kg", value)
        }
    }
}

class PersonalRecordCalculator {
    static func calculatePRs(for exercise: ExerciseDefinition) -> [PersonalRecord] {
        var personalRecords: [PersonalRecord] = []

        let allSets = exercise.workoutRecords.flatMap { $0.setEntries }

        // 1. Heaviest Weight
        if let heaviestSet = allSets.filter({ $0.weight != nil }).max(by: { ($0.weight ?? 0) < ($1.weight ?? 0) }) {
            let pr = PersonalRecord(
                type: .heaviestWeight,
                value: heaviestSet.weight!,
                date: heaviestSet.workoutRecord?.date ?? Date(),
                relatedSet: heaviestSet,
                relatedWorkout: heaviestSet.workoutRecord
            )
            personalRecords.append(pr)
        }

        // 2. Best Estimated 1RM
        if let best1RMSet = allSets.filter({ $0.weight != nil }).max(by: { $0.calculatedOneRepMax < $1.calculatedOneRepMax }) {
            if best1RMSet.calculatedOneRepMax > 0 {
                let pr = PersonalRecord(
                    type: .bestOneRepMax,
                    value: best1RMSet.calculatedOneRepMax,
                    date: best1RMSet.workoutRecord?.date ?? Date(),
                    relatedSet: best1RMSet,
                    relatedWorkout: best1RMSet.workoutRecord
                )
                personalRecords.append(pr)
            }
        }

        // 3. Most Reps in a single set
        if let mostRepsSet = allSets.max(by: { $0.reps < $1.reps }) {
            let pr = PersonalRecord(
                type: .mostReps,
                value: Double(mostRepsSet.reps),
                date: mostRepsSet.workoutRecord?.date ?? Date(),
                relatedSet: mostRepsSet,
                relatedWorkout: mostRepsSet.workoutRecord
            )
            personalRecords.append(pr)
        }

        // 4. Most Volume in a single workout
        if let bestVolumeWorkout = exercise.workoutRecords.max(by: { $0.totalVolume < $1.totalVolume }) {
            if bestVolumeWorkout.totalVolume > 0 {
                let pr = PersonalRecord(
                    type: .mostVolume,
                    value: bestVolumeWorkout.totalVolume,
                    date: bestVolumeWorkout.date,
                    relatedSet: nil,
                    relatedWorkout: bestVolumeWorkout
                )
                personalRecords.append(pr)
            }
        }

        return personalRecords
    }
}
