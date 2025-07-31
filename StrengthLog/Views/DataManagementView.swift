import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DataManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var exercises: [ExerciseDefinition]
    @Query private var workouts: [WorkoutRecord]
    @Query private var sets: [SetEntry]
    @Query private var settings: [AppSettings]
    
    @State private var exportURL: URL?
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var showingExportSuccess = false
    @State private var showingImportSuccess = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingClearConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Enhanced Export Section
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "arrow.up.doc.fill")
                            .foregroundColor(.blue)
                        Text("Export Data")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Export all your workout data to a JSON file")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button(action: exportData) {
                            HStack(spacing: 12) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 16, weight: .medium))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Export All Data")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("Save a backup of your progress")
                                        .font(.caption)
                                        .opacity(0.8)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .opacity(0.6)
                            }
                            .foregroundColor(.white)
                            .padding(16)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(20)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                
                // Enhanced Import Section
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "arrow.down.doc.fill")
                            .foregroundColor(.green)
                        Text("Import Data")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Import workout data from a JSON file")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 12))
                            Text("This will replace all existing data")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .fontWeight(.medium)
                        }
                        .padding(8)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        Button(action: { isImporting = true }) {
                            HStack(spacing: 12) {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 16, weight: .medium))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Import Data File")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("Restore from backup")
                                        .font(.caption)
                                        .opacity(0.8)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .opacity(0.6)
                            }
                            .foregroundColor(.green)
                            .padding(16)
                            .background(Color.green.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(20)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                
                // Enhanced Clear Data Section
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.red)
                        Text("Clear Data")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Delete all exercises and workout records")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 12))
                            Text("This action cannot be undone")
                                .font(.caption)
                                .foregroundColor(.red)
                                .fontWeight(.medium)
                        }
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        Button(action: { showingClearConfirmation = true }) {
                            HStack(spacing: 12) {
                                Image(systemName: "trash")
                                    .font(.system(size: 16, weight: .medium))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Clear All Data")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("Reset application")
                                        .font(.caption)
                                        .opacity(0.8)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .opacity(0.6)
                            }
                            .foregroundColor(.red)
                            .padding(16)
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(20)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                
                // Enhanced Statistics Section
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.purple)
                        Text("Database Statistics")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    
                    VStack(spacing: 12) {
                        DataStatRow(
                            icon: "dumbbell.fill",
                            title: "Exercises",
                            value: "\(exercises.count)",
                            color: .blue
                        )
                        
                        DataStatRow(
                            icon: "calendar.badge.clock",
                            title: "Workout Records",
                            value: "\(workouts.count)",
                            color: .green
                        )
                        
                        DataStatRow(
                            icon: "list.number",
                            title: "Set Entries",
                            value: "\(sets.count)",
                            color: .orange
                        )
                        
                        DataStatRow(
                            icon: "gear",
                            title: "Settings",
                            value: "\(settings.count)",
                            color: .purple
                        )
                    }
                }
                .padding(20)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Data Management")
        .navigationBarTitleDisplayMode(.large)
        .fileExporter(
            isPresented: $isExporting,
            document: JSONDocument(initialText: createExportJSON()),
            contentType: .json,
            defaultFilename: "StrengthLog_Export_\(formattedDate())"
        ) { result in
            switch result {
            case .success:
                showingExportSuccess = true
            case .failure(let error):
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let selectedURL = urls.first else { return }
                
                if selectedURL.startAccessingSecurityScopedResource() {
                    defer { selectedURL.stopAccessingSecurityScopedResource() }
                    
                    do {
                        let data = try Data(contentsOf: selectedURL)
                        try importData(from: data)
                        showingImportSuccess = true
                    } catch {
                        errorMessage = error.localizedDescription
                        showingError = true
                    }
                }
            case .failure(let error):
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
        .alert("Export Successful", isPresented: $showingExportSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your data has been successfully exported.")
        }
        .alert("Import Successful", isPresented: $showingImportSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your data has been successfully imported.")
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("Clear All Data", isPresented: $showingClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("Are you sure you want to delete all exercises and workout records? This action cannot be undone.")
        }
    }
    
    private func exportData() {
        isExporting = true
    }
    
    private func clearAllData() {
        // Delete all exercises (which will cascade delete all workout records and sets due to relationship rules)
        for exercise in exercises {
            modelContext.delete(exercise)
        }
        
        // Try to save the context explicitly to ensure changes are persisted immediately
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Error clearing data: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func createExportJSON() -> String {
        do {
            // Create a data structure to represent the export data
            struct ExportData: Codable {
                var exercises: [ExerciseData]
                var settings: SettingsData?
            }
            
            struct SettingsData: Codable {
                var themeMode: String
                var accentColor: String
                var showAdvancedStats: Bool
                var defaultWeightUnit: String
            }
            
            struct ExerciseData: Codable {
                var id: UUID
                var name: String
                var dateAdded: Date
                var workouts: [WorkoutData]
            }
            
            struct WorkoutData: Codable {
                var id: UUID
                var date: Date
                var sets: [SetData]
            }
            
            struct SetData: Codable {
                var id: UUID
                var weight: Double?
                var reps: Int
                var calculatedOneRepMax: Double
            }
            
            // Convert the model data to the export structure
            var exportExercises: [ExerciseData] = []
            
            for exercise in exercises {
                var workoutDataArray: [WorkoutData] = []
                
                for workout in exercise.workoutRecords {
                    var setDataArray: [SetData] = []
                    
                    for set in workout.setEntries {
                        let setData = SetData(
                            id: set.id,
                            weight: set.weight,
                            reps: set.reps,
                            calculatedOneRepMax: set.calculatedOneRepMax
                        )
                        setDataArray.append(setData)
                    }
                    
                    let workoutData = WorkoutData(
                        id: workout.id,
                        date: workout.date,
                        sets: setDataArray
                    )
                    workoutDataArray.append(workoutData)
                }
                
                let exerciseData = ExerciseData(
                    id: exercise.id,
                    name: exercise.name,
                    dateAdded: exercise.dateAdded,
                    workouts: workoutDataArray
                )
                exportExercises.append(exerciseData)
            }
            
            // Include settings in export
            let settingsData: SettingsData? = settings.first.map { appSettings in
                SettingsData(
                    themeMode: appSettings.themeMode.rawValue,
                    accentColor: appSettings.accentColor.rawValue,
                    showAdvancedStats: appSettings.showAdvancedStats,
                    defaultWeightUnit: appSettings.defaultWeightUnit.rawValue
                )
            }
            
            let exportData = ExportData(exercises: exportExercises, settings: settingsData)
            
            // Convert to JSON
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let jsonData = try encoder.encode(exportData)
            
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
        } catch {
            errorMessage = "Error creating export data: \(error.localizedDescription)"
            showingError = true
        }
        
        return "{\"error\": \"Failed to create export data\"}"
    }
    
    private func importData(from data: Data) throws {
        // Define the import data structure
        struct ImportData: Codable {
            var exercises: [ExerciseData]
            var settings: SettingsData?
        }
        
        struct SettingsData: Codable {
            var themeMode: String
            var accentColor: String
            var showAdvancedStats: Bool
            var defaultWeightUnit: String
        }
        
        struct ExerciseData: Codable {
            var id: UUID
            var name: String
            var dateAdded: Date
            var workouts: [WorkoutData]
        }
        
        struct WorkoutData: Codable {
            var id: UUID
            var date: Date
            var sets: [SetData]
        }
        
        struct SetData: Codable {
            var id: UUID
            var weight: Double?
            var reps: Int
            var calculatedOneRepMax: Double
        }
        
        // Parse the JSON data
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let importData = try decoder.decode(ImportData.self, from: data)
        
        // Clear existing data
        for exercise in exercises {
            modelContext.delete(exercise)
        }
        
        // Import the new data
        for exerciseData in importData.exercises {
            let exercise = ExerciseDefinition(name: exerciseData.name, dateAdded: exerciseData.dateAdded.midnight)
            exercise.id = exerciseData.id
            modelContext.insert(exercise)
            
            for workoutData in exerciseData.workouts {
                let workout = WorkoutRecord(date: workoutData.date.midnight, exerciseDefinition: exercise)
                workout.id = workoutData.id
                modelContext.insert(workout)
                
                for setData in workoutData.sets {
                    let set = SetEntry(weight: setData.weight, reps: setData.reps, workoutRecord: workout)
                    set.id = setData.id
                    set.calculatedOneRepMax = setData.calculatedOneRepMax
                    modelContext.insert(set)
                    workout.setEntries.append(set)
                }
                
                exercise.workoutRecords.append(workout)
            }
        }
        
        // Import settings if available
        if let settingsData = importData.settings {
            // Clear existing settings
            for setting in settings {
                modelContext.delete(setting)
            }
            
            // Create new settings from imported data
            let newSettings = AppSettings()
            if let themeMode = ThemeMode(rawValue: settingsData.themeMode) {
                newSettings.themeMode = themeMode
            }
            if let accentColor = AppAccentColor(rawValue: settingsData.accentColor) {
                newSettings.accentColor = accentColor
            }
            newSettings.showAdvancedStats = settingsData.showAdvancedStats
            if let weightUnit = WeightUnit(rawValue: settingsData.defaultWeightUnit) {
                newSettings.defaultWeightUnit = weightUnit
            }
            
            modelContext.insert(newSettings)
        }
        
        // Save changes
        try modelContext.save()
    }
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

// Document type for exporting JSON data
struct JSONDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    var text: String
    
    init(initialText: String = "") {
        text = initialText
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(text.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}

// Data statistics row component
struct DataStatRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray5))
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        DataManagementView()
            .modelContainer(for: [
                ExerciseDefinition.self,
                WorkoutRecord.self,
                SetEntry.self,
                AppSettings.self
            ], inMemory: true)
    }
} 