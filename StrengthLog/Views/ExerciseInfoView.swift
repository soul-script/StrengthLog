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
        ContributionMetricsBuilder.majorSlices(for: exercise)
            .map { ContributionSlice(name: $0.name, percentage: $0.fraction) }
    }

    private struct SpecificGroupBreakdown: Identifiable {
        let id = UUID()
        let groupName: String
        let groupShare: Int
        let slices: [ContributionSlice]
    }

    private var specificGroupBreakdowns: [SpecificGroupBreakdown] {
        ContributionMetricsBuilder.specificGroups(for: exercise).map { group in
            SpecificGroupBreakdown(
                groupName: group.groupName,
                groupShare: group.groupShare,
                slices: group.slices.map { ContributionSlice(name: $0.name, percentage: $0.fraction) }
            )
        }
    }

    private var validationMessages: [String] {
        ContributionMetricsBuilder.validationMessages(for: exercise)
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

