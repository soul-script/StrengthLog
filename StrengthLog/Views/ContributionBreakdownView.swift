import SwiftUI

struct ContributionSlice: Identifiable {
    let id = UUID()
    let name: String
    let percentage: Double
}

struct ContributionBreakdownView: View {
    let title: String
    let slices: [ContributionSlice]

    private var total: Double {
        slices.reduce(0) { $0 + $1.percentage }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text(String(format: "%.0f%%", total * 100))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.1))
                        .frame(height: 12)

                    HStack(spacing: 0) {
                        ForEach(slices) { slice in
                            RoundedRectangle(cornerRadius: 8)
                                .fill(ContributionColorProvider.color(for: slice.name))
                                .frame(width: max(proxy.size.width * slice.percentage, 0))
                        }
                    }
                }
            }
            .frame(height: 12)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(slices) { slice in
                    HStack {
                        Circle()
                            .fill(ContributionColorProvider.color(for: slice.name))
                            .frame(width: 10, height: 10)
                        Text(slice.name)
                            .font(.subheadline)
                        Spacer()
                        Text(String(format: "%.1f%%", slice.percentage * 100))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

enum ContributionColorProvider {
    private static let palette: [String: Color] = [
        "chest": Color(red: 0.89, green: 0.35, blue: 0.43),
        "back": Color(red: 0.33, green: 0.60, blue: 0.93),
        "shoulders": Color(red: 0.94, green: 0.66, blue: 0.20),
        "triceps": Color(red: 0.79, green: 0.49, blue: 0.86),
        "biceps": Color(red: 0.45, green: 0.84, blue: 0.42),
        "forearms": Color(red: 0.20, green: 0.70, blue: 0.62),
        "abs/core": Color(red: 0.94, green: 0.48, blue: 0.36),
        "glutes": Color(red: 0.62, green: 0.45, blue: 0.80),
        "quads": Color(red: 0.36, green: 0.81, blue: 0.75),
        "hamstrings": Color(red: 0.26, green: 0.52, blue: 0.88),
        "calves": Color(red: 0.77, green: 0.52, blue: 0.33),
        "adductors": Color(red: 0.88, green: 0.37, blue: 0.58),
        "abductors/tfl": Color(red: 0.47, green: 0.67, blue: 0.91)
    ]

    static func color(for name: String) -> Color {
        if let exact = palette[name.lowercased()] {
            return exact
        }
        let sanitized = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if let match = palette.keys.first(where: { sanitized.contains($0) }) {
            return palette[match] ?? .accentColor
        }
        let hash = abs(sanitized.hashValue)
        let hue = Double(hash % 360) / 360.0
        return Color(hue: hue, saturation: 0.45, brightness: 0.85)
    }
}
