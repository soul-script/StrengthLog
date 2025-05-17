import SwiftUI
import Charts
import SwiftData

struct ProgressChartsView: View {
    @Query var exerciseDefinitions: [ExerciseDefinition]
    @State private var selectedExercise: ExerciseDefinition? = nil
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if exerciseDefinitions.isEmpty {
                    Text("No exercises available. Please add exercises first.")
                        .padding()
                } else {
                    Picker("Select Exercise", selection: $selectedExercise) {
                        ForEach(exerciseDefinitions, id: \.id) { exercise in
                            Text(exercise.name).tag(Optional(exercise))
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal)
                    .onAppear {
                        if selectedExercise == nil, let firstExercise = exerciseDefinitions.first {
                            selectedExercise = firstExercise
                        }
                    }
                    
                    if let exercise = selectedExercise {
                        let records = exercise.workoutRecords
                        if !records.isEmpty {
                            let sortedRecords = records.sorted(by: { $0.date < $1.date })
                            
                            VStack(alignment: .leading) {
                                Text("Estimated 1RM Trend for \(exercise.name)")
                                    .font(.headline)
                                Chart(sortedRecords) { record in
                                    LineMark(x: .value("Date", record.date), y: .value("Est. 1RM", record.bestOneRepMaxInSession))
                                    PointMark(x: .value("Date", record.date), y: .value("Est. 1RM", record.bestOneRepMaxInSession))
                                }
                                .chartXAxisLabel("Date")
                                .chartYAxisLabel("Est. 1RM (kg)")
                                .frame(height: 200)
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Training Volume Trend for \(exercise.name)")
                                    .font(.headline)
                                Chart(sortedRecords) { record in
                                    LineMark(x: .value("Date", record.date), y: .value("Volume", record.totalVolume))
                                    PointMark(x: .value("Date", record.date), y: .value("Volume", record.totalVolume))
                                }
                                .chartXAxisLabel("Date")
                                .chartYAxisLabel("Volume (kg)")
                                .frame(height: 200)
                            }
                        } else {
                            Text("No workout records available for \(exercise.name).")
                                .padding()
                        }
                    } else if !exerciseDefinitions.isEmpty {
                        Text("Please select an exercise to see progress.")
                            .padding()
                    } else {
                        Text("No data available.")
                            .padding()
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Progress Charts")
    }
}

struct ProgressChartsView_Previews: PreviewProvider {
    @MainActor // Ensures Core Data/SwiftData access is on the main thread for previews
    static func createSampleData(modelContext: ModelContext) {
        let sampleExercise1 = ExerciseDefinition(name: "Bench Press")
        let sampleExercise2 = ExerciseDefinition(name: "Squat")
        modelContext.insert(sampleExercise1)
        modelContext.insert(sampleExercise2)
        
        let record1Ex1 = WorkoutRecord(date: Calendar.current.date(byAdding: .day, value: -10, to: Date())!, exerciseDefinition: sampleExercise1)
        let set1Ex1Rec1 = SetEntry(weight: 80, reps: 5, workoutRecord: record1Ex1)
        modelContext.insert(record1Ex1) // Insert parent first
        modelContext.insert(set1Ex1Rec1) // Insert child
        // SwiftData should automatically link relationships if defined correctly.
        // If manual linking is needed (e.g. one-way or specific cases):
        // record1Ex1.setEntries.append(set1Ex1Rec1) 
        // sampleExercise1.workoutRecords.append(record1Ex1)

        let record2Ex1 = WorkoutRecord(date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, exerciseDefinition: sampleExercise1)
        let set1Ex1Rec2 = SetEntry(weight: 85, reps: 5, workoutRecord: record2Ex1)
        modelContext.insert(record2Ex1)
        modelContext.insert(set1Ex1Rec2)
        // record2Ex1.setEntries.append(set1Ex1Rec2)
        // sampleExercise1.workoutRecords.append(record2Ex1)
        
        // Add a record for the second exercise to test selection
        let record1Ex2 = WorkoutRecord(date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!, exerciseDefinition: sampleExercise2)
        let set1Ex2Rec1 = SetEntry(weight: 100, reps: 5, workoutRecord: record1Ex2)
        modelContext.insert(record1Ex2)
        modelContext.insert(set1Ex2Rec1)
        // record1Ex2.setEntries.append(set1Ex2Rec1)
        // sampleExercise2.workoutRecords.append(record1Ex2)
    }

    static var previews: some View {
        // This is the more modern #Preview macro style. 
        // If your project uses the older PreviewProvider struct, the .modelContainer approach is fine.
        // For clarity and to avoid buildExpression errors, we separate data setup.
        
        // Setup for PreviewProvider struct:
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: ExerciseDefinition.self, WorkoutRecord.self, SetEntry.self, configurations: config)
        createSampleData(modelContext: container.mainContext) // Populate with data

        return ProgressChartsView()
            .modelContainer(container)
    }
} 