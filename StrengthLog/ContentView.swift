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

    var body: some View {
        NavigationSplitView {
            List {
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
                    }
                }
                .onDelete(perform: deleteExercise)
            }
            .navigationTitle("Exercises")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addExercise) {
                        Label("Add Exercise", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an exercise to view workout records")
        }
    }

    private func addExercise() {
        withAnimation {
            let newExercise = ExerciseDefinition(name: "New Exercise")
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
    var exercise: ExerciseDefinition
    @State private var showingAddWorkoutSheet = false

    var body: some View {
        VStack {
            Text("Workout records for \(exercise.name)")
                .font(.headline)
                .padding()
            
            if exercise.workoutRecords.isEmpty {
                ContentUnavailableView(
                    "No workouts yet",
                    systemImage: "dumbbell",
                    description: Text("Tap the + button to log your first workout")
                )
            } else {
                List {
                    ForEach(exercise.workoutRecords) { workout in
                        VStack(alignment: .leading) {
                            Text("Date: \(workout.date, format: .dateTime.day().month().year())")
                                .font(.headline)
                            
                            Text("Sets: \(workout.setEntries.count)")
                                .font(.subheadline)
                        }
                        .padding(.vertical, 4)
                    }
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
}

#Preview {
    ContentView()
        .modelContainer(for: [
            ExerciseDefinition.self,
            WorkoutRecord.self,
            SetEntry.self
        ], inMemory: true)
}
