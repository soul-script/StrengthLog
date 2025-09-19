//
//  StrengthLogApp.swift
//  StrengthLog
//
//  Created by Aditya Mishra on 5/13/25.
//

import SwiftUI
import SwiftData
import OSLog

@main
struct StrengthLogApp: App {
    private static let bootstrapLogger = Logger(subsystem: "com.adityamishra.StrengthLog", category: "bootstrap")

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ExerciseDefinition.self,
            WorkoutRecord.self,
            SetEntry.self,
            AppSettings.self,
            MajorMuscleGroup.self,
            SpecificMuscle.self,
            WorkoutCategoryTag.self,
            ExerciseMajorContribution.self,
            ExerciseSpecificContribution.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @MainActor
    init() {
        // Seeding is optional and user-controlled; run from a view-layer gate for safety.
    }

    var body: some Scene {
        WindowGroup {
            ThemeAwareContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

struct ThemeAwareContentView: View {
    @Query var settings: [AppSettings]
    
    private var currentSettings: AppSettings? {
        settings.first
    }
    
    var body: some View {
        ContentView()
            .preferredColorScheme(currentSettings?.themeMode.colorScheme)
            .tint(currentSettings?.accentColor.color ?? .blue)
    }
}

