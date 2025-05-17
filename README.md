# StrengthLog: Technical Documentation

**Version:** 1.0 (Post-Phase 7 & Additional Features)
**Date:** May 17, 2025
**Document Purpose:** This document provides a comprehensive technical overview of the StrengthLog iOS application, intended for development teams, new developers onboarding to the project, or for future maintenance and enhancement purposes.

## 1. Introduction

### 1.1. Project Overview

StrengthLog is an iOS application designed for users to track their strength training workouts. It allows users to define exercises, log workout sessions (including sets, weight, and repetitions), calculate estimated 1 Rep Max (1RM), visualize progress over time through charts, and manage their workout data via import/export functionalities.

### 1.2. Purpose

The primary goal of StrengthLog is to offer a simple, user-friendly, and focused tool for strength training enthusiasts to monitor their performance, track progress, and stay motivated. It emphasizes core mechanics like logging, 1RM estimation, and volume tracking.

### 1.3. Technology Stack

- **UI Framework:** SwiftUI (for declarative UI development)
- **Data Persistence:** SwiftData (for on-device data storage and management)
- **Language:** Swift
- **Charting:** SwiftUI Charts framework
- **IDE:** Xcode (typically, though developed with AI assistance via Cursor)
- **Target OS:** iOS

## 2. System Architecture

### 2.1. Architectural Pattern

StrengthLog primarily follows a declarative UI pattern driven by SwiftUI. While not strictly adhering to a formal architectural pattern like MVVM or VIPER by name, its structure exhibits characteristics influenced by MVVM:

- **Models:** SwiftData `@Model` classes (`ExerciseDefinition`, `WorkoutRecord`, `SetEntry`) represent the data and its structure. They include business logic related to data (e.g., computed properties for `totalVolume`, `bestOneRepMaxInSession`, 1RM calculation in `SetEntry`).
- **Views:** SwiftUI `View` structs define the UI layout and presentation. They observe data (often via `@Query` for SwiftData models or `@State` for local UI state) and update reactively.
- **View Logic/State Management:** UI-specific logic and state are managed within the views themselves using SwiftUI's property wrappers (`@State`, `@StateObject`, `@Environment`, `@Query`). Data manipulation logic (CRUD operations) is often performed directly within views using the `modelContext` obtained from the environment.

### 2.2. Data Flow Overview

1.  **Data Entry:** Users input data through various views (e.g., `WorkoutInputView` for sets, `ContentView` for new exercises).
2.  **ModelContext Interaction:** Views use the `@Environment(\.modelContext)` to access the SwiftData `ModelContext`.
3.  **Object Creation/Modification:** New SwiftData model objects are created (e.g., `SetEntry`, `WorkoutRecord`) or existing ones are modified.
4.  **Persistence:** SwiftData handles the persistence of these objects to the on-device store. Explicit `modelContext.save()` calls are used in critical data modification paths to ensure immediate persistence.
5.  **Data Fetching:** Views use `@Query` property wrappers to fetch and observe arrays of SwiftData model objects. These queries can include sorting and filtering.
6.  **UI Update:** SwiftUI automatically re-renders views when the observed data (from `@Query`, `@State`, etc.) changes.
7.  **Relationships:** SwiftData manages the relationships between models (e.g., an `ExerciseDefinition` has many `WorkoutRecord`s, a `WorkoutRecord` has many `SetEntry`s). Cascade rules are defined for deletion.

## 3. Data Models (SwiftData)

All data models are located in the `Models/` directory.

### 3.1. `ExerciseDefinition.swift`

- **Purpose:** Represents a specific type of exercise (e.g., "Squat", "Bench Press").
- **Fields:**
  - `id: UUID` (Primary key, unique)
  - `name: String` (Name of the exercise)
  - `dateAdded: Date` (Date the exercise was added)
- **Relationships:**
  - `workoutRecords: [WorkoutRecord]` (One-to-Many with `WorkoutRecord`). Configured with `deleteRule: .cascade`, meaning if an `ExerciseDefinition` is deleted, all its associated `WorkoutRecord`s are also deleted.
- **Initialization:** `init(name: String, dateAdded: Date = Date())`

### 3.2. `WorkoutRecord.swift`

- **Purpose:** Represents a single workout session for a specific exercise on a particular date.
- **Fields:**
  - `id: UUID` (Primary key, unique)
  - `date: Date` (Date of the workout session)
- **Relationships:**
  - `exerciseDefinition: ExerciseDefinition?` (Many-to-One with `ExerciseDefinition`). Configured with `deleteRule: .nullify`, meaning if the parent `ExerciseDefinition` is deleted, this field will be set to `nil` (though the cascade rule on `ExerciseDefinition.workoutRecords` means the `WorkoutRecord` itself would be deleted in that scenario).
  - `setEntries: [SetEntry]` (One-to-Many with `SetEntry`). Configured with `deleteRule: .cascade`, meaning if a `WorkoutRecord` is deleted, all its associated `SetEntry`s are also deleted.
- **Computed Properties:**
  - `totalVolume: Double`: Calculates the total volume for the session ($\sum (\text{weight} \times \text{reps})$ across all `setEntries`).
  - `bestOneRepMaxInSession: Double` (extension): Calculates the highest `calculatedOneRepMax` from all its `setEntries`. Returns `0.0` if no sets are present.
- **Initialization:** `init(date: Date = Date(), exerciseDefinition: ExerciseDefinition? = nil)`

### 3.3. `SetEntry.swift`

- **Purpose:** Represents a single set performed within a `WorkoutRecord` (e.g., 100kg for 5 reps).
- **Fields:**
  - `id: UUID` (Primary key, unique)
  - `weight: Double` (Weight lifted for the set)
  - `reps: Int` (Number of repetitions performed)
  - `calculatedOneRepMax: Double` (Estimated 1 Rep Max for this set, calculated on initialization and updatable)
- **Relationships:**
  - `workoutRecord: WorkoutRecord?` (Many-to-One with `WorkoutRecord`). Configured with `deleteRule: .nullify`.
- **Initialization:** `init(weight: Double, reps: Int, workoutRecord: WorkoutRecord? = nil)`
  - Calculates `calculatedOneRepMax` upon initialization using the modified Epley formula:
    - If `reps == 1`, `calculatedOneRepMax = weight`.
    - Otherwise, `calculatedOneRepMax = weight * (1 + Double(reps) / 30.0)`.
- **Methods:**
  - `updateOneRepMax()`: Recalculates and updates the `calculatedOneRepMax` property based on the current `weight` and `reps`. Uses the global `calculateOneRepMax(weight:reps:)` function.
  - `private func calculateOneRepMax(weight: Double, reps: Int) -> Double`: (Note: This private method is shadowed by the global one in `Extensions.swift` for the `updateOneRepMax` call. The initializer uses its own logic directly). The `updateOneRepMax` method now calls the global `calculateOneRepMax` function from `Extensions.swift`.

### 3.4. `Models/Extensions.swift`

- **Purpose:** Contains utility extensions and global helper functions.
- **Contents:**
  - `extension NumberFormatter`:
    - `static var decimal: NumberFormatter`: Provides a pre-configured formatter for decimal numbers (e.g., weight).
    - `static var integer: NumberFormatter`: Provides a pre-configured formatter for integers (e.g., reps).
  - `func calculateOneRepMax(weight: Double, reps: Int) -> Double`:
    - Global Epley formula implementation for calculating 1RM.
    - Handles `reps == 0` by returning `weight`.
    - If `reps == 1`, it returns `weight` directly (actual 1RM).
    - Otherwise, uses the formula: `weight * (1 + Double(reps) / 30.0)`.

### 3.5. Relationships and Cascade Rules

- **`ExerciseDefinition` to `WorkoutRecord`:** One-to-Many. Deleting an `ExerciseDefinition` cascades to delete all its `WorkoutRecord`s.
- **`WorkoutRecord` to `ExerciseDefinition`:** Many-to-One (optional). If an `ExerciseDefinition` is deleted, this link in `WorkoutRecord` would be nullified if the `WorkoutRecord` wasn't already deleted by cascade.
- **`WorkoutRecord` to `SetEntry`:** One-to-Many. Deleting a `WorkoutRecord` cascades to delete all its `SetEntry`s.
- **`SetEntry` to `WorkoutRecord`:** Many-to-One (optional). If a `WorkoutRecord` is deleted, this link in `SetEntry` is nullified (if the `SetEntry` wasn't already deleted by cascade).

These rules ensure data integrity when parent objects are removed.

## 4. Core Application (`StrengthLogApp.swift`)

### 4.1. Application Entry Point

- `@main struct StrengthLogApp: App` serves as the entry point for the application.

### 4.2. SwiftData Stack Initialization

- A `sharedModelContainer: ModelContainer` is created as a lazy static property.
- **Schema Definition:** The schema includes `ExerciseDefinition.self`, `WorkoutRecord.self`, and `SetEntry.self`.
- **Model Configuration:** A `ModelConfiguration` is used, with `isStoredInMemoryOnly` set to `false` for persistent storage.
- **Container Creation:** `ModelContainer(for:configurations:)` attempts to create the container. A `fatalError` is thrown if creation fails.
- **Container Injection:** The `sharedModelContainer` is injected into the SwiftUI environment for the `ContentView` using the `.modelContainer()` view modifier.
- **Initial Data Preloading:** The `preloadExerciseDataIfNeeded()` function, previously used to populate default exercises, has been **removed** from the `.onAppear` modifier of `ContentView` in `StrengthLogApp.swift`. Users now start with a blank slate, aligning with the data import/export capabilities.

## 5. User Interface (SwiftUI Views)

All views are located in the `Views/` directory, with `ContentView.swift` and its nested `ExerciseDetailView` at the root level.

### 5.1. `ContentView.swift` (Main Navigation & Exercise Management)

- **Purpose:** Acts as the main navigation screen of the app, providing access to different features and managing the list of exercises.
- **Key State & Data:**
  - `@Environment(\.modelContext) private var modelContext`: For SwiftData operations.
  - `@Query private var exercises: [ExerciseDefinition]`: Fetches all exercises, sorted by name (implicitly by SwiftData's default or as defined in the query).
  - `@State private var selectedExercise: ExerciseDefinition?`: For editing an exercise name.
  - `@State private var isEditingExerciseName: Bool`: Controls presentation of the exercise name editing sheet.
  - `@State private var editingName: String`: Holds the name during editing.
  - `@State private var isAddingExercise: Bool`: Controls presentation of the new exercise name input sheet.
  - `@State private var newExerciseName: String`: Holds the name for a new exercise.
- **Functionality:**
  - Uses `NavigationSplitView` for layout.
  - **Features Section:**
    - `NavigationLink` to `WorkoutHistoryListView`.
    - `NavigationLink` to `ProgressChartsView`.
    - `NavigationLink` to `DataManagementView`.
  - **My Exercises Section:**
    - Lists all `ExerciseDefinition`s. Each row is a `NavigationLink` to `ExerciseDetailView` for that exercise.
    - **Context Menu:** Each exercise row has a context menu with an "Edit Name" option, which presents a sheet (`isEditingExerciseName`) to modify the `exercise.name`. The save button in the sheet is disabled for empty names.
    - **Deletion:** Supports swipe-to-delete for exercises (`.onDelete(perform: deleteExercise)`), which removes the exercise from `modelContext`.
  - **Toolbar:**
    - `EditButton()`: Toggles the list's edit mode for reordering/deleting.
    - "Add Exercise" button (`Label` with "plus" systemImage): Calls `promptForNewExercise()`.
- **Exercise Creation (`promptForNewExercise`, `addExercise(name: String)`):**
  - `promptForNewExercise()` sets `isAddingExercise = true` to show a sheet.
  - The sheet takes `newExerciseName` input.
  - `addExercise(name: String)` creates a new `ExerciseDefinition` with the provided name and inserts it into `modelContext`. The save button is disabled for empty names.
- **Navigation Title:** "StrengthLog".

### 5.2. `ExerciseDetailView.swift` (struct within `ContentView.swift`)

- **Purpose:** Displays detailed information for a selected `ExerciseDefinition`, including its workout history and personal records. Allows logging new workouts for this exercise and deleting existing ones.
- **Key State & Data:**
  - `@Environment(\.modelContext) private var modelContext`: For SwiftData operations.
  - `var exercise: ExerciseDefinition`: The exercise being detailed.
  - `@State private var showingAddWorkoutSheet = false`: Controls presentation of `WorkoutInputView`.
  - `@State private var showingDeleteConfirmation = false`: Controls the alert for deleting a workout.
  - `@State private var workoutToDelete: WorkoutRecord?`: Holds the workout record targeted for deletion.
- **Functionality:**
  - **Personal Records Card:**
    - Displays "Best 1RM" (value and date) and "Best Volume" (value and date) for the current `exercise`.
    - Computed properties `bestOneRepMaxData` and `bestVolumeWorkout` calculate these metrics by iterating through the exercise's `workoutRecords` and their `setEntries`.
  - **Workout List:**
    - If `exercise.workoutRecords` is empty, shows a `ContentUnavailableView`.
    - Otherwise, lists `WorkoutRecord`s for the exercise, sorted by date descending. Each row shows date, set count, total volume, and best 1RM for that session.
    - **Context Menu/Swipe Action:** Each workout row has options (context menu and swipe) to delete the workout. This triggers `showingDeleteConfirmation`.
  - **"Add Workout" Button:** Presents `WorkoutInputView` as a sheet.
  - **Workout Deletion (`deleteWorkout(_ workout: WorkoutRecord)`):**
    - Removes the workout from `exercise.workoutRecords` array.
    - Deletes the `workout` from `modelContext`.
    - Calls `modelContext.save()` explicitly.
- **Navigation Title:** The name of the `exercise`.

### 5.3. `WorkoutInputView.swift`

- **Purpose:** A modal view (sheet) for logging a new workout session for a specific exercise.
- **Key State & Data:**
  - `@Environment(\.modelContext) private var modelContext`.
  - `@Environment(\.dismiss) var dismiss`.
  - `var exerciseDefinition: ExerciseDefinition`: The exercise for which the workout is being logged.
  - `@State private var workoutDate: Date`: Date of the workout.
  - `@State private var sets: [TemporarySetEntry]`: Array to temporarily hold sets before saving.
  - `@State private var weightString: String`: Input for weight (as String).
  - `@State private var repsString: String`: Input for reps (as String).
- **`TemporarySetEntry` struct:** A local struct to hold `weight`, `reps`, and computed `oneRepMax` for sets being added to the current session.
- **Functionality:**
  - **Form Layout:**
    - `DatePicker` for `workoutDate`.
    - Section for "Add Set" with `TextField`s for `weightString` and `repsString`.
      - Uses `.keyboardType(.decimalPad)` and `.numberPad` respectively.
      - "Add Set" button calls `addSet()`, disabled if `isValidInput()` is false.
    - Lists currently logged `TemporarySetEntry`s, showing weight, reps, and 1RM. Supports swipe-to-delete for these temporary sets.
    - Displays `currentTotalVolume` (computed from `sets`).
  - **Input Validation (`isValidInput()`):** Checks if `weightString` and `repsString` can be parsed to positive `Double` and `Int`.
  - **Adding a Set (`addSet()`):**
    - Parses `weightString` and `repsString`.
    - If valid, creates a `TemporarySetEntry` and appends it to `sets`.
    - Input fields (`weightString`, `repsString`) are _not_ automatically cleared to allow for easy logging of similar subsequent sets.
  - **Saving Workout (`saveWorkout()`):**
    - Creates a new `WorkoutRecord` and inserts it into `modelContext`.
    - Iterates through `temporarySet.sets`:
      - Creates a `SetEntry` for each, linking it to the new `WorkoutRecord`, and inserts it into `modelContext`.
      - Appends the `SetEntry` to `newWorkoutRecord.setEntries`.
    - Appends `newWorkoutRecord` to `exerciseDefinition.workoutRecords` to establish the bi-directional relationship.
    - Calls `modelContext.save()` explicitly.
    - Dismisses the view.
- **Navigation Title:** "Log Workout: [Exercise Name]".
- **Toolbar:** "Cancel" and "Save Workout" buttons. "Save Workout" is disabled if `sets` is empty.

### 5.4. `WorkoutHistoryListView.swift`

- **Purpose:** Displays a chronological list of all workout sessions across all exercises.
- **Key State & Data:**
  - `@Query(sort: [SortDescriptor(\WorkoutRecord.date, order: .reverse)]) var workoutRecords: [WorkoutRecord]`: Fetches all workout records, sorted by date descending.
- **Functionality:**
  - `List` iterates through `workoutRecords`.
  - Each row is a `NavigationLink` to `WorkoutSessionDetailView` for the selected `record`.
  - Displays exercise name, date, set count, and total volume for each record.
- **Navigation Title:** "Workout History".

### 5.5. `WorkoutSessionDetailView.swift`

- **Purpose:** Shows full details of a selected `WorkoutRecord`, allowing users to edit/delete individual sets and edit the workout date.
- **Key State & Data:**
  - `@Environment(\.modelContext) private var modelContext`.
  - `var workoutRecord: WorkoutRecord`: The workout session being detailed.
  - `@State private var selectedSet: SetEntry?`: For editing a specific set.
  - `@State private var isEditingSet: Bool`: Controls presentation of the set editing sheet.
  - `@State private var editingWeight: Double`, `@State private var editingReps: Int`: Hold values for set editing.
  - `@State private var isEditingDate: Bool`: Controls presentation of the date editing sheet.
  - `@State private var editingDate: Date`: Holds the date during editing.
- **Functionality:**
  - Displays exercise name and workout date.
  - **Sets List:**
    - Lists `setEntries` of the `workoutRecord`. Each row shows weight, reps, and calculated 1RM.
    - **Tap to Edit Set:** Tapping a set row sets `selectedSet`, populates `editingWeight` and `editingReps`, and presents a sheet (`isEditingSet`) for modification.
      - The editing sheet allows changing weight and reps.
      - On save, updates `selectedSet.weight`, `selectedSet.reps`, and calls `selectedSet.updateOneRepMax()`.
      - Save button is disabled for non-positive weight/reps.
    - **Swipe to Delete Set:** `.onDelete` modifier allows deleting individual `SetEntry`s. The `SetEntry` is removed from `modelContext` and also from `workoutRecord.setEntries` array (though SwiftData might handle the array part automatically with proper relationship setup).
  - **Total Volume Section:** Displays `workoutRecord.totalVolume`.
  - **Toolbar:** "Edit Date" button (calendar icon) presents a sheet (`isEditingDate`) with a `DatePicker` to modify `workoutRecord.date`.
- **Navigation Title:** "Session Details".

### 5.6. `ProgressChartsView.swift`

- **Purpose:** Provides visualization of 1RM and training volume trends for selected exercises over time.
- **Key State & Data:**
  - `@Query var exerciseDefinitions: [ExerciseDefinition]`: Fetches all exercises for the picker.
  - `@State private var selectedExercise: ExerciseDefinition?`: The exercise chosen for charting.
  - `@State private var selectedDataPoint: (date: Date, value: Double)?`: Holds data of a point tapped/dragged on the chart.
  - `@State private var chartType: ChartType = .oneRepMax`: Enum (`.oneRepMax`, `.volume`) to switch chart data.
  - `@State private var timeRange: TimeRange = .allTime`: Enum (`.month`, `.threeMonths`, etc.) for filtering data by period.
- **Functionality:**
  - **Pickers:**
    - `Picker` for `selectedExercise`.
    - Segmented `Picker` for `chartType`.
    - Menu `Picker` for `timeRange`.
    - Changing any picker resets `selectedDataPoint`.
  - **Data Filtering (`filterRecordsByTimeRange`):** Filters `workoutRecords` of the `selectedExercise` based on `timeRange`.
  - **Chart Display (`chartView`):**
    - Uses SwiftUI `Chart` API.
    - Plots `LineMark` and `PointMark` for `record.date` vs. (`record.bestOneRepMaxInSession` or `record.totalVolume`) based on `chartType`.
    - Uses different colors for 1RM (blue) and Volume (green) charts.
    - Customizes X and Y axes (`AxisMarks`, `AxisValueLabel`).
    - `.chartOverlay` with a `DragGesture` allows users to scrub through the chart, updating `selectedDataPoint` to the nearest data point.
  - **Selected Data Point Info:** Displays the date and value of `selectedDataPoint` below the chart.
  - **User Experience:** Handles cases like no exercises, no records for selected exercise, or no data in selected time range using `ContentUnavailableView` or `Text` messages.
- **Navigation Title:** "Progress Charts".

### 5.7. `Views/DataManagementView.swift`

- **Purpose:** Allows users to export their data to JSON, import data from JSON, and clear all data.
- **Key State & Data:**
  - `@Environment(\.modelContext) private var modelContext`.
  - `@Query` for `exercises`, `workouts`, `sets` (primarily for statistics and export).
  - `@State` variables for controlling file exporter/importer presentation (`isExporting`, `isImporting`), alert visibility (`showingExportSuccess`, `showingImportSuccess`, `showingError`, `showingClearConfirmation`), and error messages.
- **`JSONDocument` struct:** Conforms to `FileDocument` for use with `.fileExporter`.
- **Functionality:**
  - **Export Data:**
    - `exportData()` sets `isExporting = true`.
    - `.fileExporter` modifier presents the system's file save sheet.
    - `createExportJSON()`:
      - Defines `Codable` structs (`ExportData`, `ExerciseData`, `WorkoutData`, `SetData`) mirroring the model hierarchy.
      - Iterates through fetched `exercises`, their `workoutRecords`, and `setEntries`, populating these export structs.
      - Uses `JSONEncoder` (with `iso8601` date strategy and `prettyPrinted`, `sortedKeys` output formatting) to create the JSON string.
      - Generates a default filename like "StrengthLog_Export_yyyy-MM-dd.json".
  - **Import Data:**
    - Button sets `isImporting = true`.
    - `.fileImporter` modifier presents the system's file open sheet (allows only JSON).
    - `importData(from data: Data)`:
      - Uses `JSONDecoder` (with `iso8601` date strategy) to parse the selected JSON file into the same `Codable` structs used for export.
      - **Clears existing data:** Deletes all existing `ExerciseDefinition`s (which cascades).
      - Iterates through imported data, creating and inserting new `ExerciseDefinition`, `WorkoutRecord`, and `SetEntry` objects into `modelContext`, preserving their original IDs and relationships.
      - Calls `modelContext.save()` explicitly.
  - **Clear All Data:**
    - `showingClearConfirmation = true` presents an alert.
    - If confirmed, `clearAllData()` deletes all `ExerciseDefinition`s (cascading the deletion) and calls `modelContext.save()`.
  - **Database Statistics:** Displays counts of exercises, workout records, and set entries.
  - **Alerts:** Provides feedback for success/failure of operations.
- **Navigation Title:** "Data Management".

### 5.8. `AppIcon.swift` & `Views/AppIconPreviewView.swift`

- **`AppIcon.swift`:**
  - **Purpose:** A SwiftUI `View` that programmatically draws the app's custom icon.
  - **Design:** Features a gradient background (blue/teal), a stylized dumbbell (composed of `WeightPlate` subviews and a bar), and the text "STRENGTH LOG".
  - **`WeightPlate` struct:** A helper view to draw the circular weight plates of the dumbbell.
  - **`Color(hex:)` extension:** A helper to create `Color` instances from hex strings.
- **`Views/AppIconPreviewView.swift`:**
  - **Purpose:** A simple view to display a large preview of the `AppIcon`, intended for development and asset generation (e.g., taking a screenshot).
  - Includes instructions for using the screenshot as an app icon.

## 6. Key Functionalities & Features

### 6.1. Exercise Management

- **Adding:** Users can add new exercises via `ContentView`. A sheet prompts for the exercise name.
- **Editing:** Exercise names can be edited from the context menu on each exercise in `ContentView`.
- **Deleting:** Exercises can be deleted via swipe-to-delete in `ContentView`. This action cascades and deletes all associated workout records and sets.

### 6.2. Workout Logging

- **Session Creation:** From `ExerciseDetailView`, users can log a new workout using `WorkoutInputView`.
- **Set Entry:** Within `WorkoutInputView`, users log date, multiple sets with weight and reps.
- **1RM Calculation:**
  - `SetEntry` automatically calculates an estimated 1RM upon initialization and when `updateOneRepMax()` is called.
  - The formula `calculateOneRepMax(weight: Double, reps: Int)` in `Models/Extensions.swift` is used: if reps = 1, 1RM is the weight; otherwise, Epley formula ($1RM = \text{weight} \times (1 + \text{reps} / 30)$) is applied.

### 6.3. Progress Tracking

- `ProgressChartsView` allows users to visualize:
  - Estimated 1RM progression (best 1RM per session).
  - Training Volume progression (total volume per session).
- Features include exercise selection, chart type (1RM/Volume) selection, and time range filtering (1M, 3M, 6M, 1Y, All Time).
- Charts are interactive, showing details for tapped/dragged data points.

### 6.4. Data Editing

- **Set Editing:** In `WorkoutSessionDetailView`, users can tap a set to edit its weight and reps. The set's 1RM is recalculated upon saving.
- **Set Deletion:** Individual sets can be swipe-deleted from `WorkoutSessionDetailView`.
- **Workout Date Editing:** The date of a workout session can be edited from `WorkoutSessionDetailView`.
- **Workout Deletion:** Entire workout sessions can be deleted from `ExerciseDetailView` via context menu or swipe action.

### 6.5. Data Management

- Implemented in `DataManagementView`:
  - **Export:** All app data (exercises, workouts, sets) can be exported to a user-chosen location as a JSON file.
  - **Import:** Data can be imported from a previously exported JSON file. This action replaces all current data in the app.
  - **Clear All Data:** Allows users to delete all their data with a confirmation.

## 7. Configuration

### 7.1. SwiftData Model Configuration

- Defined in `StrengthLogApp.swift`.
- Schema includes `ExerciseDefinition`, `WorkoutRecord`, and `SetEntry`.
- `ModelConfiguration` uses `isStoredInMemoryOnly = false` for persistent storage. The default SQLite store is used by SwiftData.

### 7.2. Project Entitlements (`StrengthLog.entitlements`)

- `com.apple.security.app-sandbox: true`: Enables the App Sandbox.
- `com.apple.security.files.user-selected.read-only: true`: Allows the app to read files selected by the user (used by the file importer for JSON files). This might need to be `read-write` if the app were to save directly to user-selected locations without the system's file exporter sheet, but for current export/import, this setup is typical. The `.fileExporter` handles write permissions via its own mechanisms.

## 8. Performance Considerations & Optimizations

### 8.1. SwiftData Performance

- **Lazy Loading:** SwiftData typically loads data lazily, which is efficient.
- **`@Query`:** SwiftUI's `@Query` property wrapper is optimized for fetching and observing data changes efficiently.
- **Computed Properties:** Heavy computations in computed properties accessed frequently in lists (e.g., `totalVolume`, `bestOneRepMaxInSession`) could impact performance if data sets grow extremely large. However, for typical personal use, this is unlikely to be an issue. These are recalculated on demand.
- **Cascade Deletes:** While convenient, cascade deletes on large interconnected datasets can take time. This is generally managed well by SwiftData.
- **Explicit Saves:** `modelContext.save()` is called explicitly in `WorkoutInputView`, `ExerciseDetailView` (workout deletion), and `DataManagementView` to ensure data is written immediately after critical operations. This can provide more predictable behavior at the cost of a minor, usually imperceptible, delay compared to relying solely on SwiftData's autosave.

### 8.2. UI Responsiveness

- SwiftUI's declarative nature and diffing algorithm generally ensure responsive UI updates.
- Complex views with many elements or frequent updates should be profiled if sluggishness is observed.
- `ProgressChartsView` involves data filtering and chart rendering. For very large numbers of workout records, performance of filtering and chart generation could be a factor, but SwiftUI Charts are generally quite performant.

### 8.3. Data Handling

- **JSON Serialization/Deserialization:** The export/import feature involves parsing potentially large JSON files. This is done synchronously after the file is selected/before export begins. For extremely large files, this could block the main thread momentarily. Consider background processing for very large data operations if this becomes an issue.
- **Memory Usage:** Fetching large datasets into memory (e.g., all exercises for export) should be monitored if the app is intended to handle exceptionally large amounts of data. SwiftData's faulting mechanism helps mitigate this.

## 9. Inter-Component Interactions

- **`StrengthLogApp` -> `ContentView`:** `StrengthLogApp` sets up the `ModelContainer` and passes it to `ContentView` via the environment.
- **`ContentView` -> Feature Views:** Navigates to `WorkoutHistoryListView`, `ProgressChartsView`, `DataManagementView`.
- **`ContentView` -> `ExerciseDetailView`:** Passes the selected `ExerciseDefinition` to `ExerciseDetailView`.
- **`ExerciseDetailView` -> `WorkoutInputView`:** Presents `WorkoutInputView` as a sheet, passing the current `ExerciseDefinition`.
- **Views & `ModelContext`:** Most views interact with `@Environment(\.modelContext)` to fetch, create, edit, or delete SwiftData objects.
- **`@Query` & Data Flow:** Views using `@Query` automatically update when underlying SwiftData records change, ensuring UI consistency.
- **Data Propagation:**
  - New workout data from `WorkoutInputView` creates `WorkoutRecord` and `SetEntry` objects, linked to an `ExerciseDefinition`.
  - Changes in `WorkoutSessionDetailView` (editing sets/date) directly modify SwiftData objects, triggering UI updates in any view observing that data.
  - `ProgressChartsView` fetches data based on selected `ExerciseDefinition` and dynamically updates charts.
- **Relationship Management:** When new `WorkoutRecord`s or `SetEntry`s are created, they are explicitly linked to their parent objects (e.g., `newWorkoutRecord.setEntries.append(setEntry)`, `exerciseDefinition.workoutRecords.append(newWorkoutRecord)`) to ensure bi-directional relationships are correctly established if not automatically handled by SwiftData in all cases.

## 10. Real-World Use Cases

1.  **Adding a New Exercise:**
    - User taps "+" on `ContentView`.
    - Sheet appears, user types "Deadlift", taps "Save".
    - "Deadlift" appears in the "My Exercises" list.
2.  **Logging a Workout:**
    - User taps "Deadlift" in `ContentView`, navigates to `ExerciseDetailView`.
    - User taps "Add Workout" button.
    - `WorkoutInputView` appears. User selects date, enters sets (e.g., Set 1: 100kg, 5 reps; Set 2: 110kg, 3 reps).
    - User taps "Save Workout". View dismisses.
    - The new workout appears in `ExerciseDetailView`'s list and also in `WorkoutHistoryListView`.
3.  **Reviewing Workout History:**
    - User taps "Workout History" on `ContentView`.
    - `WorkoutHistoryListView` shows all workouts, most recent first.
    - User taps a specific workout to see `WorkoutSessionDetailView` with its sets.
4.  **Tracking Progress:**
    - User taps "Progress Charts" on `ContentView`.
    - `ProgressChartsView` appears. User selects "Deadlift" from picker.
    - User selects "1RM" chart type and "3 Months" time range.
    - Chart displays 1RM trend for Deadlifts over the last 3 months. User can tap points for details.
5.  **Correcting a Mistake:**
    - User navigates to a past workout in `WorkoutSessionDetailView`.
    - Realizes Set 2 was 115kg, not 110kg. Taps Set 2.
    - Edit Set sheet appears. User changes weight to 115, taps "Save".
    - Set details and session's `bestOneRepMaxInSession` (if affected) update.
6.  **Backing Up Data:**
    - User navigates to `DataManagementView`.
    - Taps "Export Data". System file save sheet appears.
    - User chooses location, saves `StrengthLog_Export_YYYY-MM-DD.json`.
7.  **Restoring Data (e.g., on a new device):**
    - User installs app, navigates to `DataManagementView`.
    - Taps "Import Data". System file open sheet appears.
    - User selects their backup JSON file.
    - App confirms, then replaces any existing data with the imported data.

## 11. Build & Deployment Notes

- **Target:** iOS.
- **Build System:** Standard Xcode build system.
- **Dependencies:** None outside of standard Apple frameworks (SwiftUI, SwiftData, Charts, UniformTypeIdentifiers).
- **App Icon:** The custom `AppIcon.swift` is for design and preview. For actual deployment, a rasterized version (e.g., PNGs generated from a screenshot of `AppIconPreviewView`) needs to be added to the `Assets.xcassets` catalog in the appropriate App Icon set.
- **Deployment:** Standard App Store submission process via App Store Connect.

## 12. Future Considerations / Potential Enhancements

- **Cloud Sync (iCloud):** Allow users to sync their data across multiple devices using iCloud and SwiftData's cloud capabilities.
- **More Advanced Charting:** Options for different chart types (bar charts for volume), comparing exercises, or more detailed analytics.
- **Workout Templates/Routines:** Allow users to create and save workout templates.
- **Rest Timers:** Integrated rest timers between sets.
- **Exercise Instructions/Media:** Ability to add notes, images, or videos to `ExerciseDefinition`s.
- **WatchOS App:** A companion Apple Watch app for quick logging.
- **Advanced Statistics:** More in-depth statistics like total volume per week/month, PR tracking over time for specific rep ranges, etc.
- **Localization:** Support for multiple languages.
- **Accessibility:** Further review and enhancements for accessibility features.
