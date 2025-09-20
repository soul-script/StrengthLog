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
    @Environment(\.modelContext) private var modelContext
    @StateObject private var themeManager = ThemeManager()
    @State private var hasInitializedTheme = false
    @State private var repositoryProvider: RepositoryProvider?

    var body: some View {
        Group {
            if let provider = repositoryProvider {
                ContentView()
                    .environmentObject(themeManager)
                    .environment(\.exerciseRepository, provider.exerciseRepository)
                    .environment(\.workoutRepository, provider.workoutRepository)
                    .environment(\.settingsRepository, provider.settingsRepository)
                    .preferredColorScheme(themeManager.colorScheme)
                    .tint(themeManager.accentColor)
            } else {
                ProgressView()
            }
        }
        .task {
            await MainActor.run {
                if repositoryProvider == nil {
                    repositoryProvider = RepositoryProvider(context: modelContext)
                }

                if let provider = repositoryProvider, !hasInitializedTheme {
                    hasInitializedTheme = true
                    themeManager.initialize(with: provider.settingsRepository)
                }
            }
        }
    }
}
