import SwiftUI
import SwiftData

struct ExerciseInfoView: View {
    let exercise: ExerciseDefinition

    private var categoryNames: [String] {
        exercise.categories
            .sorted(by: { $0.name < $1.name })
            .map { $0.name }
    }

    private var majorContributionSlices: [ContributionSlice] {
        exercise.majorContributions
            .filter { $0.share > 0 }
            .sorted(by: { $0.share > $1.share })
            .compactMap { contribution in
                guard let name = contribution.majorGroup?.name else { return nil }
                return ContributionSlice(name: name, percentage: Double(contribution.share) / 100.0)
            }
    }

    private struct SpecificGroupBreakdown: Identifiable {
        let id = UUID()
        let groupName: String
        let groupShare: Int
        let slices: [ContributionSlice]
    }

    private var specificGroupBreakdowns: [SpecificGroupBreakdown] {
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
                .compactMap { contribution -> ContributionSlice? in
                    guard let muscleName = contribution.specificMuscle?.name else { return nil }
                    return ContributionSlice(name: muscleName, percentage: Double(contribution.share) / 100.0)
                }
                .sorted(by: { $0.percentage > $1.percentage })

            return SpecificGroupBreakdown(groupName: groupName, groupShare: groupShare, slices: slices)
        }
        .sorted(by: { $0.groupShare > $1.groupShare })
    }

    private var validationMessages: [String] {
        exercise.validatePercentages()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !categoryNames.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categoryNames, id: \.self) { name in
                                Text(name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.accentColor.opacity(0.15))
                                    .foregroundColor(.accentColor)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }

                if !majorContributionSlices.isEmpty {
                    ContributionBreakdownView(title: "Major Muscle Groups", slices: majorContributionSlices)
                        .padding(.horizontal, 16)
                }

                ForEach(specificGroupBreakdowns) { breakdown in
                    ContributionBreakdownView(
                        title: "\(breakdown.groupName) \(breakdown.groupShare)%",
                        slices: breakdown.slices
                    )
                    .padding(.horizontal, 16)
                }

                if !validationMessages.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(validationMessages, id: \.self) { message in
                            Label(message, systemImage: "exclamationmark.triangle.fill")
                                .font(.footnote)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.horizontal, 16)
                }

                Spacer(minLength: 12)
            }
            .padding(.vertical, 12)
            .navigationTitle("Exercise Details")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

