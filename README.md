# StrengthLog: Technical Documentation

**Version:** 2.0 (Post-Phase 8 & Additional Features)
**Date:** May 18, 2025
**Document Purpose:** This document provides a comprehensive technical overview of the StrengthLog iOS application, intended for development teams, new developers onboarding to the project, or for future maintenance and enhancement purposes.

## 1. Introduction

### 1.1. Project Overview

StrengthLog is an iOS application designed for users to track their strength training workouts. It allows users to define exercises, log workout sessions (including sets, weight, and repetitions), calculate estimated 1 Rep Max (1RM), visualize progress over time through charts, and manage their workout data via import/export functionalities. The app features a detailed workout history with daily grouping and filtering capabilities.

### 1.2. Purpose

The primary goal of StrengthLog is to offer a simple, user-friendly, and focused tool for strength training enthusiasts to monitor their performance, track progress, and stay motivated. It emphasizes core mechanics like logging, 1RM estimation, volume tracking, and an intuitive way to review past workouts.

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

1.  **Data Entry:** Users input data through various views (e.g., `WorkoutInputView` for sets, `ContentView` for new exercises, `WorkoutSessionDetailView` for adding more sets).
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
  - `workoutRecords: [WorkoutRecord]` (One-to-Many with `WorkoutRecord`). Configured with `deleteRule: .cascade`.
- **Initialization:** `init(name: String, dateAdded: Date = Date())`

### 3.2. `WorkoutRecord.swift`

- **Purpose:** Represents a single workout session for a specific exercise on a particular date.
- **Fields:**
  - `id: UUID` (Primary key, unique)
  - `date: Date` (Date of the workout session)
- **Relationships:**
  - `exerciseDefinition: ExerciseDefinition?` (Many-to-One with `ExerciseDefinition`). Configured with `deleteRule: .nullify`.
  - `setEntries: [SetEntry]` (One-to-Many with `SetEntry`). Configured with `deleteRule: .cascade`. The order in this array generally reflects the order of set creation.
- **Computed Properties:**
  - `totalVolume: Double`: Calculates the total volume for the session ($\sum (\text{weight} \times \text{reps})$ across all `setEntries`).
  - `bestOneRepMaxInSession: Double` (extension): Calculates the highest `calculatedOneRepMax` from all its `setEntries`. Returns `0.0` if no sets are present.
- **Initialization:** `init(date: Date = Date(), exerciseDefinition: ExerciseDefinition? = nil)`

### 3.3. `SetEntry.swift`

- **Purpose:** Represents a single set performed within a `WorkoutRecord`.
- **Fields:**
  - `id: UUID` (Primary key, unique)
  - `weight: Double` (Weight lifted for the set)
  - `reps: Int` (Number of repetitions performed)
  - `calculatedOneRepMax: Double` (Estimated 1 Rep Max for this set)
- **Relationships:**
  - `workoutRecord: WorkoutRecord?` (Many-to-One with `WorkoutRecord`). Configured with `deleteRule: .nullify`.
- **Initialization:** `init(weight: Double, reps: Int, workoutRecord: WorkoutRecord? = nil)`
  - Calculates `calculatedOneRepMax` upon initialization using the modified Epley formula.
- **Methods:**
  - `updateOneRepMax()`: Recalculates `calculatedOneRepMax` using the global `calculateOneRepMax` function.

### 3.4. `Models/Extensions.swift`

- **Purpose:** Contains utility extensions and global helper functions.
- **Contents:**
  - `extension NumberFormatter`: Static properties `decimal` and `integer`.
  - `func calculateOneRepMax(weight: Double, reps: Int) -> Double`: Global Epley formula (handles 1-rep case).
  - `extension Calendar`: Helper functions `weekDateRange`, `monthDateRange`, `yearDateRange` for calculating date intervals.

### 3.5. Relationships and Cascade Rules

- **`ExerciseDefinition` to `WorkoutRecord`:** One-to-Many. Deleting an `ExerciseDefinition` cascades to delete all its `WorkoutRecord`s.
- **`WorkoutRecord` to `ExerciseDefinition`:** Many-to-One (optional).
- **`WorkoutRecord` to `SetEntry`:** One-to-Many. Deleting a `WorkoutRecord` cascades to delete all its `SetEntry`s.
- **`SetEntry` to `WorkoutRecord`:** Many-to-One (optional).

## 4. Core Application (`StrengthLogApp.swift`)

- Standard SwiftUI App entry point, sets up and injects the SwiftData `ModelContainer`.
- Schema includes `ExerciseDefinition`, `WorkoutRecord`, and `SetEntry`.
- No initial data preloading; users start with a blank slate.

## 5. User Interface (SwiftUI Views)

### 5.1. `ContentView.swift` (Main Navigation & Exercise Management)

- **Purpose:** Main navigation screen, lists exercises, and provides links to features.
- **Functionality:**
  - `NavigationSplitView` layout.
  - Links to `WorkoutHistoryListView`, `ProgressChartsView`, `DataManagementView`.
  - Lists `ExerciseDefinition`s, allowing addition (with name prompt), editing (name via context menu), and deletion (swipe-to-delete).
  - Each exercise navigates to `ExerciseDetailView`.

### 5.2. `ExerciseDetailView.swift` (struct within `ContentView.swift`)

- **Purpose:** Displays details for a selected `ExerciseDefinition`, including personal records and a list of its workouts.
- **Functionality:**
  - "Personal Records" card for best 1RM and best volume.
  - Lists `WorkoutRecord`s (sorted by date descending), allowing deletion via context menu/swipe.
  - "Add Workout" button presents `WorkoutInputView`.

### 5.3. `WorkoutInputView.swift`

- **Purpose:** Modal sheet for logging a new workout session for an exercise.
- **Functionality:**
  - `DatePicker` for workout date.
  - Input fields for weight and reps to add `TemporarySetEntry`s.
  - Lists temporary sets (supports deletion) and displays current total volume.
  - Saves the `WorkoutRecord` with its `SetEntry`s. Input fields for weight/reps are not cleared after adding a set to facilitate easier subsequent entries.

### 5.4. `WorkoutHistoryListView.swift`

- **Purpose:** Displays a filterable and navigable history of all workout sessions, grouped by day.
- **Key State & Data:**
  - `@Query(sort: [SortDescriptor(\WorkoutRecord.date, order: .reverse)]) var allWorkoutRecords`: Fetches all workout records.
  - `@State private var timeFilter: TimeFilter`: Enum (`.week`, `.month`, `.year`, `.allTime`) for filtering. Defaults to `.week`.
  - `@State private var currentDateRange: (start: Date, end: Date)`: The currently displayed date interval.
- **Functionality:**
  - **Time Period Selector:** Segmented `Picker` for `timeFilter`. Default is "Week".
  - **Date Range Navigation:** "Previous" and "Next" buttons to navigate through weeks, months, or years, depending on the active filter. Displays the current date range title.
  - **Daily Grouping:**
    - `displayWorkouts: [Date: [WorkoutRecord]]` computed property filters records by `currentDateRange` and groups them by the start of each day.
    - The list displays `DailySummaryRow` for each day with workouts, sorted chronologically (most recent day first).
  - **Navigation:** Each `DailySummaryRow` is a `NavigationLink` to `DailyWorkoutsView` for that specific day.
  - Handles empty states if no workouts are found in the selected period.
- **Navigation Title:** "Workout History".

### 5.5. `Views/DailyWorkoutsView.swift`

- **Purpose:** Displays all individual workout sessions that occurred on a specific selected day.
- **Key State & Data:**
  - `let date: Date`: The specific day for which to show workouts.
  - `@Query var workoutRecords: [WorkoutRecord]`: Fetches workout records filtered for the given `date` (start to end of day).
- **Functionality:**
  - Lists each `WorkoutRecord` for the day, showing exercise name, time, set count, and volume.
  - Each listed workout is a `NavigationLink` to `WorkoutSessionDetailView`.
- **Navigation Title:** Formatted date (e.g., "May 18, 2025").

### 5.6. `WorkoutSessionDetailView.swift`

- **Purpose:** Shows full details of a selected `WorkoutRecord`, allowing users to edit/delete individual sets, edit the workout date, and add new sets.
- **Key State & Data:**
  - `var workoutRecord: WorkoutRecord`: The workout session being detailed.
  - States for editing an existing set (`selectedSet`, `isEditingSet`, `editingWeight`, `editingReps`).
  - States for editing the workout date (`isEditingDate`, `editingDate`).
  - States for adding a new set (`newWeight`, `newReps`).
- **Functionality:**
  - Displays exercise name and workout date.
  - **Sets List:**
    - `sortedSets: [SetEntry]`: A computed property that sorts `workoutRecord.setEntries` based on their original order in the array (reflecting creation order, oldest first).
    - Lists sets using `sortedSets`. Each row shows weight, reps, and 1RM.
    - **Tap to Edit Set:** Presents a sheet for modifying weight/reps of an existing set. 1RM is updated.
    - **Swipe to Delete Set:** Allows deleting individual `SetEntry`s.
  - **Add New Set Section:**
    - `TextField`s for weight and reps for a new set.
    - "Add Set" button calls `addNewSet()`, which creates a new `SetEntry`, links it to the `workoutRecord`, and saves it. Input fields are cleared after adding.
  - **Total Volume Section:** Displays `workoutRecord.totalVolume`.
  - **Toolbar:** "Edit Date" button presents a sheet to modify `workoutRecord.date`.
- **Navigation Title:** "Session Details".

### 5.7. `ProgressChartsView.swift`

- **Purpose:** Provides visualization of 1RM and training volume trends.
- **Functionality:**
  - Pickers for exercise, chart type (1RM/Volume), and time range (1M, 3M, 6M, 1Y, All Time).
  - Interactive SwiftUI `Chart` displaying trends.
  - Handles empty states.

### 5.8. `Views/DataManagementView.swift`

- **Purpose:** Allows JSON export/import of all data and clearing all data.
- **Functionality:**
  - `.fileExporter` for JSON export.
  - `.fileImporter` for JSON import (replaces existing data).
  - Confirmation alert for clearing all data.
  - Displays database statistics.

### 5.9. `AppIcon.swift` & `Views/AppIconPreviewView.swift`

- Programmatic design of the app icon and a preview view for it.

## 6. Key Functionalities & Features

### 6.1. Exercise Management

- Adding, editing names, and deleting exercises. Deletion cascades.

### 6.2. Workout Logging

- **Session Creation:** Log new workouts via `WorkoutInputView`.
- **Set Entry:** Log date, multiple sets with weight and reps.
- **1RM Calculation:** Automatic 1RM calculation per set using Epley formula (handles 1-rep actual).

### 6.3. Workout History Review

- **Daily Grouping:** `WorkoutHistoryListView` groups workouts by day.
- **Filtering:** Filter history by Week (default), Month, Year, or All Time.
- **Period Navigation:** Navigate to previous/next week, month, or year.
- **Individual Session View:** Drill down from daily summary to `DailyWorkoutsView` (listing sessions for that day) and then to `WorkoutSessionDetailView` (specifics of one session).

### 6.4. Progress Tracking

- Interactive 1RM and Volume trend charts in `ProgressChartsView` with exercise and time range filters.

### 6.5. Data Editing

- **Set Editing:** Edit weight/reps of existing sets in `WorkoutSessionDetailView`. 1RM updates.
- **Set Deletion:** Delete individual sets in `WorkoutSessionDetailView`.
- **Adding Sets In-Session:** Add new sets directly within `WorkoutSessionDetailView`.
- **Set Order:** Sets in `WorkoutSessionDetailView` are displayed chronologically (oldest first, last added at the bottom).
- **Workout Date Editing:** Edit the date of a workout session.
- **Workout Deletion:** Delete entire workout sessions from `ExerciseDetailView`.

### 6.6. Data Management

- JSON export, JSON import (replaces current data), and clear all data functionalities.

## 7. Configuration

- SwiftData `ModelConfiguration` for persistent storage.
- App Sandbox and User Selected Files (read-only) entitlements.

## 8. Performance Considerations & Optimizations

- SwiftData lazy loading and `@Query` efficiency.
- Explicit `modelContext.save()` calls for predictable persistence.
- UI responsiveness through SwiftUI's declarative updates.
- JSON operations are synchronous; consider backgrounding for extremely large datasets if needed.

## 9. Inter-Component Interactions

- **`StrengthLogApp` -> `ContentView`**: Environment setup.
- **`ContentView` -> Feature Views**: Navigation to `WorkoutHistoryListView`, `ProgressChartsView`, `DataManagementView`, `ExerciseDetailView`.
- **`WorkoutHistoryListView` -> `DailyWorkoutsView` -> `WorkoutSessionDetailView`**: Navigation flow for exploring workout history.
- **`ExerciseDetailView` -> `WorkoutInputView`**: Sheet presentation for new workout logging.
- **`WorkoutSessionDetailView`**: Manages its own sheets for editing set/date.
- Views interact with `@Environment(\.modelContext)` and `@Query` for data operations and reactive UI.

## 10. Real-World Use Cases

1.  **Adding a New Exercise:** (As before)
2.  **Logging a Workout:** (As before)
3.  **Reviewing Workout History (New Flow):**
    - User taps "Workout History" on `ContentView`.
    - `WorkoutHistoryListView` shows workouts grouped by day, filtered by the current week. User sees "May 18, 2025 - 2 Workouts".
    - User taps "May 18, 2025". Navigates to `DailyWorkoutsView`.
    - `DailyWorkoutsView` lists the two sessions from May 18. User taps the "Deadlift" session.
    - Navigates to `WorkoutSessionDetailView` for that Deadlift session.
4.  **Filtering History:**
    - In `WorkoutHistoryListView`, user changes filter to "Month". List updates to show daily summaries for the current month.
    - User taps "Previous" to see daily summaries for the last month.
5.  **Tracking Progress:** (As before)
6.  **Correcting a Mistake & Adding a Forgotten Set:**
    - User navigates to a past workout in `WorkoutSessionDetailView`. Sets are listed with the first set at the top.
    - Realizes Set 2 was 115kg, not 110kg. Taps Set 2. Edits and saves.
    - Realizes they forgot a final set. Uses the "Add New Set" section in `WorkoutSessionDetailView` to add "Set 3: 100kg, 8 reps". The new set appears at the bottom of the list.
7.  **Backing Up Data:** (As before)
8.  **Restoring Data:** (As before)

## 11. Build & Deployment Notes

- **Target:** iOS.
- **Build System:** Standard Xcode build system.
- **Dependencies:** None outside of standard Apple frameworks (SwiftUI, SwiftData, Charts, UniformTypeIdentifiers).
- **App Icon:** Custom `AppIcon.swift` for design. Rasterized assets needed for `Assets.xcassets`.
- **Deployment:** Standard App Store submission.

## 12. Future Considerations / Potential Enhancements

- **Cloud Sync (iCloud)**
- **More Advanced Charting & Analytics**
- **Workout Templates/Routines**
- **Rest Timers**
- **Exercise Instructions/Media**
- **WatchOS App**
- **Localization**
- **Accessibility Enhancements**
