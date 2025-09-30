import Foundation

struct WorkoutVolumeContributionBuilder {
    struct Slice: Identifiable {
        let id = UUID()
        let name: String
        let volume: Double
        let percentage: Double
    }

    struct SpecificGroup: Identifiable {
        let id = UUID()
        let groupName: String
        let groupShare: Int
        let totalVolume: Double
        let slices: [Slice]
    }

    struct Result {
        let measurement: Measurement
        let totalVolume: Double
        let majorSlices: [Slice]
        let specificGroups: [SpecificGroup]
    }

    enum Measurement {
        case weighted(unit: WeightUnit)
        case bodyweight
        case mixed(unit: WeightUnit)
    }

    static func build(for workout: WorkoutRecord, unit: WeightUnit) -> Result? {
        guard let exercise = workout.exerciseDefinition else { return nil }

        let totalVolume = workout.totalVolume(in: unit)
        guard totalVolume > 0 else { return nil }

        let hasWeightedSets = workout.setEntries.contains(where: { $0.isWeighted })
        let hasBodyweightSets = workout.setEntries.contains(where: { !$0.isWeighted })

        let measurement: Measurement
        if hasWeightedSets && hasBodyweightSets {
            measurement = .mixed(unit: unit)
        } else if hasWeightedSets {
            measurement = .weighted(unit: unit)
        } else {
            measurement = .bodyweight
        }

        let majorSlices = exercise.majorContributions
            .filter { $0.share > 0 }
            .compactMap { contribution -> Slice? in
                guard let name = contribution.majorGroup?.name else { return nil }
                let fraction = Double(contribution.share) / 100.0
                guard fraction > 0 else { return nil }
                return Slice(
                    name: name,
                    volume: totalVolume * fraction,
                    percentage: fraction
                )
            }
            .sorted { lhs, rhs in
                if lhs.volume == rhs.volume {
                    return lhs.name < rhs.name
                }
                return lhs.volume > rhs.volume
            }

        guard !majorSlices.isEmpty else { return nil }

        let groupedSpecifics = Dictionary(
            grouping: exercise.specificContributions.filter { $0.share > 0 }
        ) { contribution -> UUID? in
            contribution.specificMuscle?.majorGroup?.id
        }

        let specificGroups = groupedSpecifics.compactMap { (key: UUID?, contributions: [ExerciseSpecificContribution]) -> SpecificGroup? in
            guard
                let groupID = key,
                let majorContribution = exercise.majorContributions.first(where: { $0.majorGroup?.id == groupID }),
                majorContribution.share > 0,
                let groupName = contributions.first?.specificMuscle?.majorGroup?.name
            else {
                return nil
            }

            let groupFraction = Double(majorContribution.share) / 100.0
            let groupVolume = totalVolume * groupFraction

            guard groupVolume > 0 else { return nil }

            let slices = contributions.compactMap { contribution -> Slice? in
                guard let specificName = contribution.specificMuscle?.name else { return nil }
                let specificFractionOfTotal = Double(contribution.share) / 100.0
                guard specificFractionOfTotal > 0 else { return nil }
                let sliceVolume = totalVolume * specificFractionOfTotal
                let normalizedFraction = groupVolume == 0 ? 0 : min(max(sliceVolume / groupVolume, 0), 1)
                return Slice(
                    name: specificName,
                    volume: sliceVolume,
                    percentage: normalizedFraction
                )
            }
            .sorted { lhs, rhs in
                if lhs.volume == rhs.volume {
                    return lhs.name < rhs.name
                }
                return lhs.volume > rhs.volume
            }

            guard !slices.isEmpty else { return nil }

            return SpecificGroup(
                groupName: groupName,
                groupShare: majorContribution.share,
                totalVolume: groupVolume,
                slices: slices
            )
        }
        .sorted { lhs, rhs in
            if lhs.totalVolume == rhs.totalVolume {
                return lhs.groupName < rhs.groupName
            }
            return lhs.totalVolume > rhs.totalVolume
        }

        return Result(
            measurement: measurement,
            totalVolume: totalVolume,
            majorSlices: majorSlices,
            specificGroups: specificGroups
        )
    }
}