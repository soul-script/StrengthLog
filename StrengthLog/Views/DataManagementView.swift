import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DataManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var exercises: [ExerciseDefinition]
    @Query private var workouts: [WorkoutRecord]
    @Query private var sets: [SetEntry]
    
    @State private var exportURL: URL?
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var showingExportSuccess = false
    @State private var showingImportSuccess = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingClearConfirmation = false
    
    var body: some View {
        List {
            Section(header: Text("Export Data")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Export all your workout data to a JSON file")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: exportData) {
                        Label("Export Data", systemImage: "arrow.up.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.vertical, 8)
                }
            }
            
            Section(header: Text("Import Data")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Import workout data from a JSON file")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Warning: This will replace all existing data")
                        .font(.caption)
                        .foregroundColor(.red)
                    
                    Button(action: { isImporting = true }) {
                        Label("Import Data", systemImage: "arrow.down.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .padding(.vertical, 8)
                }
            }
            
            Section(header: Text("Clear Data")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Delete all exercises and workout records")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Warning: This action cannot be undone")
                        .font(.caption)
                        .foregroundColor(.red)
                    
                    Button(action: { showingClearConfirmation = true }) {
                        Label("Clear All Data", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                    .padding(.vertical, 8)
                }
            }
            
            Section(header: Text("Database Statistics")) {
                HStack {
                    Text("Exercises")
                    Spacer()
                    Text("\(exercises.count)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Workout Records")
                    Spacer()
                    Text("\(workouts.count)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Set Entries")
                    Spacer()
                    Text("\(sets.count)")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Data Management")
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
            
            let exportData = ExportData(exercises: exportExercises)
            
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

#Preview {
    NavigationStack {
        DataManagementView()
            .modelContainer(for: [
                ExerciseDefinition.self,
                WorkoutRecord.self,
                SetEntry.self
            ], inMemory: true)
    }
} 