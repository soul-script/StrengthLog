# StrengthLog: Technical Documentation

**Version:** 2.5 (Post-Session Details UI Overhaul)
**Date:** January 2025
**Document Purpose:** This document provides a comprehensive technical overview of the StrengthLog iOS application, intended for development teams, new developers onboarding to the project, or for future maintenance and enhancement purposes.

## 1. Introduction

### 1.1. Project Overview

StrengthLog is an iOS application designed for users to track their strength training workouts. It allows users to define exercises, log workout sessions (including sets with weight and repetitions for weighted exercises, or reps-only for bodyweight exercises), calculate estimated 1 Rep Max (1RM) for weighted exercises, visualize progress over time through charts, and manage their workout data via import/export functionalities. The app features a detailed workout history with daily grouping, filtering capabilities, and seamless navigation throughout the app.

### 1.2. Purpose

The primary goal of StrengthLog is to offer a simple, user-friendly, and focused tool for strength training enthusiasts to monitor their performance, track progress, and stay motivated. It emphasizes core mechanics like logging (both weighted and bodyweight exercises), 1RM estimation for weighted exercises, volume tracking with smart calculation methods, and an intuitive way to review past workouts with proper navigation flow.

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

### 3.0. `AppSettings.swift` (Version 2.3)

- **Purpose:** Stores user preferences and app settings, particularly theme and display preferences.
- **Fields:**
  - `id: UUID` (Primary key, unique)
  - `themeMode: ThemeMode` (Enum: `.light`, `.dark`, `.system`)
  - `accentColor: AppAccentColor` (Enum with 8 color options: `.blue`, `.green`, `.orange`, `.red`, `.purple`, `.pink`, `.indigo`, `.teal`)
  - `showAdvancedStats: Bool` (Toggle for advanced statistics display)
  - `defaultWeightUnit: WeightUnit` (Enum: `.kg`, `.lbs`)
- **Initialization:** `init(themeMode: ThemeMode = .system, accentColor: AppAccentColor = .blue, showAdvancedStats: Bool = true, defaultWeightUnit: WeightUnit = .kg)`
- **Enums:**
  - `ThemeMode`: Provides `colorScheme` computed property for SwiftUI integration
  - `AppAccentColor`: Provides `color` computed property returning SwiftUI `Color` values
  - `WeightUnit`: For future weight unit preferences

### 3.1. `ExerciseDefinition.swift` (Updated Version 2.4)

- **Purpose:** Represents a specific type of exercise (e.g., "Squat", "Bench Press", "Pull-ups") with enhanced categorization and muscle group classification.
- **Fields:**
  - `id: UUID` (Primary key, unique)
  - `name: String` (Name of the exercise)
  - `dateAdded: Date` (Date the exercise was added)
  - `muscleGroup: MuscleGroup` (Primary muscle group targeted - defaults to `.other`)
  - `category: ExerciseCategory` (Exercise movement category - defaults to `.other`)
- **Relationships:**
  - `workoutRecords: [WorkoutRecord]` (One-to-Many with `WorkoutRecord`). Configured with `deleteRule: .cascade`.
- **Initialization:** `init(name: String, muscleGroup: MuscleGroup = .other, category: ExerciseCategory = .other, dateAdded: Date = Date.todayAtMidnight)` - All exercise creation timestamps are normalized to midnight.
- **Enhanced Enums (Version 2.4):**
  - **`MuscleGroup`:** 12 primary muscle groups with visual properties:
    - `.chest`, `.back`, `.shoulders`, `.arms`, `.legs`, `.glutes`, `.core`, `.cardio`, `.fullBody`, `.flexibility`, `.functional`, `.other`
    - Each includes: `displayName`, `color` (SwiftUI Color), `icon` (SF Symbol), `description`
  - **`ExerciseCategory`:** 10 movement categories with visual properties:
    - `.push`, `.pull`, `.squat`, `.hinge`, `.carry`, `.core`, `.cardio`, `.flexibility`, `.plyometric`, `.other`
    - Each includes: `displayName`, `color` (SwiftUI Color), `icon` (SF Symbol), `description`
- **Convenience Methods:**
  - `muscleGroupDisplayName: String` - Returns formatted muscle group name
  - `categoryDisplayName: String` - Returns formatted category name

### 3.2. `WorkoutRecord.swift`

- **Purpose:** Represents a single workout session for a specific exercise on a particular date.
- **Fields:**
  - `id: UUID` (Primary key, unique)
  - `date: Date` (Date of the workout session)
- **Relationships:**
  - `exerciseDefinition: ExerciseDefinition?` (Many-to-One with `ExerciseDefinition`). Configured with `deleteRule: .nullify`.
  - `setEntries: [SetEntry]` (One-to-Many with `SetEntry`). Configured with `deleteRule: .cascade`. The order in this array generally reflects the order of set creation.
- **Computed Properties:**
  - `totalVolume: Double`: Calculates the total volume for the session. For weighted sets: $\sum (\text{weight} \times \text{reps})$. For bodyweight sets: $\sum \text{reps}$. Mixed sessions combine both calculations.
  - `bestOneRepMaxInSession: Double` (extension): Calculates the highest `calculatedOneRepMax` from all weighted `setEntries`. Returns `0.0` if no weighted sets are present.
- **Initialization:** `init(date: Date = Date.todayAtMidnight, exerciseDefinition: ExerciseDefinition? = nil)` - All workout session timestamps are normalized to midnight.

### 3.3. `SetEntry.swift`

- **Purpose:** Represents a single set performed within a `WorkoutRecord`.
- **Fields:**
  - `id: UUID` (Primary key, unique)
  - `weight: Double?` (Weight lifted for the set - optional to support bodyweight exercises)
  - `reps: Int` (Number of repetitions performed)
  - `calculatedOneRepMax: Double` (Estimated 1 Rep Max for this set - 0.0 for bodyweight exercises)
- **Relationships:**
  - `workoutRecord: WorkoutRecord?` (Many-to-One with `WorkoutRecord`). Configured with `deleteRule: .nullify`.
- **Initialization:** `init(weight: Double? = nil, reps: Int, workoutRecord: WorkoutRecord? = nil)`
  - Calculates `calculatedOneRepMax` upon initialization using the modified Epley formula for weighted exercises.
  - Sets `calculatedOneRepMax` to 0.0 for bodyweight exercises (when weight is nil).
- **Methods:**
  - `updateOneRepMax()`: Recalculates `calculatedOneRepMax` using the global `calculateOneRepMax` function for weighted exercises, or sets to 0.0 for bodyweight exercises.

### 3.4. `Models/Extensions.swift`

- **Purpose:** Contains utility extensions and global helper functions.
- **Contents:**
  - `extension NumberFormatter`: Static properties `decimal` and `integer`.
  - `func calculateOneRepMax(weight: Double, reps: Int) -> Double`: Global Epley formula (handles 1-rep case).
  - `extension Calendar`: Helper functions `weekDateRange`, `monthDateRange`, `yearDateRange` for calculating date intervals.
  - `extension Date`: Date utilities for consistent timestamp handling:
    - `midnight`: Property that returns a new Date set to midnight (00:00:00.000) of the same day.
    - `todayAtMidnight`: Static property that creates a new Date set to midnight of today.

### 3.5. Relationships and Cascade Rules

- **`ExerciseDefinition` to `WorkoutRecord`:** One-to-Many. Deleting an `ExerciseDefinition` cascades to delete all its `WorkoutRecord`s.
- **`WorkoutRecord` to `ExerciseDefinition`:** Many-to-One (optional).
- **`WorkoutRecord` to `SetEntry`:** One-to-Many. Deleting a `WorkoutRecord` cascades to delete all its `SetEntry`s.
- **`SetEntry` to `WorkoutRecord`:** Many-to-One (optional).

## 4. Core Application (`StrengthLogApp.swift`)

- Standard SwiftUI App entry point, sets up and injects the SwiftData `ModelContainer`.
- **Updated Schema (Version 2.3):** Includes `ExerciseDefinition`, `WorkoutRecord`, `SetEntry`, and `AppSettings`.
- **Theme Integration:** Uses `ThemeAwareContentView` wrapper to apply user theme preferences.
- No initial data preloading; users start with a blank slate.
- **Theme-Aware Architecture:** Automatic theme detection and application based on user preferences.

## 5. User Interface (SwiftUI Views)

### 5.1. `ContentView.swift` (Main Navigation & Enhanced Exercise Management) (Updated Version 2.4)

- **Purpose:** Main navigation screen with enhanced exercise categorization, filtering, and visual organization.
- **Navigation:** Uses `NavigationStack` for proper back button behavior throughout the app.
- **Enhanced Functionality (Version 2.4):**
  - Links to `WorkoutHistoryListView`, `ProgressChartsView`, `DataManagementView`, and **Settings**.
  - **Advanced Exercise Management:**
    - **Muscle Group Filtering:** Filter exercises by muscle group with "All" option
    - **Exercise Grouping:** Group exercises by muscle group for better organization
    - **Enhanced Exercise Creation:** `AddExerciseView` with muscle group and category selection
    - **Exercise Editing:** `EditExerciseView` for modifying exercise properties
    - **Visual Categories:** Color-coded muscle group and category tags on each exercise
  - **New UI Components:**
    - `FilterOptionsView`: Muscle group filter with visual indicators
    - `AddExerciseView`: Modal sheet for creating exercises with categorization
    - `EditExerciseView`: Modal sheet for editing exercise properties
    - `EnhancedExerciseRowView`: Exercise rows with category/muscle group visual tags
  - **Enhanced Display:**
    - Exercises grouped by muscle group when filter is "All"
    - Color-coded visual tags for immediate exercise identification
    - Improved exercise count indicators per muscle group

### 5.2. `ExerciseDetailView.swift` (struct within `ContentView.swift`)

- **Purpose:** Displays details for a selected `ExerciseDefinition`, including personal records and a list of its workouts.
- **Functionality:**
  - "Personal Records" card for best 1RM (weighted exercises only) and best volume.
  - Lists `WorkoutRecord`s (sorted by date descending) with NavigationLinks to `WorkoutSessionDetailView`.
  - Allows deletion via context menu/swipe.
  - "Add Workout" button presents `WorkoutInputView`.

### 5.3. `WorkoutInputView.swift`

- **Purpose:** Modal sheet for logging a new workout session for an exercise.
- **Navigation:** Uses `NavigationStack` instead of `NavigationView` for proper modal behavior.
- **Functionality:**
  - `DatePicker` for workout date.
  - **Bodyweight Toggle:** Option to mark exercise as bodyweight (hides weight input).
  - **Conditional Input Fields:** Weight input shown only for weighted exercises.
  - **Enhanced Validation:** Validates reps for all exercises, weight only for weighted exercises.
  - **Smart Display:** Lists temporary sets with appropriate labeling (bodyweight vs. weighted).
  - **Volume Calculation:** Displays total volume with context-aware formatting (reps for bodyweight, weight×reps for weighted, "mixed" for combined).
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

### 5.6. `WorkoutSessionDetailView.swift` (Updated Version 2.5)

- **Purpose:** Shows full details of a selected `WorkoutRecord` with a completely redesigned modern interface, allowing users to edit/delete individual sets, edit the workout date, and add new sets.
- **Navigation:** Uses `NavigationStack` for all modal sheets to ensure proper back button behavior.
- **Enhanced UI Design (Version 2.5):**
  - **Modern Interface:** Complete visual overhaul with improved hierarchy, spacing, and user experience.
  - **Smart Header Section:** Exercise information with dumbbell icon, improved typography, and date display with calendar icon.
  - **Summary Cards:** Visual overview showing total volume and set count in a styled card format.
  - **Enhanced Set Display:** Numbered badges for each set with accent color theming and clear information layout.
  - **Visual Feedback:** Chevron indicators for tappable items and proper empty state handling.
  - **Themed Integration:** Full `ThemeManager` integration with consistent accent color usage throughout.
- **Key State & Data:**
  - `var workoutRecord: WorkoutRecord`: The workout session being detailed.
  - `@Environment(\.themeManager) var themeManager`: Theme integration for consistent styling.
  - States for editing an existing set (`selectedSet`, `isEditingSet`, `editingWeight`, `editingReps`).
  - States for editing the workout date (`isEditingDate`, `editingDate`).
  - States for adding a new set (`newWeight`, `newReps`, `isBodyweightExercise`).
- **Enhanced Functionality:**
  - **Smart Header Display:** Exercise name with dumbbell icon, formatted date with calendar icon.
  - **Visual Summary Card:** Total volume and set count displayed in a styled background card.
  - **Enhanced Sets List:**
    - `sortedSets: [SetEntry]`: Chronologically ordered sets (oldest first).
    - **Numbered Display:** Each set shows with a numbered badge using theme accent color.
    - **Improved Information Layout:** Weight/reps with estimated 1RM display for weighted sets.
    - **Smart Empty States:** Informative messages when no sets are recorded.
    - **Interactive Elements:** Clear visual indicators for tappable items.
  - **Streamlined Set Addition:**
    - **Enhanced Form Design:** Better styling with rounded text fields and proper spacing.
    - **Icon Integration:** Relevant SF Symbols for weight and reps inputs.
    - **Visual Button States:** Styled add button with proper disabled state handling.
    - **Improved Validation:** Enhanced form validation with visual feedback.
  - **Enhanced Modal Sheets:**
    - **Consistent Styling:** All modals use themed headers with relevant icons.
    - **Better Form Layout:** Improved spacing and input field styling in edit sheets.
    - **Graphical Date Picker:** Enhanced date editing with `.graphical` style.
    - **Theme Integration:** Consistent button styling and accent color usage.
- **Navigation Title:** "Session Details".

### 5.7. `ProgressChartsView.swift`

- **Purpose:** Provides visualization of 1RM and training volume trends.
- **Functionality:**
  - Pickers for exercise, chart type (1RM/Volume), and time range (1M, 3M, 6M, 1Y, All Time).
  - **Enhanced 1RM Charts:** Only displays data for weighted exercises (filters out bodyweight sets).
  - Interactive SwiftUI `Chart` displaying trends.
  - Handles empty states.

### 5.8. `Views/SettingsView.swift` (Version 2.3)

- **Purpose:** Comprehensive settings interface for theme preferences and app configuration.
- **Key Features:**
  - **Theme Mode Selection:** Segmented picker for Light, Dark, or System theme modes with visual icons.
  - **Accent Color Picker:** 3x3 grid of color options with visual feedback and selection indicators.
  - **Advanced Statistics Toggle:** Option to enable/disable advanced statistics display.
  - **Weight Unit Preference:** Future-ready setting for kg/lbs preference.
  - **App Information:** Version display and about section.
- **Navigation:** Uses `NavigationStack` with proper title and styling.
- **Integration:** Direct integration with `ThemeManager` for immediate theme application.

### 5.9. `Views/DataManagementView.swift` (Updated Version 2.4)

- **Purpose:** Allows JSON export/import of all data and clearing all data with enhanced categorization support.
- **Enhanced Functionality (Version 2.4):**
  - **Updated Export/Import:** Full support for `muscleGroup` and `category` properties in JSON structures with backward compatibility.
  - **Settings Persistence:** Theme preferences included in export/import operations.
  - **Backward Compatibility:** Handles import of older JSON formats without muscle group/category data (defaults to `.other`).
  - **Enhanced Export Structure:** Includes muscle group and category information for comprehensive data backup.
  - `.fileExporter` for JSON export with complete exercise categorization data.
  - `.fileImporter` for JSON import (replaces existing data) with full backward compatibility.
  - Confirmation alert for clearing all data.
  - Displays database statistics including exercise categorization breakdown.

### 5.10. `AppIcon.swift` & `Views/AppIconPreviewView.swift`

- Programmatic design of the app icon and a preview view for it.

### 5.11. `Utilities/ThemeManager.swift` (Version 2.3)

- **Purpose:** Centralized theme management utility providing reactive theme updates throughout the app.
- **Architecture:** `ObservableObject` pattern with SwiftData integration for persistent theme preferences.
- **Key Features:**
  - **Reactive Updates:** Automatic UI updates when theme preferences change.
  - **Environment Integration:** Available app-wide via SwiftUI environment values.
  - **Convenience Methods:** Easy-to-use functions for updating theme preferences.
  - **Theme-Aware Components:** Provides computed properties for current theme settings.
- **Environment Integration:**
  - `ThemeManagerKey`: Environment key for dependency injection.
  - `ThemeAware` view modifier for consistent theme application.
  - Global access via `@Environment(\.themeManager)`.

## 6. Key Functionalities & Features

### 6.1. Exercise Management

- Adding, editing names, and deleting exercises. Deletion cascades.

### 6.2. Enhanced Workout Logging

- **Session Creation:** Log new workouts via `WorkoutInputView` with bodyweight exercise support.
- **Flexible Set Entry:** Log date, multiple sets with weight and reps (weighted exercises) or reps only (bodyweight exercises).
- **Mixed Workouts:** Support for combining weighted and bodyweight sets in the same session.
- **Smart 1RM Calculation:** Automatic 1RM calculation per weighted set using Epley formula. Bodyweight sets show 0.0 for 1RM.

### 6.3. Improved Workout History Review

- **Daily Grouping:** `WorkoutHistoryListView` groups workouts by day.
- **Filtering:** Filter history by Week (default), Month, Year, or All Time.
- **Period Navigation:** Navigate to previous/next week, month, or year.
- **Seamless Navigation:** Fixed back button behavior throughout the navigation flow.
- **Individual Session View:** Drill down from daily summary to `DailyWorkoutsView` (listing sessions for that day) and then to `WorkoutSessionDetailView` (specifics of one session).

### 6.4. Progress Tracking

- Interactive 1RM and Volume trend charts in `ProgressChartsView` with exercise and time range filters.
- **Enhanced 1RM Charts:** Only considers weighted exercises for 1RM calculations and display.

### 6.5. Enhanced Data Editing

- **Set Editing:** Edit weight/reps of existing sets in `WorkoutSessionDetailView`. Convert between weighted and bodyweight. 1RM updates automatically.
- **Set Deletion:** Delete individual sets in `WorkoutSessionDetailView`.
- **Flexible Set Addition:** Add new weighted or bodyweight sets directly within `WorkoutSessionDetailView`.
- **Set Order:** Sets in `WorkoutSessionDetailView` are displayed chronologically (oldest first, last added at the bottom).
- **Workout Date Editing:** Edit the date of a workout session.
- **Workout Deletion:** Delete entire workout sessions from `ExerciseDetailView`.

### 6.6. Enhanced Data Management

- **Updated Export/Import:** JSON export and import with full bodyweight exercise support and backward compatibility.
- **Clear All Data:** Functionality with confirmation dialogs.

## 7. Configuration

- SwiftData `ModelConfiguration` for persistent storage.
- App Sandbox and User Selected Files (read-only) entitlements.

## 8. Performance Considerations & Optimizations

- SwiftData lazy loading and `@Query` efficiency.
- Explicit `modelContext.save()` calls for predictable persistence.
- UI responsiveness through SwiftUI's declarative updates.
- **Enhanced Navigation:** `NavigationStack` usage throughout for better performance and user experience.
- JSON operations are synchronous; consider backgrounding for extremely large datasets if needed.

## 9. Inter-Component Interactions

- **`StrengthLogApp` -> `ContentView`**: Environment setup.
- **`ContentView` -> Feature Views**: Navigation to `WorkoutHistoryListView`, `ProgressChartsView`, `DataManagementView`, `ExerciseDetailView`.
- **Enhanced Navigation Flow:** `WorkoutHistoryListView` -> `DailyWorkoutsView` -> `WorkoutSessionDetailView` with proper back button behavior.
- **`ExerciseDetailView` -> `WorkoutInputView`**: Sheet presentation for new workout logging.
- **`ExerciseDetailView` -> `WorkoutSessionDetailView`**: Direct navigation to workout details.
- **`WorkoutSessionDetailView`**: Manages its own sheets for editing set/date with `NavigationStack`.
- Views interact with `@Environment(\.modelContext)` and `@Query` for data operations and reactive UI.

## 10. Real-World Use Cases

1.  **Adding a New Exercise:** (As before)
2.  **Logging a Weighted Workout:** (As before)
3.  **Logging a Bodyweight Workout:**
    - User taps "Add Workout" for "Pull-ups" exercise.
    - In `WorkoutInputView`, user toggles "Bodyweight Exercise" to ON.
    - Weight input field disappears. User enters reps (e.g., 12) and taps "Add Set".
    - Set appears as "12 reps (bodyweight)" with no 1RM displayed.
    - User adds more sets, saves workout. Volume shows total reps.
4.  **Logging a Mixed Workout:**
    - User logs "Chest Workout" with both weighted bench press sets and bodyweight push-up sets.
    - Volume displays as "mixed" combining weight×reps + total bodyweight reps.
5.  **Reviewing Workout History (Enhanced Flow):**
    - User taps "Workout History" on `ContentView`.
    - `WorkoutHistoryListView` shows workouts grouped by day, filtered by the current week.
    - User taps "May 18, 2025". Navigates to `DailyWorkoutsView`.
    - User taps a workout session. Navigates to `WorkoutSessionDetailView`.
    - **Back button works correctly:** Returns to `DailyWorkoutsView`, then to `WorkoutHistoryListView`, then to `ContentView`.
6.  **Converting Set Types:**
    - In `WorkoutSessionDetailView`, user taps a weighted set to edit.
    - User toggles "Bodyweight Exercise" to convert to bodyweight set.
    - Weight is removed, 1RM becomes 0.0, set displays as bodyweight.
7.  **Tracking Progress:** Enhanced charts show 1RM trends only for weighted exercises.
8.  **Data Management:** Export/import maintains full compatibility with both weighted and bodyweight exercises.

## 11. Build & Deployment Notes

- **Target:** iOS.
- **Build System:** Standard Xcode build system.
- **Dependencies:** None outside of standard Apple frameworks (SwiftUI, SwiftData, Charts, UniformTypeIdentifiers).
- **App Icon:** Custom `AppIcon.swift` for design. Rasterized assets needed for `Assets.xcassets`.
- **Deployment:** Standard App Store submission.

## 12. Recent Updates (Version 2.5)

### 12.1. Session Details UI Overhaul Implementation

- **Complete Interface Redesign:** Transformed `WorkoutSessionDetailView` from functional to modern, visually appealing interface while maintaining core functionality.
- **Enhanced Visual Hierarchy:**
  - **Smart Header Section:** Exercise name with dumbbell icon, improved typography with proper font weights.
  - **Summary Cards:** Visual overview cards showing total volume and set count with styled backgrounds.
  - **Themed Icons:** Contextual SF Symbols throughout with consistent accent color theming.
- **Improved Set Management:**
  - **Numbered Badges:** Each set displays with numbered circular badges using theme accent colors.
  - **Enhanced Information Layout:** Better spacing and typography for weight, reps, and 1RM display.
  - **Interactive Indicators:** Clear chevron indicators for tappable set items.
  - **Smart Empty States:** Informative messages when no sets are recorded yet.
- **Streamlined User Experience:**
  - **Enhanced Form Design:** Improved input fields with rounded text field styling and better validation feedback.
  - **Icon Integration:** Relevant SF Symbols for weight (scalemass) and reps (number) inputs.
  - **Visual Button States:** Styled "Add Set" button with proper enabled/disabled state styling.
  - **Better Modal Presentations:** Consistent themed headers across all sheet presentations.
- **Theme System Integration:**
  - **Full ThemeManager Integration:** Complete integration with app's theme system including accent colors and dark mode support.
  - **Consistent Styling:** All elements follow the app's design language and respond to theme changes.
  - **Enhanced Date Picker:** Graphical date picker style for better user experience.
- **Technical Improvements:**
  - **NavigationStack Usage:** Proper navigation structure for all modal presentations.
  - **Theme-Aware Components:** `.themeAware()` modifier application for consistent theming.
  - **Improved Form Validation:** Enhanced validation with visual feedback for better user guidance.

## 13. Previous Updates (Version 2.4)

### 13.1. Exercise Categories & Muscle Groups Implementation

- **Enhanced Data Model:** Comprehensive categorization system for exercises with visual properties and user-friendly organization.
- **New Enums with Visual Properties:**
  - **`MuscleGroup`:** 12 primary muscle groups (Chest, Back, Shoulders, Arms, Legs, Glutes, Core, Cardio, Full Body, Flexibility, Functional, Other)
  - **`ExerciseCategory`:** 10 movement categories (Push, Pull, Squat, Hinge, Carry, Core, Cardio, Flexibility, Plyometric, Other)
  - **Visual Integration:** Each enum includes display names, colors, SF Symbol icons, and descriptions
- **Enhanced Exercise Management:**
  - **Advanced Filtering:** Filter exercises by muscle group with visual indicators and exercise counts
  - **Smart Grouping:** Automatic exercise grouping by muscle group for better organization
  - **Enhanced Creation/Editing:** Complete muscle group and category selection during exercise creation and editing
  - **Visual Categorization:** Color-coded tags and icons for immediate exercise identification
- **UI Component Architecture:**
  - `FilterOptionsView`: Muscle group filter interface with visual feedback
  - `AddExerciseView` & `EditExerciseView`: Enhanced exercise management modals
  - `EnhancedExerciseRowView`: Exercise display with categorization tags
- **Data Management:**
  - **Backward Compatible Export/Import:** Full support for new categorization data with fallback for older formats
  - **Default Categorization:** Intelligent defaults for uncategorized exercises
  - **Enhanced Database Statistics:** Category and muscle group breakdown in data management
- **User Experience:**
  - **Visual Organization:** Color-coded exercise organization for faster navigation
  - **Intuitive Filtering:** Quick muscle group filtering with visual feedback
  - **Comprehensive Categorization:** Professional exercise classification system
  - **Enhanced Discoverability:** Better exercise organization and visual cues

## 14. Previous Updates (Version 2.3)

### 14.1. Dark Mode & Theme System Implementation

- **New Data Model:** Added `AppSettings` model with `ThemeMode`, `AppAccentColor`, and preference storage.
- **Theme Management:** Implemented centralized `ThemeManager` with reactive updates and environment integration.
- **Settings Interface:** Created comprehensive `SettingsView` with theme customization options.
- **App Integration:** Updated main app with theme-aware wrapper and automatic theme application.
- **Data Persistence:** Extended export/import functionality to include theme preferences.
- **User Experience:**
  - **Three Theme Modes:** Light, Dark, System (follows device setting)
  - **Eight Accent Colors:** Blue, Green, Orange, Red, Purple, Pink, Indigo, Teal
  - **Immediate Application:** Theme changes apply instantly without app restart
  - **Persistent Preferences:** All settings automatically saved and restored

### 14.2. Comprehensive UI Enhancement Implementation

- **Visual Design Transformation:** Complete overhaul of the application interface from functional but plain to modern and visually appealing while maintaining core simplicity.
- **Component Architecture:** Implemented reusable UI components for consistent design across all views:
  - `FeatureRowView` and `ExerciseRowView` for ContentView
  - `StatCard` for workout history statistics
  - `EnhancedDailySummaryRow` for daily workout summaries
  - `ProgressStatCard` for progress chart statistics
  - `DataStatRow` for data management statistics
  - `DayStatCard` and `EnhancedWorkoutRow` for daily workout views
- **Enhanced Views:**
  - **ContentView:** Modern interface with colored feature icons, exercise count badges, and improved visual hierarchy
  - **SettingsView:** Visual theme picker with animated color selection and enhanced layout
  - **WorkoutHistoryListView:** Statistics cards, enhanced headers, and improved daily summary display
  - **ProgressChartsView:** Better chart styling, progress statistics cards, and enhanced data presentation
  - **DataManagementView:** Modern card-based layout with enhanced action buttons and data statistics
  - **DailyWorkoutsView:** Day statistics cards and enhanced workout row display
  - **WorkoutInputView:** Enhanced form sections with colored icons and improved input styling
- **Design System:**
  - **8-Point Grid System:** Consistent spacing and layout standards throughout the app
  - **Color-Coded Interface:** Meaningful use of colors for visual communication and user guidance
  - **SF Symbols Integration:** Contextual system icons for better visual communication
  - **Subtle Visual Effects:** Tasteful shadows, backgrounds, and rounded corners for modern app feel
  - **Accessibility Preservation:** All enhancements maintain iOS accessibility standards and readability

## 15. Previous Updates (Version 2.2)

### 15.1. Timestamp Normalization (Version 2.2)

- **Consistent Midnight Timestamps:** All exercise creation, workout logging, and set entry operations now use midnight (00:00:00.000) timestamps instead of current time.
- **Data Model Changes:** Updated `ExerciseDefinition` and `WorkoutRecord` initializers to default to midnight timestamps.
- **UI Display Consistency:** Modified `DailyWorkoutsView` to always display workout times as 00:00 regardless of timezone conversion.
- **Import/Export Compatibility:** Enhanced data import functions to normalize imported timestamps to midnight for consistency.
- **Utility Functions:** Added Date extension with `midnight` property and `todayAtMidnight` static property for consistent timestamp handling throughout the app.

## 16. Previous Updates (Version 2.1)

### 16.1. Bodyweight Exercise Support

- **Data Model Changes:** Made `SetEntry.weight` optional to support bodyweight exercises.
- **UI Enhancements:** Added bodyweight toggles throughout the app.
- **Smart Calculations:** Volume and 1RM calculations adapt to exercise type.
- **Export/Import:** Updated JSON structures to handle optional weight.

### 16.2. Navigation Improvements

- **Architecture Change:** Replaced `NavigationSplitView` with `NavigationStack` in main ContentView.
- **Modal Sheets:** Updated all modal presentations to use `NavigationStack`.
- **Back Button Fix:** Resolved issue where back button would skip to main page instead of previous screen.
- **Enhanced UX:** Added NavigationLinks to workout rows in ExerciseDetailView.

### 16.3. Backward Compatibility

- **Data Migration:** Existing data with weight values continues to work seamlessly.
- **Import Compatibility:** Can import both old (weight required) and new (weight optional) JSON formats.

## 17. Future Considerations / Potential Enhancements

- **Cloud Sync (iCloud)**
- **More Advanced Charting & Analytics**
- **Workout Templates/Routines**
- **Rest Timers**
- **Exercise Instructions/Media**
- **WatchOS App**
- **Localization**
- **Accessibility Enhancements**
- **Bodyweight Progression Tracking** (weighted pull-ups, progression to harder variations)
