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
            SetEntry.self,
            AppSettings.self
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

