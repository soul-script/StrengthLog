import Foundation
import SwiftData

@Model
final class ExerciseDefinition {
    @Attribute(.unique) var id: UUID
    var name: String
    var dateAdded: Date
    
    @Relationship var categories: [WorkoutCategoryTag] = []
    
    @Relationship(deleteRule: .cascade, inverse: \ExerciseMajorContribution.exercise)
    var majorContributions: [ExerciseMajorContribution] = []
    
    @Relationship(deleteRule: .cascade, inverse: \ExerciseSpecificContribution.exercise)
    var specificContributions: [ExerciseSpecificContribution] = []
    
    @Relationship(deleteRule: .cascade)
    var workoutRecords: [WorkoutRecord] = []
    
    init(name: String, dateAdded: Date = Date.todayAtMidnight) {
        self.id = UUID()
        self.name = name
        self.dateAdded = dateAdded.midnight
    }
}

// MARK: - Contribution Metrics & Validation

extension ExerciseDefinition {
    
    /// Total contribution across all selected major muscle groups. Expected to equal 100 after validation.
    var totalMajorShare: Int {
        majorContributions.reduce(0) { runningTotal, contribution in
            runningTotal + contribution.share
        }
    }

    /// Total contribution across specific muscles. Only validated when specific muscles are provided.
    var totalSpecificShare: Int {
        specificContributions.reduce(0) { runningTotal, contribution in
            runningTotal + contribution.share
        }
    }

    /// Aggregates specific-muscle contributions by their parent major group.
    func groupedSpecificShares() -> [UUID: Int] {
        specificContributions.reduce(into: [UUID: Int]()) { partialResult, contribution in
            guard
                let groupID = contribution.specificMuscle?.majorGroup?.id
            else { return }
            partialResult[groupID, default: 0] += contribution.share
        }
    }

    func validatePercentages(
        strategy: ContributionValidationStrategy = DefaultContributionValidationStrategy()
    ) -> [String] {
        strategy.validate(exercise: self)
    }
}

// MARK: - Validation Strategy

protocol ContributionValidationStrategy {
    func validate(exercise: ExerciseDefinition) -> [String]
}

struct DefaultContributionValidationStrategy: ContributionValidationStrategy {
    func validate(exercise: ExerciseDefinition) -> [String] {
        var errors: [String] = []

        let majorTotal = exercise.totalMajorShare
        if !exercise.majorContributions.isEmpty && majorTotal != 100 {
            errors.append("Major muscle shares must sum to 100%. Currently \(majorTotal)%.")
        }

        let specificTotal = exercise.totalSpecificShare
        if !exercise.specificContributions.isEmpty && specificTotal != 100 {
            errors.append("Specific muscle shares must sum to 100%. Currently \(specificTotal)%.")
        }

        let groupedShares = exercise.groupedSpecificShares()
        for majorContribution in exercise.majorContributions {
            guard
                let groupID = majorContribution.majorGroup?.id
            else { continue }
            let specificTotal = groupedShares[groupID, default: 0]
            if specificTotal != majorContribution.share {
                let groupName = majorContribution.majorGroup?.name ?? "Selected group"
                errors.append("Specific muscle shares for \(groupName) must equal the assigned percentage.")
            }
        }

        let selectedGroupIDs = Set(exercise.majorContributions.compactMap { $0.majorGroup?.id })
        let orphanSpecifics = exercise.specificContributions.contains { contribution in
            guard let groupID = contribution.specificMuscle?.majorGroup?.id else { return false }
            return !selectedGroupIDs.contains(groupID)
        }

        if orphanSpecifics {
            errors.append("Some specific muscles belong to a major group that isn’t selected.")
        }

        return errors
    }
}
