import SwiftUI

struct PRHistoryView: View {
    let exercise: ExerciseDefinition
    @State private var personalRecords: [PersonalRecord] = []

    var body: some View {
        List {
            Section(header: Text("Personal Records")) {
                if personalRecords.isEmpty {
                    ContentUnavailableView(
                        "No Records Found",
                        systemImage: "trophy.fill",
                        description: Text("Log some workouts for this exercise to see your personal records.")
                    )
                } else {
                    ForEach(personalRecords) { record in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(record.type.rawValue)
                                    .font(.headline)
                                    .fontWeight(.semibold)

                                Text(record.formattedValue)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)

                                Text("Achieved on \(record.date, format: .dateTime.day().month().year())")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if let set = record.relatedSet {
                                VStack(alignment: .trailing) {
                                    Text("Set Details")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                    if let weight = set.weight {
                                        Text("\(String(format: "%.1f", weight)) kg x \(set.reps) reps")
                                            .font(.caption)
                                    } else {
                                        Text("\(set.reps) reps")
                                            .font(.caption)
                                    }
                                }
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .onAppear {
            personalRecords = PersonalRecordCalculator.calculatePRs(for: exercise)
        }
        .navigationTitle("PR History for \(exercise.name)")
    }
}
