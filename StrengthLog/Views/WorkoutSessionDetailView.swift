import SwiftUI
import SwiftData
import Foundation

struct WorkoutSessionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.themeManager) var themeManager
    var workoutRecord: WorkoutRecord
    @State private var selectedSet: SetEntry? = nil
    @State private var isEditingSet: Bool = false
    @State private var editingWeight: Double = 0
    @State private var editingReps: Int = 0
    @State private var isEditingDate: Bool = false
    @State private var editingDate: Date = Date()
    
    // States for adding new set
    @State private var newWeight: String = ""
    @State private var newReps: String = ""
    @State private var isBodyweightExercise: Bool = false
    
    // Get sets sorted in chronological order (oldest first)
    var sortedSets: [SetEntry] {
        // First, by comparing workout record's set entry array indices
        let setIndices = workoutRecord.setEntries.enumerated().reduce(into: [UUID: Int]()) { dict, entry in
            dict[entry.element.id] = entry.offset
        }
        
        return workoutRecord.setEntries.sorted { setA, setB in
            guard let indexA = setIndices[setA.id], let indexB = setIndices[setB.id] else {
                return false
            }
            return indexA < indexB
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Header Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "dumbbell.fill")
                                .foregroundColor(themeManager.accentColor)
                                .font(.system(size: 24, weight: .medium))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(workoutRecord.exerciseDefinition?.name ?? "Unknown Exercise")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                HStack(spacing: 8) {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                    Text(workoutRecord.date, format: .dateTime.day().month().year())
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                        }
                        
                        // Total Volume Summary Card
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Total Volume")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                
                                let hasWeightedSets = workoutRecord.setEntries.contains { $0.weight != nil }
                                let hasBodyweightSets = workoutRecord.setEntries.contains { $0.weight == nil }
                                
                                if hasWeightedSets && hasBodyweightSets {
                                    Text("\(workoutRecord.totalVolume, format: .number.precision(.fractionLength(1))) (mixed)")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                } else if hasBodyweightSets && !hasWeightedSets {
                                    Text("\(workoutRecord.totalVolume, format: .number.precision(.fractionLength(0))) reps")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                } else {
                                    Text("\(workoutRecord.totalVolume, format: .number.precision(.fractionLength(1)))")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Sets")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                
                                Text("\(sortedSets.count)")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.vertical, 8)
                }
                
                // Sets Section
                Section(header: HStack {
                    Image(systemName: "list.bullet.circle.fill")
                        .foregroundColor(themeManager.accentColor)
                        .font(.system(size: 14, weight: .medium))
                    Text("Sets")
                }) {
                    if sortedSets.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.circle")
                                .foregroundColor(.secondary)
                            Text("No sets recorded yet")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    } else {
                        ForEach(Array(sortedSets.enumerated()), id: \.element.id) { index, set in
                            HStack(spacing: 12) {
                                // Set number badge
                                Text("\(index + 1)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                                    .background(themeManager.accentColor)
                                    .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    if let weight = set.weight {
                                        Text("\(weight, format: .number.precision(.fractionLength(1))) kg × \(set.reps) reps")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    } else {
                                        Text("\(set.reps) reps (bodyweight)")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                    
                                    if set.calculatedOneRepMax > 0 {
                                        Text("Est. 1RM: \(set.calculatedOneRepMax, format: .number.precision(.fractionLength(1))) kg")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedSet = set
                                editingWeight = set.weight ?? 0
                                editingReps = set.reps
                                isEditingSet = true
                            }
                        }
                        .onDelete { indexSet in
                            let setsToDelete = indexSet.map { sortedSets[$0] }
                            
                            for setToDelete in setsToDelete {
                                if let index = workoutRecord.setEntries.firstIndex(where: { $0.id == setToDelete.id }) {
                                    modelContext.delete(setToDelete)
                                    workoutRecord.setEntries.remove(at: index)
                                }
                            }
                        }
                    }
                }
                
                // Add New Set Section
                Section(header: HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(themeManager.accentColor)
                        .font(.system(size: 14, weight: .medium))
                    Text("Add New Set")
                }) {
                    Toggle(isOn: $isBodyweightExercise) {
                        HStack {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .foregroundColor(themeManager.accentColor)
                                .font(.system(size: 16, weight: .medium))
                            Text("Bodyweight Exercise")
                        }
                    }
                    .onChange(of: isBodyweightExercise) { _, newValue in
                        if newValue {
                            newWeight = ""
                        }
                    }
                    
                    if !isBodyweightExercise {
                        HStack {
                            Image(systemName: "scalemass")
                                .foregroundColor(.secondary)
                                .font(.system(size: 16))
                                .frame(width: 20)
                            Text("Weight")
                            Spacer()
                            TextField("kg", text: $newWeight)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "number")
                            .foregroundColor(.secondary)
                            .font(.system(size: 16))
                            .frame(width: 20)
                        Text("Reps")
                        Spacer()
                        TextField("Count", text: $newReps)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }
                    
                    Button(action: addNewSet) {
                        HStack {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .medium))
                            Text("Add Set")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(isValidNewSet() ? themeManager.accentColor : Color(.systemGray4))
                        .foregroundColor(isValidNewSet() ? .white : .secondary)
                        .cornerRadius(8)
                    }
                    .disabled(!isValidNewSet())
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Session Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    editingDate = workoutRecord.date
                    isEditingDate = true
                }) {
                    Label("Edit Date", systemImage: "calendar")
                }
            }
        }
        .sheet(isPresented: $isEditingSet) {
            NavigationStack {
                Form {
                    Section(header: HStack {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundColor(themeManager.accentColor)
                            .font(.system(size: 14, weight: .medium))
                        Text("Edit Set")
                    }) {
                        Toggle(isOn: Binding(
                            get: { selectedSet?.weight == nil },
                            set: { isBodyweight in
                                if isBodyweight {
                                    editingWeight = 0
                                } else if editingWeight == 0 {
                                    editingWeight = 1.0
                                }
                            }
                        )) {
                            HStack {
                                Image(systemName: "figure.strengthtraining.traditional")
                                    .foregroundColor(themeManager.accentColor)
                                    .font(.system(size: 16, weight: .medium))
                                Text("Bodyweight Exercise")
                            }
                        }
                        
                        if selectedSet?.weight != nil || editingWeight > 0 {
                            HStack {
                                Image(systemName: "scalemass")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 16))
                                    .frame(width: 20)
                                Text("Weight")
                                Spacer()
                                TextField("kg", value: $editingWeight, formatter: NumberFormatter.decimal)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 80)
                            }
                        }
                        
                        HStack {
                            Image(systemName: "number")
                                .foregroundColor(.secondary)
                                .font(.system(size: 16))
                                .frame(width: 20)
                            Text("Reps")
                            Spacer()
                            TextField("Count", value: $editingReps, formatter: NumberFormatter.integer)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                        }
                    }
                }
                .navigationTitle("Edit Set")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            isEditingSet = false
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            if let set = selectedSet {
                                set.weight = (editingWeight <= 0) ? nil : editingWeight
                                set.reps = editingReps
                                set.updateOneRepMax()
                            }
                            isEditingSet = false
                        }
                        .disabled(editingReps <= 0)
                        .fontWeight(.semibold)
                    }
                }
            }
        }
        .sheet(isPresented: $isEditingDate) {
            NavigationStack {
                Form {
                    Section(header: HStack {
                        Image(systemName: "calendar.circle.fill")
                            .foregroundColor(themeManager.accentColor)
                            .font(.system(size: 14, weight: .medium))
                        Text("Edit Workout Date")
                    }) {
                        DatePicker("Date", selection: $editingDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                    }
                }
                .navigationTitle("Edit Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            isEditingDate = false
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            workoutRecord.date = editingDate.midnight
                            isEditingDate = false
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
        .themeAware()
    }
    
    // Validation for new set inputs
    private func isValidNewSet() -> Bool {
        // Check reps first
        guard let reps = Int(newReps.trimmingCharacters(in: .whitespaces)),
              reps > 0 else {
            return false
        }
        
        // For bodyweight exercises, only reps need to be valid
        if isBodyweightExercise {
            return true
        }
        
        // For weighted exercises, weight must also be valid
        guard let weight = Double(newWeight.trimmingCharacters(in: .whitespaces)),
              weight > 0 else {
            return false
        }
        
        return true
    }
    
    // Add new set to the workout
    private func addNewSet() {
        guard let reps = Int(newReps.trimmingCharacters(in: .whitespaces)),
              reps > 0 else {
            return
        }
        
        let weight: Double? = isBodyweightExercise ? nil : Double(newWeight.trimmingCharacters(in: .whitespaces))
        
        // For weighted exercises, validate weight
        if !isBodyweightExercise {
            guard let validWeight = weight, validWeight > 0 else {
                return
            }
        }
        
        // Create and add the new set
        let newSet = SetEntry(weight: weight, reps: reps, workoutRecord: workoutRecord)
        modelContext.insert(newSet)
        workoutRecord.setEntries.append(newSet)
        
        // Reset input fields
        newWeight = ""
        newReps = ""
    }
}

#Preview {
    // Group all setup logic
    let (record, container) = {
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
        .themeAware()
}
