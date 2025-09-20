import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import OSLog

// MARK: - Import Model Types (shared by decode/apply)
private struct DMCategoryRef: Codable { var name: String }
private struct DMMajorGroupRef: Codable { var name: String; var info: String? }
private struct DMSpecificMuscleRef: Codable { var name: String; var majorGroupName: String?; var notes: String? }

private struct DMCategoryData: Codable { var name: String }
private struct DMMajorContributionData: Codable { var groupName: String; var share: Int }
private struct DMSpecificContributionData: Codable { var majorGroupName: String; var muscleName: String; var share: Int }

private struct DMWorkoutData: Codable { var id: UUID; var date: Date; var sets: [DMSetData] }
private struct DMSetData: Codable { var id: UUID; var weight: Double?; var weightInPounds: Double?; var reps: Int; var calculatedOneRepMax: Double }
private struct DMExerciseData: Codable {
    var id: UUID; var name: String; var dateAdded: Date
    var categories: [DMCategoryData]?; var majorContributions: [DMMajorContributionData]?; var specificContributions: [DMSpecificContributionData]?; var workouts: [DMWorkoutData]
}
private struct DMSettingsData: Codable {
    var themeMode: String
    var accentColor: String
    var showAdvancedStats: Bool
    var defaultWeightUnit: String
}
private struct DMImportData: Codable {
    var categories: [DMCategoryRef]?; var majorGroups: [DMMajorGroupRef]?; var specificMuscles: [DMSpecificMuscleRef]?; var exercises: [DMExerciseData]; var settings: DMSettingsData?
}

struct DataManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var exercises: [ExerciseDefinition]
    @Query private var workouts: [WorkoutRecord]
    @Query private var sets: [SetEntry]
    @Query private var settings: [AppSettings]
    @Query(sort: \WorkoutCategoryTag.name) private var categories: [WorkoutCategoryTag]
    @Query(sort: \MajorMuscleGroup.name) private var majorGroups: [MajorMuscleGroup]
    @Query(sort: \SpecificMuscle.name) private var muscles: [SpecificMuscle]
    private let logger = Logger(subsystem: "com.adityamishra.StrengthLog", category: "DataManagement")
    
    @State private var exportURL: URL?
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var showingExportSuccess = false
    @State private var showingImportSuccess = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingClearConfirmation = false
    @State private var showingSeedSuccess = false
    @State private var exportDocument = JSONDocument(initialText: "{}")
    
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
                Text("Export all your data, including reference taxonomy, to a JSON file")
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
                Text("Import data from a JSON file (replaces existing data)")
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
                
                // Reference Data Management
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "folder.badge.gearshape")
                            .foregroundColor(.purple)
                        Text("Reference Data")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Manage workout categories, muscle groups, and specific muscles")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        NavigationLink {
                            ReferenceDataManagerView()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 16, weight: .medium))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Open Reference Manager")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("Create and edit categories and muscles")
                                        .font(.caption)
                                        .opacity(0.8)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .opacity(0.6)
                            }
                            .foregroundColor(.purple)
                            .padding(16)
                            .background(Color.purple.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.purple.opacity(0.25), lineWidth: 1)
                            )
                        }

                        Button(action: restoreReferenceData) {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.clockwise.circle")
                                    .font(.system(size: 16, weight: .medium))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Restore Reference Data")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("Adds any missing categories and muscles")
                                        .font(.caption)
                                        .opacity(0.8)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .opacity(0.6)
                            }
                            .foregroundColor(.purple)
                            .padding(16)
                            .background(Color.purple.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
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
                        Text("Delete all exercises, workout records, and reference data")
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
            document: exportDocument,
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
                        importDataAsync(from: data)
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
        .alert("Reference Data Restored", isPresented: $showingSeedSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Reference data has been restored or was already complete.")
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
            Text("Are you sure you want to delete all exercises, workout records, and reference data? This action cannot be undone.")
        }
    }
    
    private func exportData() {
        logger.log("Export started")
        let start = Date()
        Task.detached { [logger] in
            do {
                let json = try await MainActor.run { try buildExportJSON() }
                await MainActor.run {
                    exportDocument = JSONDocument(initialText: json)
                    isExporting = true
                }
                let duration = Date().timeIntervalSince(start) * 1000
                logger.log("Export completed in \(Int(duration)) ms")
            } catch {
                logger.error("Export failed: \(String(describing: error))")
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }

    private func restoreReferenceData() {
        do {
            try ReferenceDataSeeder(context: modelContext).seedIfNeeded()
            showingSeedSuccess = true
        } catch {
            errorMessage = "Failed to restore reference data: \(error.localizedDescription)"
            showingError = true
        }
    }

    private func clearAllData() {
        // Delete exercises first (cascades to workouts, sets, and contributions)
        for exercise in exercises { modelContext.delete(exercise) }

        // Delete specific muscles (including any without a major group)
        for muscle in muscles { modelContext.delete(muscle) }

        // Delete major groups (cascades to their specific muscles as well; safe after specifics pass)
        for group in majorGroups { modelContext.delete(group) }

        // Delete categories
        for tag in categories { modelContext.delete(tag) }

        // Persist deletions
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Error clearing data: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private enum DataExportError: Error {
        case encodingFailed
    }

    private func buildExportJSON() throws -> String {
        // Create a data structure to represent the export data
        struct ExportData: Codable {
            var categories: [CategoryRef]
            var majorGroups: [MajorGroupRef]
            var specificMuscles: [SpecificMuscleRef]
            var exercises: [ExerciseData]
            var settings: SettingsData?
        }
            
        struct SettingsData: Codable {
            var themeMode: String
            var accentColor: String
            var showAdvancedStats: Bool
            var defaultWeightUnit: String
        }

            // Top-level reference data
            struct CategoryRef: Codable {
                var name: String
            }
            struct MajorGroupRef: Codable {
                var name: String
                var info: String?
            }
            struct SpecificMuscleRef: Codable {
                var name: String
                var majorGroupName: String?
                var notes: String?
            }

            struct CategoryData: Codable {
                var name: String
            }

            struct MajorContributionData: Codable {
                var groupName: String
                var share: Int
            }

            struct SpecificContributionData: Codable {
                var majorGroupName: String
                var muscleName: String
                var share: Int
            }

            struct ExerciseData: Codable {
                var id: UUID
                var name: String
                var dateAdded: Date
                var categories: [CategoryData]
                var majorContributions: [MajorContributionData]
                var specificContributions: [SpecificContributionData]
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
                var weightInPounds: Double?
                var reps: Int
                var calculatedOneRepMax: Double
            }
            
            // Convert the model data to the export structure
            var exportCategories: [CategoryRef] = []
            exportCategories.reserveCapacity(categories.count)
            for tag in categories {
                exportCategories.append(CategoryRef(name: tag.name))
            }

            var exportMajorGroups: [MajorGroupRef] = []
            exportMajorGroups.reserveCapacity(majorGroups.count)
            for group in majorGroups {
                exportMajorGroups.append(MajorGroupRef(name: group.name, info: group.info))
            }

            var exportSpecificMuscles: [SpecificMuscleRef] = []
            exportSpecificMuscles.reserveCapacity(muscles.count)
            for muscle in muscles {
                exportSpecificMuscles.append(
                    SpecificMuscleRef(
                        name: muscle.name,
                        majorGroupName: muscle.majorGroup?.name,
                        notes: muscle.notes
                    )
                )
            }

            var exportExercises: [ExerciseData] = []
            
            for exercise in exercises {
                var workoutDataArray: [WorkoutData] = []
                
                for workout in exercise.workoutRecords {
                    var setDataArray: [SetData] = []
                    
                    for set in workout.setEntries {
                        let setData = SetData(
                            id: set.id,
                            weight: set.weight,
                            weightInPounds: set.weightValue(in: .lbs),
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
                
                let categoryData = exercise.categories
                    .sorted(by: { $0.name < $1.name })
                    .map { CategoryData(name: $0.name) }

                let majorData = exercise.majorContributions
                    .filter { $0.share > 0 }
                    .sorted(by: { $0.share > $1.share })
                    .compactMap { contribution -> MajorContributionData? in
                        guard let groupName = contribution.majorGroup?.name else { return nil }
                        return MajorContributionData(groupName: groupName, share: contribution.share)
                    }

                let specificData = exercise.specificContributions
                    .filter { $0.share > 0 }
                    .sorted(by: { $0.share > $1.share })
                    .compactMap { contribution -> SpecificContributionData? in
                        guard
                            let muscleName = contribution.specificMuscle?.name,
                            let majorName = contribution.specificMuscle?.majorGroup?.name
                        else { return nil }
                        return SpecificContributionData(majorGroupName: majorName, muscleName: muscleName, share: contribution.share)
                    }

                let exerciseData = ExerciseData(
                    id: exercise.id,
                    name: exercise.name,
                    dateAdded: exercise.dateAdded,
                    categories: categoryData,
                    majorContributions: majorData,
                    specificContributions: specificData,
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
            
            let exportData = ExportData(
                categories: exportCategories,
                majorGroups: exportMajorGroups,
                specificMuscles: exportSpecificMuscles,
                exercises: exportExercises,
                settings: settingsData
            )
            
            // Convert to JSON
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let jsonData = try encoder.encode(exportData)
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                throw DataExportError.encodingFailed
            }
            return jsonString
    }
    
    nonisolated private static func decodeImportData(from data: Data) throws -> DMImportData {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(DMImportData.self, from: data)
    }

    private func applyImport(_ importData: DMImportData) throws {
        // Clear existing data (replace all)
        for exercise in exercises { modelContext.delete(exercise) }
        for muscle in muscles { modelContext.delete(muscle) }
        for group in majorGroups { modelContext.delete(group) }
        for tag in categories { modelContext.delete(tag) }

        // Start with empty caches (avoid relying on @Query state after deletions)
        var categoryCache = [String: WorkoutCategoryTag]()
        var majorGroupCache = [String: MajorMuscleGroup]()
        var muscleCache = [String: SpecificMuscle]()

        func resolveCategory(named name: String) -> WorkoutCategoryTag {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return WorkoutCategoryTag(name: "") } // unreachable in normal flow
            let key = trimmed.lowercased()
            if let existing = categoryCache[key] {
                return existing
            }
            let category = WorkoutCategoryTag(name: trimmed)
            modelContext.insert(category)
            categoryCache[key] = category
            return category
        }

        func resolveMajorGroup(named name: String) -> MajorMuscleGroup {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return MajorMuscleGroup(name: "") } // unreachable in normal flow
            let key = trimmed.lowercased()
            if let existing = majorGroupCache[key] {
                return existing
            }
            let group = MajorMuscleGroup(name: trimmed)
            modelContext.insert(group)
            majorGroupCache[key] = group
            return group
        }

        func resolveMuscle(named name: String, majorGroup: MajorMuscleGroup) -> SpecificMuscle {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return SpecificMuscle(name: "", majorGroup: majorGroup) } // unreachable in normal flow
            let key = trimmed.lowercased()
            if let existing = muscleCache[key] {
                if existing.majorGroup?.id != majorGroup.id {
                    existing.majorGroup = majorGroup
                }
                return existing
            }
            let muscle = SpecificMuscle(name: trimmed, majorGroup: majorGroup)
            modelContext.insert(muscle)
            muscleCache[key] = muscle
            return muscle
        }

        // 1) Import top-level reference data first (if provided)
        if let refs = importData.majorGroups {
            for ref in refs {
                let trimmed = ref.name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { continue }
                let group = resolveMajorGroup(named: trimmed)
                group.info = ref.info
            }
        }

        if let refs = importData.categories {
            for ref in refs {
                let trimmed = ref.name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { continue }
                _ = resolveCategory(named: trimmed)
            }
        }

        if let refs = importData.specificMuscles {
            for ref in refs {
                let trimmedMuscle = ref.name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedMuscle.isEmpty else { continue }
                if let groupName = ref.majorGroupName, !groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    let group = resolveMajorGroup(named: groupName)
                    let muscle = resolveMuscle(named: trimmedMuscle, majorGroup: group)
                    muscle.notes = ref.notes
                } else {
                    // No major group provided; still import the muscle without association
                    let key = trimmedMuscle.lowercased()
                    if muscleCache[key] == nil {
                        let muscle = SpecificMuscle(name: trimmedMuscle, majorGroup: nil, notes: ref.notes)
                        modelContext.insert(muscle)
                        muscleCache[key] = muscle
                    }
                }
            }
        }

        // 2) Import the new exercises and their related data
        for exerciseData in importData.exercises {
            let exercise = ExerciseDefinition(name: exerciseData.name, dateAdded: exerciseData.dateAdded.midnight)
            exercise.id = exerciseData.id
            modelContext.insert(exercise)

            for categoryData in exerciseData.categories ?? [] {
                let category = resolveCategory(named: categoryData.name)
                exercise.categories.append(category)
            }

            for majorData in exerciseData.majorContributions ?? [] {
                let group = resolveMajorGroup(named: majorData.groupName)
                let contribution = ExerciseMajorContribution(exercise: exercise, majorGroup: group, share: majorData.share)
                modelContext.insert(contribution)
            }

            for specificData in exerciseData.specificContributions ?? [] {
                let group = resolveMajorGroup(named: specificData.majorGroupName)
                let muscle = resolveMuscle(named: specificData.muscleName, majorGroup: group)
                let contribution = ExerciseSpecificContribution(exercise: exercise, specificMuscle: muscle, share: specificData.share)
                modelContext.insert(contribution)
            }

            let validationErrors = exercise.validatePercentages()
            if !validationErrors.isEmpty {
                logger.warning("Imported exercise \(exercise.name, privacy: .public) has distribution issues: \(validationErrors.joined(separator: "; "), privacy: .public)")
            }
            
            for workoutData in exerciseData.workouts {
                let workout = WorkoutRecord(date: workoutData.date.midnight, exerciseDefinition: exercise)
                workout.id = workoutData.id
                modelContext.insert(workout)
                
                for setData in workoutData.sets {
                    let measurement = WeightConversionService.shared.measurement(
                        kilograms: setData.weight,
                        pounds: setData.weightInPounds
                    )
                    let set = SetEntry(
                        weight: measurement?.kilograms,
                        weightInPounds: measurement?.pounds,
                        reps: setData.reps,
                        workoutRecord: workout
                    )
                    set.id = setData.id
                    set.updateOneRepMax()
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

    private func importDataAsync(from data: Data) {
        logger.log("Import started")
        let start = Date()
        Task.detached {
            do {
                let decoded = try Self.decodeImportData(from: data)
                await MainActor.run {
                    do {
                        try applyImport(decoded)
                        showingImportSuccess = true
                    } catch {
                        errorMessage = error.localizedDescription
                        showingError = true
                    }
                }
                let duration = Date().timeIntervalSince(start) * 1000
                logger.log("Import completed in \(Int(duration)) ms")
            } catch {
                logger.error("Import failed: \(String(describing: error))")
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
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
                AppSettings.self,
                MajorMuscleGroup.self,
                SpecificMuscle.self,
                WorkoutCategoryTag.self,
                ExerciseMajorContribution.self,
                ExerciseSpecificContribution.self
            ], inMemory: true)
    }
}
