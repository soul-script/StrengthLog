import Foundation
import SwiftData

/// Pure helpers to compute contribution metrics for an exercise.
/// Returns UI-agnostic slices that views can map to presentation models.
struct ContributionMetricsBuilder {
    struct Slice {
        let name: String
        let fraction: Double
    }

    struct SpecificGroup {
        let groupName: String
        let groupShare: Int
        let slices: [Slice]
    }

    static func majorSlices(for exercise: ExerciseDefinition) -> [Slice] {
        exercise.majorContributions
            .filter { $0.share > 0 }
            .sorted { $0.share > $1.share }
            .compactMap { contribution in
                guard let name = contribution.majorGroup?.name else { return nil }
                return Slice(name: name, fraction: Double(contribution.share) / 100.0)
            }
    }

    static func specificGroups(for exercise: ExerciseDefinition) -> [SpecificGroup] {
        let grouped = Dictionary(grouping: exercise.specificContributions.filter { $0.share > 0 }) { contribution -> UUID? in
            contribution.specificMuscle?.majorGroup?.id
        }

        return grouped.compactMap { key, contributions in
            guard
                let groupID = key,
                let groupShare = exercise.majorContributions.first(where: { $0.majorGroup?.id == groupID })?.share,
                groupShare > 0,
                let groupName = contributions.first?.specificMuscle?.majorGroup?.name
            else { return nil }

            let slices = contributions
                .compactMap { contribution -> Slice? in
                    guard let muscleName = contribution.specificMuscle?.name else { return nil }
                    return Slice(name: muscleName, fraction: Double(contribution.share) / 100.0)
                }
                .sorted { $0.fraction > $1.fraction }

            return SpecificGroup(groupName: groupName, groupShare: groupShare, slices: slices)
        }
        .sorted { $0.groupShare > $1.groupShare }
    }

    static func validationMessages(for exercise: ExerciseDefinition) -> [String] {
        exercise.validatePercentages()
    }
}


