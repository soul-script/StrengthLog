import SwiftUI
import Charts

struct WorkoutContributionChartCard: View {
    let title: String
    let subtitle: String?
    let slices: [WorkoutVolumeContributionBuilder.Slice]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            chart
            legend
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.headline)
            Spacer()
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var chart: some View {
        Chart {
            ForEach(slices) { slice in
                SectorMark(
                    angle: .value("Volume Share", slice.percentage),
                    innerRadius: .ratio(0.55)
                )
                .cornerRadius(4)
                .foregroundStyle(ContributionColorProvider.color(for: slice.name))
            }
        }
        .chartLegend(.hidden)
        .frame(height: 180)
    }

    private var legend: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(slices) { slice in
                HStack {
                    Circle()
                        .fill(ContributionColorProvider.color(for: slice.name))
                        .frame(width: 10, height: 10)
                    Text(slice.name)
                        .font(.subheadline)
                    Spacer()
                    Text(percentageString(for: slice.percentage))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func percentageString(for value: Double) -> String {
        String(format: "%.1f%%", value * 100)
    }
}