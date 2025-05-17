import SwiftUI
import SwiftData
import Foundation

struct WorkoutInputView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss

    var exerciseDefinition: ExerciseDefinition

    @State private var workoutDate: Date = Date()
    @State private var sets: [TemporarySetEntry] = []
    @State private var currentWeight: Double = 0
    @State private var currentReps: Int = 0
    
    // Computed property for current total volume
    var currentTotalVolume: Double {
        sets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }
    
    // Temporary struct to hold set data before saving
    struct TemporarySetEntry: Identifiable {
        let id = UUID()
        var weight: Double
        var reps: Int
        var oneRepMax: Double {
            calculateOneRepMax(weight: weight, reps: reps)
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Workout Details")) {
                    DatePicker("Date", selection: $workoutDate, displayedComponents: .date)
                }

                Section(header: Text("Add Set")) {
                    HStack {
                        Text("Weight:")
                        TextField("kg/lbs", value: $currentWeight, formatter: NumberFormatter.decimal)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Reps:")
                        TextField("Count", value: $currentReps, formatter: NumberFormatter.integer)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    Button("Add Set") {
                        addSet()
                    }
                    .disabled(currentWeight <= 0 || currentReps <= 0)
                }

                if !sets.isEmpty {
                    Section(header: Text("Logged Sets (\(sets.count))")) {
                        List {
                            ForEach(sets) { set in
                                HStack {
                                    Text("\(set.weight, specifier: "%.1f") kg/lbs x \(set.reps) reps")
                                    Spacer()
                                    Text("1RM: \(set.oneRepMax, specifier: "%.1f")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .onDelete(perform: deleteSet)
                        }
                    }
                }

                Section(header: Text("Total Volume")) {
                    Text("\(currentTotalVolume, format: .number.precision(.fractionLength(1)))")
                        .font(.title2)
                        .padding(.vertical, 4)
                }
            }
            .navigationTitle("Log Workout: \(exerciseDefinition.name)")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save Workout") {
                        saveWorkout()
                        dismiss()
                    }
                    .disabled(sets.isEmpty)
                }
            }
        }
    }

    private func addSet() {
        guard currentWeight > 0, currentReps > 0 else { return }
        let newSet = TemporarySetEntry(weight: currentWeight, reps: currentReps)
        sets.append(newSet)
        // Optionally reset fields after adding a set
        // currentWeight = 0
        // currentReps = 0
    }

    private func deleteSet(at offsets: IndexSet) {
        sets.remove(atOffsets: offsets)
    }

    private func saveWorkout() {
        let newWorkoutRecord = WorkoutRecord(date: workoutDate, exerciseDefinition: exerciseDefinition)
        modelContext.insert(newWorkoutRecord)

        for tempSet in sets {
            let setEntry = SetEntry(weight: tempSet.weight, reps: tempSet.reps, workoutRecord: newWorkoutRecord)
            // The 1RM is already calculated in SetEntry's initializer.
            // We can ensure it's updated if necessary, but the current SetEntry model does this.
            // setEntry.updateOneRepMax() // This would re-calculate, initializer should be sufficient
            modelContext.insert(setEntry)
        }
        
        // Link the workout record to the exercise definition
        // This relationship might be implicitly handled if ExerciseDefinition.workoutRecords is an array
        // that SwiftData manages. If not, manual linking might be needed.
        // exerciseDefinition.workoutRecords.append(newWorkoutRecord) // Check if this is needed or automatic

        // No explicit save needed for modelContext with SwiftData's autosave,
        // but good practice to be aware of transactionality.
        // try? modelContext.save() // If manual save is ever preferred or needed.
    }
}

// Preview needs an ExerciseDefinition.
#Preview {
    // Create a dummy ExerciseDefinition for the preview
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: ExerciseDefinition.self, WorkoutRecord.self, SetEntry.self, configurations: config)
    let exampleExercise = ExerciseDefinition(name: "Bench Press")
    // It's important to insert the exampleExercise into the context if WorkoutInputView or its children might try to use its modelContext.
    // However, for this specific preview, WorkoutInputView primarily uses the passed exerciseDefinition for its name and to link upon saving.
    // If the view were to, for example, immediately fetch related data *from* the exerciseDefinition using its context, insertion would be critical here.
    // For now, just passing it should be fine for display and initial interaction.
    // container.mainContext.insert(exampleExercise) // Uncomment if issues arise related to model context from exercise.
    
    WorkoutInputView(exerciseDefinition: exampleExercise)
        .modelContainer(container) // Provide the container to the view hierarchy for @Environment(\.modelContext).
} 