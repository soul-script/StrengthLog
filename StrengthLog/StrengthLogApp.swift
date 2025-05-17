//
//  StrengthLogApp.swift
//  StrengthLog
//
//  Created by Aditya Mishra on 5/13/25.
//

import SwiftUI
import SwiftData

@main
struct StrengthLogApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ExerciseDefinition.self,
            WorkoutRecord.self,
            SetEntry.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    preloadExerciseDataIfNeeded()
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    // Function to preload exercise data if needed
    private func preloadExerciseDataIfNeeded() {
        Task {
            do {
                let modelContext = sharedModelContainer.mainContext
                let descriptor = FetchDescriptor<ExerciseDefinition>(predicate: nil)
                let existingExercises = try modelContext.fetch(descriptor)
                
                // Only preload if there are no exercises yet
                if existingExercises.isEmpty {
                    let defaultExercises = [
                        "Squat",
                        "Bench Press",
                        "Deadlift",
                        "Overhead Press",
                        "Barbell Row",
                        "Pull-ups"
                    ]
                    
                    for exerciseName in defaultExercises {
                        let exercise = ExerciseDefinition(name: exerciseName)
                        modelContext.insert(exercise)
                    }
                    
                    try modelContext.save()
                    print("Preloaded default exercises")
                }
            } catch {
                print("Failed to preload exercise data: \(error)")
            }
        }
    }
}
