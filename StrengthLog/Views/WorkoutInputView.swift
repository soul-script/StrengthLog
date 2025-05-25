import SwiftUI
import SwiftData
import Foundation

struct WorkoutInputView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss

    var exerciseDefinition: ExerciseDefinition

    @State private var workoutDate: Date = Date()
    @State private var sets: [TemporarySetEntry] = []
    @State private var weightString: String = ""
    @State private var repsString: String = ""
    @State private var isBodyweightExercise: Bool = false
    
    // Computed property for current total volume
    var currentTotalVolume: Double {
        sets.reduce(0) { total, set in
            if let weight = set.weight {
                return total + (weight * Double(set.reps))
            } else {
                // For bodyweight exercises, volume is just the number of reps
                return total + Double(set.reps)
            }
        }
    }
    
    // Temporary struct to hold set data before saving
    struct TemporarySetEntry: Identifiable {
        let id = UUID()
        var weight: Double?
        var reps: Int
        var oneRepMax: Double {
            if let weight = weight {
                return calculateOneRepMax(weight: weight, reps: reps)
            } else {
                return 0.0 // No 1RM for bodyweight exercises
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Workout Details")) {
                    DatePicker("Date", selection: $workoutDate, displayedComponents: .date)
                }
                
                Section(header: Text("Exercise Type")) {
                    Toggle("Bodyweight Exercise", isOn: $isBodyweightExercise)
                        .onChange(of: isBodyweightExercise) { _, newValue in
                            if newValue {
                                weightString = ""
                            }
                        }
                }

                Section(header: Text("Add Set")) {
                    if !isBodyweightExercise {
                        HStack {
                            Text("Weight:")
                            TextField("kg/lbs", text: $weightString)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    HStack {
                        Text("Reps:")
                        TextField("Count", text: $repsString)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    Button("Add Set") {
                        addSet()
                    }
                    .disabled(!isValidInput())
                }

                if !sets.isEmpty {
                    Section(header: Text("Logged Sets (\(sets.count))")) {
                        List {
                            ForEach(sets) { set in
                                HStack {
                                    if let weight = set.weight {
                                        Text("\(weight, specifier: "%.1f") kg/lbs x \(set.reps) reps")
                                    } else {
                                        Text("\(set.reps) reps (bodyweight)")
                                    }
                                    Spacer()
                                    if set.oneRepMax > 0 {
                                        Text("1RM: \(set.oneRepMax, specifier: "%.1f")")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .onDelete(perform: deleteSet)
                        }
                    }
                }

                Section(header: Text("Total Volume")) {
                    HStack {
                        if sets.contains(where: { $0.weight == nil }) && sets.contains(where: { $0.weight != nil }) {
                            // Mixed exercise types
                            Text("\(currentTotalVolume, format: .number.precision(.fractionLength(1))) (mixed)")
                        } else if sets.allSatisfy({ $0.weight == nil }) {
                            // All bodyweight
                            Text("\(currentTotalVolume, format: .number.precision(.fractionLength(0))) reps")
                        } else {
                            // All weighted
                            Text("\(currentTotalVolume, format: .number.precision(.fractionLength(1)))")
                        }
                    }
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
                    }
                    .disabled(sets.isEmpty)
                }
            }
        }
    }
    
    private func isValidInput() -> Bool {
        // Check reps first
        guard let reps = Int(repsString.trimmingCharacters(in: .whitespaces)),
              reps > 0 else {
            return false
        }
        
        // For bodyweight exercises, only reps need to be valid
        if isBodyweightExercise {
            return true
        }
        
        // For weighted exercises, weight must also be valid
        guard let weight = Double(weightString.trimmingCharacters(in: .whitespaces)),
              weight > 0 else {
            return false
        }
        
        return true
    }

    private func addSet() {
        guard let reps = Int(repsString.trimmingCharacters(in: .whitespaces)),
              reps > 0 else {
            return
        }
        
        let weight: Double? = isBodyweightExercise ? nil : Double(weightString.trimmingCharacters(in: .whitespaces))
        
        // For weighted exercises, validate weight
        if !isBodyweightExercise {
            guard let validWeight = weight, validWeight > 0 else {
                return
            }
        }
        
        let newSet = TemporarySetEntry(weight: weight, reps: reps)
        sets.append(newSet)
        
        // Keep the values for easier entry of multiple sets with similar values
        // User can edit as needed for the next set
    }

    private func deleteSet(at offsets: IndexSet) {
        sets.remove(atOffsets: offsets)
    }

    private func saveWorkout() {
        // Create the workout record
        let newWorkoutRecord = WorkoutRecord(date: workoutDate, exerciseDefinition: exerciseDefinition)
        modelContext.insert(newWorkoutRecord)

        // Add all sets to the workout record
        for tempSet in sets {
            let setEntry = SetEntry(weight: tempSet.weight, reps: tempSet.reps, workoutRecord: newWorkoutRecord)
            modelContext.insert(setEntry)
            newWorkoutRecord.setEntries.append(setEntry)
        }
        
        // Explicitly add the workout record to the exercise's workoutRecords array
        // This ensures the relationship is properly established in both directions
        exerciseDefinition.workoutRecords.append(newWorkoutRecord)
        
        // Try to save the context explicitly to ensure changes are persisted immediately
        do {
            try modelContext.save()
        } catch {
            print("Error saving workout: \(error)")
        }
        
        // Dismiss the view after saving
        dismiss()
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