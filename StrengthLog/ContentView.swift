//
//  ContentView.swift
//  StrengthLog
//
//  Created by Aditya Mishra on 5/13/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var exercises: [ExerciseDefinition]
    @State private var selectedExercise: ExerciseDefinition? = nil
    @State private var isEditingExerciseName: Bool = false
    @State private var editingName: String = ""
    @State private var isAddingExercise: Bool = false
    @State private var newExerciseName: String = ""

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Features")) {
                    NavigationLink {
                        WorkoutHistoryListView()
                    } label: {
                        Label("Workout History", systemImage: "clock")
                    }
                    
                    NavigationLink {
                        ProgressChartsView()
                    } label: {
                        Label("Progress Charts", systemImage: "chart.xyaxis.line")
                    }
                    
                    NavigationLink {
                        DataManagementView()
                    } label: {
                        Label("Data Management", systemImage: "square.and.arrow.up.on.square")
                    }
                }
                
                Section(header: Text("My Exercises")) {
                    ForEach(exercises) { exercise in
                        NavigationLink {
                            ExerciseDetailView(exercise: exercise)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(exercise.name)
                                    .font(.headline)
                                Text("Added: \(exercise.dateAdded, format: .dateTime.day().month().year())")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .contextMenu {
                                Button(action: {
                                    selectedExercise = exercise
                                    editingName = exercise.name
                                    isEditingExerciseName = true
                                }) {
                                    Label("Edit Name", systemImage: "pencil")
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteExercise)
                }
            }
            .navigationTitle("StrengthLog")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: promptForNewExercise) {
                        Label("Add Exercise", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isEditingExerciseName) {
                NavigationStack {
                    Form {
                        Section(header: Text("Edit Exercise Name")) {
                            TextField("Exercise Name", text: $editingName)
                                .textInputAutocapitalization(.words)
                        }
                    }
                    .navigationTitle("Edit Exercise")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                isEditingExerciseName = false
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Save") {
                                if let exercise = selectedExercise {
                                    exercise.name = editingName
                                }
                                isEditingExerciseName = false
                            }
                            .disabled(editingName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
            }
            .sheet(isPresented: $isAddingExercise) {
                NavigationStack {
                    Form {
                        Section(header: Text("New Exercise Name")) {
                            TextField("Exercise Name", text: $newExerciseName)
                                .textInputAutocapitalization(.words)
                        }
                    }
                    .navigationTitle("Add Exercise")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                newExerciseName = ""
                                isAddingExercise = false
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Save") {
                                addExercise(name: newExerciseName)
                                newExerciseName = ""
                                isAddingExercise = false
                            }
                            .disabled(newExerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
            }
        }
    }

    private func promptForNewExercise() {
        newExerciseName = ""
        isAddingExercise = true
    }

    private func addExercise(name: String) {
        withAnimation {
            let newExercise = ExerciseDefinition(name: name)
            modelContext.insert(newExercise)
        }
    }

    private func deleteExercise(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(exercises[index])
            }
        }
    }
}

struct ExerciseDetailView: View {
    @Environment(\.modelContext) private var modelContext
    var exercise: ExerciseDefinition
    @State private var showingAddWorkoutSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var workoutToDelete: WorkoutRecord? = nil
    
    // Computed properties for best performance metrics
    private var bestOneRepMaxData: (value: Double, date: Date)? {
        guard !exercise.workoutRecords.isEmpty else { return nil }
        
        var bestOneRM: Double = 0
        var bestDate: Date = Date()
        var foundValidOneRM = false
        
        for workout in exercise.workoutRecords {
            for setEntry in workout.setEntries {
                // Only consider sets with weight for 1RM calculation
                if setEntry.weight != nil && setEntry.calculatedOneRepMax > bestOneRM {
                    bestOneRM = setEntry.calculatedOneRepMax
                    bestDate = workout.date
                    foundValidOneRM = true
                }
            }
        }
        
        return foundValidOneRM ? (value: bestOneRM, date: bestDate) : nil
    }
    
    private var bestVolumeWorkout: (volume: Double, date: Date)? {
        guard !exercise.workoutRecords.isEmpty else { return nil }
        
        let workoutWithMaxVolume = exercise.workoutRecords.max { $0.totalVolume < $1.totalVolume }
        if let workout = workoutWithMaxVolume {
            return (volume: workout.totalVolume, date: workout.date)
        }
        return nil
    }

    var body: some View {
        VStack {
            if !exercise.workoutRecords.isEmpty {
                // Summary card for best performance metrics
                VStack(spacing: 10) {
                    Text("Personal Records")
                        .font(.headline)
                        .padding(.top, 8)
                    
                    HStack(spacing: 20) {
                        VStack {
                            Text("Best 1RM")
                                .font(.subheadline)
                            if let bestOneRM = bestOneRepMaxData {
                                Text("\(bestOneRM.value, specifier: "%.1f")")
                                    .font(.title3.bold())
                                    .foregroundColor(.blue)
                                Text("\(bestOneRM.date, format: .dateTime.day().month())")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("N/A")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        Divider().frame(height: 40)
                        
                        VStack {
                            Text("Best Volume")
                                .font(.subheadline)
                            if let bestVolume = bestVolumeWorkout {
                                Text("\(bestVolume.volume, specifier: "%.1f")")
                                    .font(.title3.bold())
                                    .foregroundColor(.green)
                                Text("\(bestVolume.date, format: .dateTime.day().month())")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("N/A")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            
            if exercise.workoutRecords.isEmpty {
                ContentUnavailableView(
                    "No workouts yet",
                    systemImage: "dumbbell",
                    description: Text("Tap the + button to log your first workout")
                )
            } else {
                List {
                    ForEach(exercise.workoutRecords.sorted(by: { $0.date > $1.date })) { workout in
                        NavigationLink {
                            WorkoutSessionDetailView(workoutRecord: workout)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Date: \(workout.date, format: .dateTime.day().month().year())")
                                    .font(.headline)
                                
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Sets: \(workout.setEntries.count)")
                                            .font(.subheadline)
                                        
                                        Text("Total Volume: \(workout.totalVolume, specifier: "%.1f")")
                                            .font(.subheadline)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing) {
                                        Text("Best 1RM:")
                                            .font(.subheadline)
                                        
                                        Text("\(workout.bestOneRepMaxInSession, specifier: "%.1f")")
                                            .font(.subheadline.bold())
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                workoutToDelete = workout
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete Workout", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                workoutToDelete = workout
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .alert("Delete Workout", isPresented: $showingDeleteConfirmation) {
                    Button("Cancel", role: .cancel) {
                        workoutToDelete = nil
                    }
                    Button("Delete", role: .destructive) {
                        if let workout = workoutToDelete {
                            deleteWorkout(workout)
                            workoutToDelete = nil
                        }
                    }
                } message: {
                    Text("Are you sure you want to delete this workout? This action cannot be undone.")
                }
            }
            
            Spacer()
            
            Button(action: {
                showingAddWorkoutSheet = true
            }) {
                Label("Add Workout", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .navigationTitle(exercise.name)
        .sheet(isPresented: $showingAddWorkoutSheet) {
            WorkoutInputView(exerciseDefinition: exercise)
        }
    }
    
    private func deleteWorkout(_ workout: WorkoutRecord) {
        // Remove the workout from the exercise's workoutRecords array
        if let index = exercise.workoutRecords.firstIndex(where: { $0.id == workout.id }) {
            exercise.workoutRecords.remove(at: index)
        }
        
        // Delete the workout from the model context
        modelContext.delete(workout)
        
        // Try to save the context explicitly to ensure changes are persisted immediately
        do {
            try modelContext.save()
        } catch {
            print("Error deleting workout: \(error)")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            ExerciseDefinition.self,
            WorkoutRecord.self,
            SetEntry.self
        ], inMemory: true)
}
