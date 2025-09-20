import SwiftUI
import SwiftData
import Foundation

struct WorkoutInputView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var themeManager: ThemeManager

    var exerciseDefinition: ExerciseDefinition

    @State private var workoutDate: Date = Date.todayAtMidnight
    @State private var sets: [TemporarySetEntry] = []
    @State private var weightString: String = ""
    @State private var repsString: String = ""
    @State private var isBodyweightExercise: Bool = false
    
    // Computed property for current total volume
    struct TemporarySetEntry: Identifiable {
        let id = UUID()
        var measurement: WeightMeasurement?
        var reps: Int

        var isWeighted: Bool {
            measurement != nil
        }

        func weight(in unit: WeightUnit) -> Double? {
            measurement?.value(in: unit)
        }

        var oneRepMaxKilograms: Double {
            guard let measurement else { return 0 }
            return calculateOneRepMax(weight: measurement.kilograms, reps: reps)
        }

        func displayOneRepMax(in unit: WeightUnit) -> Int? {
            guard measurement != nil else { return nil }
            return Int(convertOneRepMax(oneRepMaxKilograms, to: unit))
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: HStack {
                    Image(systemName: "calendar.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 14, weight: .medium))
                    Text("Workout Details")
                        .textCase(.uppercase)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                                .font(.system(size: 16, weight: .medium))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Date")
                                .font(.system(size: 16, weight: .medium))
                            Text("When did you work out?")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        DatePicker("", selection: $workoutDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: HStack {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 14, weight: .medium))
                    Text("Exercise Type")
                        .textCase(.uppercase)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.purple.opacity(0.1))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: isBodyweightExercise ? "figure.walk" : "dumbbell.fill")
                                .foregroundColor(.purple)
                                .font(.system(size: 16, weight: .medium))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Bodyweight Exercise")
                                .font(.system(size: 16, weight: .medium))
                            Text(isBodyweightExercise ? "No external weight" : "Uses external weight")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $isBodyweightExercise)
                            .onChange(of: isBodyweightExercise) { _, newValue in
                                if newValue {
                                    weightString = ""
                                }
                            }
                    }
                    .padding(.vertical, 4)
                }

                Section(header: HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 14, weight: .medium))
                    Text("Add Set")
                        .textCase(.uppercase)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }) {
                    if !isBodyweightExercise {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.green.opacity(0.1))
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: "scalemass.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 16, weight: .medium))
                            }
                            
                            Text("Weight")
                                .font(.system(size: 16, weight: .medium))
                                .frame(width: 60, alignment: .leading)
                            
                            TextField(themeManager.weightUnit.abbreviation, text: $weightString)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        .padding(.vertical, 4)
                    }
                    
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.orange.opacity(0.1))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "repeat")
                                .foregroundColor(.orange)
                                .font(.system(size: 16, weight: .medium))
                        }
                        
                        Text("Reps")
                            .font(.system(size: 16, weight: .medium))
                            .frame(width: 60, alignment: .leading)
                        
                        TextField("Count", text: $repsString)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.vertical, 4)
                    
                    Button(action: addSet) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Add Set")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isValidInput() ? Color.accentColor : Color.gray)
                        )
                    }
                    .disabled(!isValidInput())
                    .buttonStyle(PlainButtonStyle())
                    .padding(.vertical, 4)
                }

                if !sets.isEmpty {
                    Section(header: HStack {
                        Image(systemName: "list.bullet.circle.fill")
                            .foregroundColor(.accentColor)
                            .font(.system(size: 14, weight: .medium))
                        Text("Logged Sets")
                            .textCase(.uppercase)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(sets.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.2))
                            .clipShape(Capsule())
                    }) {
                        ForEach(sets) { set in
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.accentColor.opacity(0.1))
                                        .frame(width: 28, height: 28)
                                    
                                    Text("\(sets.firstIndex(where: { $0.id == set.id })! + 1)")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.accentColor)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    if let weight = set.weight(in: themeManager.weightUnit) {
                                        Text("\(Int(weight)) \(themeManager.weightUnit.abbreviation) × \(set.reps) reps")
                                            .font(.system(size: 15, weight: .medium))
                                    } else {
                                        Text("\(set.reps) reps (bodyweight)")
                                            .font(.system(size: 15, weight: .medium))
                                    }
                                    
                                    if let oneRep = set.displayOneRepMax(in: themeManager.weightUnit), oneRep > 0 {
                                        Text("1RM: \(oneRep) \(themeManager.weightUnit.abbreviation)")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: deleteSet)
                    }
                }

                Section(header: HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 14, weight: .medium))
                    Text("Session Summary")
                        .textCase(.uppercase)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.green.opacity(0.1))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 18, weight: .medium))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Volume")
                                .font(.system(size: 16, weight: .medium))
                            
                            let hasWeightedSets = sets.contains(where: { $0.isWeighted })
                            let hasBodyweightSets = sets.contains(where: { !$0.isWeighted })
                            let currentTotalVolume = totalVolume(in: themeManager.weightUnit)
                            if hasWeightedSets && hasBodyweightSets {
                                Text("\(Int(currentTotalVolume)) \(themeManager.weightUnit.abbreviation) vol (mixed)")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.green)
                            } else if !hasWeightedSets {
                                Text("\(Int(currentTotalVolume)) reps")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.green)
                            } else {
                                Text("\(Int(currentTotalVolume)) \(themeManager.weightUnit.abbreviation) vol")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.green)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
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
    
    private func totalVolume(in unit: WeightUnit) -> Double {
        sets.reduce(0) { total, set in
            if let weight = set.weight(in: unit) {
                return total + (weight * Double(set.reps))
            }
            return total + Double(set.reps)
        }
    }

    private func isValidInput() -> Bool {
        guard let reps = Int(repsString.trimmingCharacters(in: .whitespaces)), reps > 0 else {
            return false
        }

        if isBodyweightExercise {
            return true
        }

        guard
            let rawWeight = Double(weightString.trimmingCharacters(in: .whitespaces)),
            WeightConversionService.shared.measurement(from: rawWeight, unit: themeManager.weightUnit) != nil
        else {
            return false
        }

        return true
    }

    private func addSet() {
        guard let reps = Int(repsString.trimmingCharacters(in: .whitespaces)), reps > 0 else {
            return
        }

        let measurement: WeightMeasurement?
        if isBodyweightExercise {
            measurement = nil
        } else {
            guard
                let rawWeight = Double(weightString.trimmingCharacters(in: .whitespaces)),
                let normalized = WeightConversionService.shared.measurement(from: rawWeight, unit: themeManager.weightUnit)
            else {
                return
            }
            measurement = normalized
        }

        let newSet = TemporarySetEntry(measurement: measurement, reps: reps)
        sets.append(newSet)
    }

    private func deleteSet(at offsets: IndexSet) {
        sets.remove(atOffsets: offsets)
    }

    private func saveWorkout() {
        // Create the workout record with midnight timestamp
        let newWorkoutRecord = WorkoutRecord(date: workoutDate.midnight, exerciseDefinition: exerciseDefinition)
        modelContext.insert(newWorkoutRecord)

        // Add all sets to the workout record
        for tempSet in sets {
            let setEntry = SetEntry(
                weight: tempSet.measurement?.kilograms,
                weightInPounds: tempSet.measurement?.pounds,
                reps: tempSet.reps,
                workoutRecord: newWorkoutRecord
            )
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
    WorkoutInputViewPreviewFactory.make()
}

private enum WorkoutInputViewPreviewFactory {
    @MainActor
    static func make() -> some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: ExerciseDefinition.self,
                 WorkoutRecord.self,
                 SetEntry.self,
                 AppSettings.self,
                 MajorMuscleGroup.self,
                 SpecificMuscle.self,
                 WorkoutCategoryTag.self,
                 ExerciseMajorContribution.self,
                 ExerciseSpecificContribution.self,
            configurations: config
        )

        let exercise = ExerciseDefinition(name: "Bench Press")
        container.mainContext.insert(exercise)

        let workout = WorkoutRecord(date: Date(), exerciseDefinition: exercise)
        container.mainContext.insert(workout)

        let sampleSet = SetEntry(weight: 80, reps: 8, workoutRecord: workout)
        container.mainContext.insert(sampleSet)
        workout.setEntries.append(sampleSet)

        let appSettings = AppSettings()
        container.mainContext.insert(appSettings)

        let themeManager = ThemeManager()
        themeManager.currentSettings = appSettings

        return WorkoutInputView(exerciseDefinition: exercise)
            .modelContainer(container)
            .environmentObject(themeManager)
    }
}
