import SwiftUI
import SwiftData
import Foundation

struct WorkoutInputView: View {
    @Environment(\.workoutRepository) private var workoutRepository
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var themeManager: ThemeManager

    var exerciseDefinition: ExerciseDefinition

    @StateObject private var viewModel: WorkoutInputViewModel

    init(exerciseDefinition: ExerciseDefinition) {
        self.exerciseDefinition = exerciseDefinition
        _viewModel = StateObject(wrappedValue: WorkoutInputViewModel(exercise: exerciseDefinition))
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
                        
                        DatePicker("", selection: $viewModel.workoutDate, displayedComponents: .date)
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
                            
                            Image(systemName: viewModel.isBodyweightExercise ? "figure.walk" : "dumbbell.fill")
                                .foregroundColor(.purple)
                                .font(.system(size: 16, weight: .medium))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Bodyweight Exercise")
                                .font(.system(size: 16, weight: .medium))
                            Text(viewModel.isBodyweightExercise ? "No external weight" : "Uses external weight")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { viewModel.isBodyweightExercise },
                            set: { viewModel.setBodyweight($0) }
                        ))
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
                    if !viewModel.isBodyweightExercise {
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
                            
                        TextField(themeManager.weightUnit.abbreviation, text: $viewModel.weightInput)
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
                        
                        TextField("Count", text: $viewModel.repsInput)
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
                                .fill(viewModel.isValidInput(preferredUnit: themeManager.weightUnit) ? Color.accentColor : Color.gray)
                        )
                    }
                    .disabled(!viewModel.isValidInput(preferredUnit: themeManager.weightUnit))
                    .buttonStyle(PlainButtonStyle())
                    .padding(.vertical, 4)
                }

                if !viewModel.sets.isEmpty {
                    Section(header: HStack {
                        Image(systemName: "list.bullet.circle.fill")
                            .foregroundColor(.accentColor)
                            .font(.system(size: 14, weight: .medium))
                        Text("Logged Sets")
                            .textCase(.uppercase)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(viewModel.sets.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.2))
                            .clipShape(Capsule())
                    }) {
                        ForEach(viewModel.sets) { set in
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.accentColor.opacity(0.1))
                                        .frame(width: 28, height: 28)
                                    if let index = viewModel.sets.firstIndex(where: { $0.id == set.id }) {
                                        Text("\(index + 1)")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.accentColor)
                                    }
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
                            
                            let hasWeightedSets = viewModel.sets.contains(where: { $0.isWeighted })
                            let hasBodyweightSets = viewModel.sets.contains(where: { !$0.isWeighted })
                            let currentTotalVolume = viewModel.totalVolume(in: themeManager.weightUnit)
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
                            .disabled(viewModel.sets.isEmpty)
                }
            }
        }
        .task {
            viewModel.configureIfNeeded(repository: workoutRepository)
        }
        .alert("Unable to Save", isPresented: Binding(
            get: { viewModel.saveErrorMessage != nil },
            set: { if !$0 { viewModel.resetError() } }
        )) {
            Button("OK", role: .cancel) { viewModel.resetError() }
        } message: {
            Text(viewModel.saveErrorMessage ?? "")
        }
    }
    
    private func addSet() {
        viewModel.addSet(preferredUnit: themeManager.weightUnit)
    }

    private func deleteSet(at offsets: IndexSet) {
        viewModel.deleteSet(at: offsets)
    }

    private func saveWorkout() {
        viewModel.persistWorkout(preferredUnit: themeManager.weightUnit) {
            dismiss()
        }
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

        let dependencies = PreviewDependencies(container: container)

        return dependencies.apply(to: WorkoutInputView(exerciseDefinition: exercise))
    }
}
