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
                Section(header: Text("Features").textCase(.uppercase).font(.subheadline).foregroundColor(.secondary)) {
                    FeatureRowView(
                        title: "Workout History",
                        subtitle: "View past workouts",
                        systemImage: "clock.fill",
                        color: .blue,
                        destination: AnyView(WorkoutHistoryListView())
                    )
                    
                    FeatureRowView(
                        title: "Progress Charts",
                        subtitle: "Track your improvements",
                        systemImage: "chart.xyaxis.line",
                        color: .green,
                        destination: AnyView(ProgressChartsView())
                    )
                    
                    FeatureRowView(
                        title: "Data Management",
                        subtitle: "Export & import data",
                        systemImage: "square.and.arrow.up.on.square.fill",
                        color: .orange,
                        destination: AnyView(DataManagementView())
                    )
                    
                    FeatureRowView(
                        title: "Settings",
                        subtitle: "Customize your experience",
                        systemImage: "gear",
                        color: .purple,
                        destination: AnyView(SettingsView())
                    )
                }
                
                Section(header: HStack {
                    Text("My Exercises")
                        .textCase(.uppercase)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(exercises.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .clipShape(Capsule())
                }) {
                    ForEach(exercises) { exercise in
                        NavigationLink {
                            ExerciseDetailView(exercise: exercise)
                        } label: {
                            ExerciseRowView(exercise: exercise)
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

// MARK: - Enhanced UI Components

struct FeatureRowView: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let color: Color
    let destination: AnyView
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.1))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: systemImage)
                        .foregroundColor(color)
                        .font(.system(size: 16, weight: .medium))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(.vertical, 4)
        }
    }
}

struct ExerciseRowView: View {
    let exercise: ExerciseDefinition
    
    private var workoutCount: Int {
        exercise.workoutRecords.count
    }
    
    private var lastWorkoutDate: Date? {
        exercise.workoutRecords.max(by: { $0.date < $1.date })?.date
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Exercise Icon
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "dumbbell.fill")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 16, weight: .medium))
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(exercise.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                HStack(spacing: 12) {
                    if workoutCount > 0 {
                        Label("\(workoutCount) workout\(workoutCount == 1 ? "" : "s")", systemImage: "clock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        if let lastDate = lastWorkoutDate {
                            Label("Last: \(lastDate, format: .dateTime.day().month())", systemImage: "calendar")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("No workouts yet")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
            }
            
            Spacer()
            
            if workoutCount > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }
        }
        .padding(.vertical, 2)
    }
}

struct WorkoutRowView: View {
    let workout: WorkoutRecord
    
    var body: some View {
        HStack(spacing: 12) {
            // Date indicator
            VStack(spacing: 2) {
                Text("\(Calendar.current.component(.day, from: workout.date))")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.accentColor)
                
                Text(workout.date.formatted(.dateTime.month(.abbreviated)))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }
            .frame(width: 36)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor.opacity(0.1))
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.date.formatted(.dateTime.weekday(.wide).day().month().year()))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "repeat")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text("\(workout.setEntries.count) sets")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text("\(workout.totalVolume, specifier: "%.0f") vol")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("Best 1RM")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                Text("\(workout.bestOneRepMaxInSession, specifier: "%.1f")")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
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
        VStack(spacing: 0) {
            if !exercise.workoutRecords.isEmpty {
                // Enhanced summary card for best performance metrics
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 16, weight: .medium))
                        Text("Personal Records")
                            .font(.system(size: 18, weight: .semibold))
                        Spacer()
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                    
                    HStack(spacing: 0) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "scalemass.fill")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 18, weight: .medium))
                            }
                            
                            Text("Best 1RM")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            if let bestOneRM = bestOneRepMaxData {
                                Text("\(bestOneRM.value, specifier: "%.1f")")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.primary)
                                Text("\(bestOneRM.date, format: .dateTime.day().month())")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            } else {
                                Text("N/A")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        Rectangle()
                            .fill(Color.secondary.opacity(0.3))
                            .frame(width: 1, height: 60)
                        
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.1))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "chart.bar.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 18, weight: .medium))
                            }
                            
                            Text("Best Volume")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            if let bestVolume = bestVolumeWorkout {
                                Text("\(bestVolume.volume, specifier: "%.1f")")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.primary)
                                Text("\(bestVolume.date, format: .dateTime.day().month())")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            } else {
                                Text("N/A")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.secondarySystemBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            
            if exercise.workoutRecords.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "dumbbell")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    
                    VStack(spacing: 8) {
                        Text("No workouts yet")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("Tap the + button to log your first workout")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(exercise.workoutRecords.sorted(by: { $0.date > $1.date })) { workout in
                        NavigationLink {
                            WorkoutSessionDetailView(workoutRecord: workout)
                        } label: {
                            WorkoutRowView(workout: workout)
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
                .listStyle(PlainListStyle())
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
            
            // Enhanced floating action button
            VStack {
                Spacer()
                
                Button(action: {
                    showingAddWorkoutSheet = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Add Workout")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.accentColor)
                            .shadow(color: Color.accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
                    )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
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
