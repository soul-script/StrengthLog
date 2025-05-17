import SwiftUI
import SwiftData

struct WorkoutHistoryListView: View {
    @Query(sort: [SortDescriptor(\WorkoutRecord.date, order: .reverse)]) var workoutRecords: [WorkoutRecord]

    var body: some View {
        List {
            ForEach(workoutRecords) { record in
                NavigationLink {
                    WorkoutSessionDetailView(workoutRecord: record)
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(record.exerciseDefinition?.name ?? "Unknown Exercise")
                                .font(.headline)
                            Text(record.date, format: .dateTime.day().month().year())
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("\(record.setEntries.count) sets")
                                .font(.subheadline)
                            Text("Volume: \(record.totalVolume, format: .number.precision(.fractionLength(1)))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Workout History")
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: ExerciseDefinition.self, WorkoutRecord.self, SetEntry.self, configurations: config)
    WorkoutHistoryListView()
        .modelContainer(container)
} 