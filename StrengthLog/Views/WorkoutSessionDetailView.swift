import SwiftUI
import SwiftData

struct WorkoutSessionDetailView: View {
    var workoutRecord: WorkoutRecord

    var body: some View {
        VStack(alignment: .leading) {
            Text(workoutRecord.exerciseDefinition?.name ?? "Unknown Exercise")
                .font(.largeTitle)
                .padding(.bottom, 2)

            Text(workoutRecord.date, format: .dateTime.day().month().year())
                .font(.headline)
                .padding(.bottom, 10)

            List {
                Section(header: Text("Sets")) {
                    ForEach(workoutRecord.setEntries) { set in
                        HStack {
                            Text("\(set.weight, format: .number.precision(.fractionLength(1))) × \(set.reps) reps")
                            Spacer()
                            Text("1RM: \(set.calculatedOneRepMax, format: .number.precision(.fractionLength(1)))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section(header: Text("Total Volume")) {
                    Text("\(workoutRecord.totalVolume, format: .number.precision(.fractionLength(1)))")
                        .font(.title2)
                        .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Session Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    // Group all setup logic
    let (record, container) = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: ExerciseDefinition.self, WorkoutRecord.self, SetEntry.self, configurations: config)
        let exercise = ExerciseDefinition(name: "Bench Press")
        let record = WorkoutRecord(date: Date(), exerciseDefinition: exercise)
        let set1 = SetEntry(weight: 80, reps: 8, workoutRecord: record)
        let set2 = SetEntry(weight: 85, reps: 5, workoutRecord: record)
        
        container.mainContext.insert(exercise)
        container.mainContext.insert(record)
        container.mainContext.insert(set1)
        container.mainContext.insert(set2)
        
        record.setEntries.append(set1)
        record.setEntries.append(set2)
        
        return (record, container) // Return the necessary data
    }()

    // Ensure the view is returned properly
    return WorkoutSessionDetailView(workoutRecord: record)
        .modelContainer(container)
}