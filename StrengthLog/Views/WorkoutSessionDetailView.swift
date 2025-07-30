import SwiftUI
import SwiftData
import Foundation

struct WorkoutSessionDetailView: View {
    @Environment(\.modelContext) private var modelContext
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
        VStack(alignment: .leading) {
            Text(workoutRecord.exerciseDefinition?.name ?? "Unknown Exercise")
                .font(.largeTitle)
                .padding(.bottom, 2)

            Text(workoutRecord.date, format: .dateTime.day().month().year())
                .font(.headline)
                .padding(.bottom, 10)

            List {
                Section(header: Text("Sets")) {
                    ForEach(sortedSets) { set in
                        HStack {
                            if let weight = set.weight {
                                Text("\(weight, format: .number.precision(.fractionLength(1))) × \(set.reps) reps")
                            } else {
                                Text("\(set.reps) reps (bodyweight)")
                            }
                            Spacer()
                            if set.calculatedOneRepMax > 0 {
                                Text("1RM: \(set.calculatedOneRepMax, format: .number.precision(.fractionLength(1)))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle()) // Make the entire row tappable
                        .onTapGesture {
                            selectedSet = set
                            editingWeight = set.weight ?? 0
                            editingReps = set.reps
                            isEditingSet = true
                        }
                    }
                    .onDelete { indexSet in
                        // Convert UI indices (sorted by time) to model indices
                        let setsToDelete = indexSet.map { sortedSets[$0] }
                        
                        for setToDelete in setsToDelete {
                            if let index = workoutRecord.setEntries.firstIndex(where: { $0.id == setToDelete.id }) {
                                modelContext.delete(setToDelete)
                                workoutRecord.setEntries.remove(at: index)
                            }
                        }
                    }
                }
                
                Section(header: Text("Add New Set")) {
                    Toggle("Bodyweight Exercise", isOn: $isBodyweightExercise)
                        .onChange(of: isBodyweightExercise) { _, newValue in
                            if newValue {
                                newWeight = ""
                            }
                        }
                    
                    if !isBodyweightExercise {
                        HStack {
                            Text("Weight:")
                            TextField("kg/lbs", text: $newWeight)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    HStack {
                        Text("Reps:")
                        TextField("Count", text: $newReps)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Button("Add Set") {
                        addNewSet()
                    }
                    .disabled(!isValidNewSet())
                }

                Section(header: Text("Total Volume")) {
                    HStack {
                        let hasWeightedSets = workoutRecord.setEntries.contains { $0.weight != nil }
                        let hasBodyweightSets = workoutRecord.setEntries.contains { $0.weight == nil }
                        
                        if hasWeightedSets && hasBodyweightSets {
                            // Mixed exercise types
                            Text("\(workoutRecord.totalVolume, format: .number.precision(.fractionLength(1))) (mixed)")
                        } else if hasBodyweightSets && !hasWeightedSets {
                            // All bodyweight
                            Text("\(workoutRecord.totalVolume, format: .number.precision(.fractionLength(0))) reps")
                        } else {
                            // All weighted
                            Text("\(workoutRecord.totalVolume, format: .number.precision(.fractionLength(1)))")
                        }
                    }
                    .font(.title2)
                    .padding(.vertical, 4)
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
                    Section(header: Text("Edit Set")) {
                        Toggle("Bodyweight Exercise", isOn: Binding(
                            get: { selectedSet?.weight == nil },
                            set: { isBodyweight in
                                if isBodyweight {
                                    editingWeight = 0
                                } else if editingWeight == 0 {
                                    editingWeight = 1.0
                                }
                            }
                        ))
                        
                        if selectedSet?.weight != nil || editingWeight > 0 {
                            HStack {
                                Text("Weight:")
                                TextField("kg/lbs", value: $editingWeight, formatter: NumberFormatter.decimal)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                        HStack {
                            Text("Reps:")
                            TextField("Count", value: $editingReps, formatter: NumberFormatter.integer)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
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
                                // If weight is 0 or toggle shows bodyweight, set weight to nil
                                set.weight = (editingWeight <= 0) ? nil : editingWeight
                                set.reps = editingReps
                                set.updateOneRepMax()
                            }
                            isEditingSet = false
                        }
                        .disabled(editingReps <= 0)
                    }
                }
            }
        }
        .sheet(isPresented: $isEditingDate) {
            NavigationStack {
                Form {
                    Section(header: Text("Edit Workout Date")) {
                        DatePicker("Date", selection: $editingDate, displayedComponents: .date)
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
                    }
                }
            }
        }
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