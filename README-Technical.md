# StrengthLog: Technical Documentation

**Version:** 2.8 (MVVM + Repositories, Import Performance, Standardized Rounding)
**Date:** September 2025
**Document Purpose:** This document provides a comprehensive technical overview of the StrengthLog iOS application, intended for development teams, new developers onboarding to the project, or for future maintenance and enhancement purposes.

## 1. Introduction

### 1.1. Project Overview

StrengthLog is an iOS application designed for users to track their strength training workouts with comprehensive muscle tracking and categorization capabilities. It allows users to define exercises with detailed muscle contribution mapping, log workout sessions (including sets with weight and repetitions for weighted exercises, or reps-only for bodyweight exercises), calculate estimated 1 Rep Max (1RM) for weighted exercises, visualize progress over time through charts, and manage their workout data via import/export functionalities. The app features a sophisticated exercise taxonomy system with major muscle groups and specific muscle tracking, detailed workout history with daily grouping, filtering capabilities, template-based exercise creation, and seamless navigation throughout the app.

### 1.2. Purpose

The primary goal of StrengthLog is to offer a simple, user-friendly, and focused tool for strength training enthusiasts to monitor their performance, track progress, and stay motivated with comprehensive muscle engagement tracking. It emphasizes core mechanics like logging (both weighted and bodyweight exercises), 1RM estimation for weighted exercises, volume tracking with smart calculation methods, sophisticated muscle contribution analysis, template-based exercise creation, and an intuitive way to review past workouts with proper navigation flow. The advanced taxonomy system allows users to understand exactly which muscles are being targeted and in what proportions for optimal workout planning.

### 1.3. Technology Stack

- **UI Framework:** SwiftUI (for declarative UI development)
- **Data Persistence:** SwiftData (for on-device data storage and management)
- **Language:** Swift
- **Charting:** SwiftUI Charts framework
- **IDE:** Xcode (typically, though developed with AI assistance via Cursor)
- **Target OS:** iOS

## 2. System Architecture

### 2.1. Architectural Pattern

StrengthLog adopts MVVM + Services + Repositories with dependency injection:

- **Models:** SwiftData `@Model` classes (`ExerciseDefinition`, `WorkoutRecord`, `SetEntry`, taxonomy models, `AppSettings`). Domain services/utilities encapsulate core logic (e.g., `OneRepMaxCalculator`, `WeightConversionService`, `ContributionMetricsBuilder`).
- **Repositories:** Protocol-first data layer (`ExerciseRepository`, `WorkoutRepository`, `SettingsRepository`) with SwiftData-backed implementations that centralize reads/writes and simple queries. Injected via environment.
- **ViewModels:** One per major screen (`ContentViewModel`, `WorkoutHistoryViewModel`, `WorkoutInputViewModel`) own presentation state and intents; repositories handle persistence.
- **Views:** Thin SwiftUI Views bind to ViewModels and environment dependencies. Direct persistence calls from views are minimized.
- **Dependency Injection:** `RepositoryProvider` composes concrete repositories; environment keys expose them throughout the view tree. `ThemeManager` initializes from `SettingsRepository`.

### 2.2. Data Flow Overview

1.  **User Input:** Views capture user actions and forward intents to ViewModels.
2.  **ViewModel Orchestration:** ViewModels validate inputs, compute domain values, and call repositories.
3.  **Repository Persistence:** Repositories perform SwiftData reads/writes and save on the main actor.
4.  **Reactive Fetching:** Views use `@Query` to observe model changes; ViewModels merge with filter state to derive outputs.
5.  **UI Update:** SwiftUI re-renders on ViewModel `@Published` updates and `@Query` changes.
6.  **Relationships:** SwiftData relationships and cascade rules unchanged; repositories encapsulate mutations.

## 3. Data Models (SwiftData)

All data models are located in the `Models/` directory.

### 3.0. `AppSettings.swift` (Updated Version 2.6)

- **Purpose:** Stores user preferences and app settings, particularly theme and display preferences.
- **Fields:**
  - `id: UUID` (Primary key, unique)
  - `themeMode: ThemeMode` (Enum: `.light`, `.dark`, `.system`)
  - `accentColor: AppAccentColor` (Enum with 8 color options: `.blue`, `.green`, `.orange`, `.red`, `.purple`, `.pink`, `.indigo`, `.teal`)
  - `showAdvancedStats: Bool` (Toggle for advanced statistics display)
  - `defaultWeightUnit: WeightUnit` (Enum: `.kg`, `.lbs`) — now actively controls conversions and display units across the app via `ThemeManager`.
- **Initialization:** `init(themeMode: ThemeMode = .system, accentColor: AppAccentColor = .blue, showAdvancedStats: Bool = true, defaultWeightUnit: WeightUnit = .kg)`
- **Integration:** `ThemeManager` reads and persists this model to drive tinting, color scheme, weight unit selection, and analytics toggles.
- **Enums:**
  - `ThemeMode`: Provides `colorScheme` computed property for SwiftUI integration
  - `AppAccentColor`: Provides `color` computed property returning SwiftUI `Color` values
  - `WeightUnit`: For future weight unit preferences

### 3.1. `ExerciseDefinition.swift` (Updated Version 2.7)

- **Purpose:** Represents a specific type of exercise (e.g., "Squat", "Bench Press", "Pull-ups") with comprehensive muscle contribution tracking and category classification.
- **Fields:**
  - `id: UUID` (Primary key, unique)
  - `name: String` (Name of the exercise)
  - `dateAdded: Date` (Date the exercise was added)
- **Relationships:**
  - `categories: [WorkoutCategoryTag]` (Many-to-Many with `WorkoutCategoryTag`) - Exercise category assignments
  - `majorContributions: [ExerciseMajorContribution]` (One-to-Many with `ExerciseMajorContribution`). Configured with `deleteRule: .cascade` - Major muscle group contributions with percentages
  - `specificContributions: [ExerciseSpecificContribution]` (One-to-Many with `ExerciseSpecificContribution`). Configured with `deleteRule: .cascade` - Specific muscle contributions with percentages
  - `workoutRecords: [WorkoutRecord]` (One-to-Many with `WorkoutRecord`). Configured with `deleteRule: .cascade`.
- **Initialization:** `init(name: String, dateAdded: Date = Date.todayAtMidnight)` - All exercise creation timestamps are normalized to midnight.
- **Validation & Computed Properties:**
  - `totalMajorShare: Int` - Sum of all major muscle group contribution percentages
  - `totalSpecificShare: Int` - Sum of all specific muscle contribution percentages
  - `groupedSpecificShares() -> [UUID: Int]` - Groups specific muscle contributions by their parent major muscle group
  - `validatePercentages() -> [String]` - Validates that contribution percentages sum to 100% and relationships are consistent
- **Validation Strategy:**
  - Protocol-based validation system using `ContributionValidationStrategy`
  - Default validation ensures major and specific muscle contributions each sum to 100%
  - Validates that specific muscle contributions align with selected major muscle groups
  - Prevents orphaned specific muscle contributions

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
  - `func totalVolume(in unit: WeightUnit) -> Double`: Converts each set to the requested unit before computing session volume.
  - `func bestOneRepMax(in unit: WeightUnit) -> Double`: Converts the normalized 1RM to the preferred display unit.
- **Initialization:** `init(date: Date = Date.todayAtMidnight, exerciseDefinition: ExerciseDefinition? = nil)` - All workout session timestamps are normalized to midnight.

### 3.3. `SetEntry.swift`

- **Purpose:** Represents a single set performed within a `WorkoutRecord`.
- **Fields:**
  - `id: UUID` (Primary key, unique)
  - `weight: Double?` (Weight lifted in kilograms - optional to support bodyweight exercises)
  - `weightInPounds: Double?` (Mirrors the stored pounds value for the same set to avoid repeated conversions)
  - `reps: Int` (Number of repetitions performed)
  - `calculatedOneRepMax: Double` (Estimated 1 Rep Max for this set - 0.0 for bodyweight exercises)
- **Relationships:**
  - `workoutRecord: WorkoutRecord?` (Many-to-One with `WorkoutRecord`). Configured with `deleteRule: .nullify`.
- **Initialization:** `init(weight: Double? = nil, weightInPounds: Double? = nil, reps: Int, workoutRecord: WorkoutRecord? = nil)`
  - Normalizes both unit values through `WeightConversionService` to guarantee consistent kg↔lbs data.
  - Calculates `calculatedOneRepMax` upon initialization using `OneRepMaxCalculator`, or sets to 0.0 for bodyweight exercises.
- **Methods:**
  - `updateWeight(kilograms:pounds:)`: Accepts either unit and synchronizes both stored values while recalculating 1RM.
  - `weightValue(in:)`: Returns the stored kilogram or pound value, converting as needed.
  - `updateOneRepMax()`: Recomputes estimated max using sanitized weights.
  - `isWeighted`: Convenience flag indicating whether the set includes any external load.

### 3.4. `Models/Extensions.swift`

- **Purpose:** Contains utility extensions and global helper functions.
- **Contents:**
  - `extension NumberFormatter`: Static properties `decimal` and `integer`.
  - `OneRepMaxFormula` + `EpleyOneRepMaxFormula`: Protocol-driven design for max estimation strategies.
  - `OneRepMaxCalculator`: Centralized, rounding-aware calculator exposed via helper functions `calculateOneRepMax`, `normalizeOneRepMax`, and `convertOneRepMax`.
  - `WeightMeasurement`: Value type that carries paired kilogram/pound readings.
  - `WeightConversionService`: Shared, lossless conversion utility that sanitizes inputs and enforces consistent rounding.
  - `extension Calendar`: Helper functions `weekDateRange`, `monthDateRange`, `yearDateRange` for calculating date intervals.
  - `extension Date`: Date utilities for consistent timestamp handling:
    - `midnight`: Property that returns a new Date set to midnight (00:00:00.000) of the same day.
    - `todayAtMidnight`: Static property that creates a new Date set to midnight of today.

### 3.5. Exercise Taxonomy Models (`Models/ExerciseTaxonomy.swift`) - Version 2.7

#### 3.5.1. `MajorMuscleGroup.swift`

- **Purpose:** Represents primary muscle groups for exercise categorization (e.g., "Chest", "Back", "Shoulders").
- **Fields:**
  - `id: UUID` (Primary key, unique)
  - `name: String` (Unique name of the muscle group)
  - `info: String?` (Optional descriptive information)
- **Relationships:**
  - `specificMuscles: [SpecificMuscle]` (One-to-Many with `SpecificMuscle`). Configured with `deleteRule: .cascade`.
- **Initialization:** `init(name: String, info: String? = nil)`

#### 3.5.2. `SpecificMuscle.swift`

- **Purpose:** Represents individual muscles within major muscle groups (e.g., "Pectoralis Major", "Latissimus Dorsi").
- **Fields:**
  - `id: UUID` (Primary key, unique)
  - `name: String` (Unique name of the specific muscle)
  - `notes: String?` (Optional notes about the muscle)
- **Relationships:**
  - `majorGroup: MajorMuscleGroup?` (Many-to-One with `MajorMuscleGroup`)
- **Initialization:** `init(name: String, majorGroup: MajorMuscleGroup? = nil, notes: String? = nil)`

#### 3.5.3. `WorkoutCategoryTag.swift`

- **Purpose:** Represents exercise categories for classification (e.g., "Push", "Pull", "Squat").
- **Fields:**
  - `id: UUID` (Primary key, unique)
  - `name: String` (Unique name of the category)
- **Relationships:**
  - `exercises: [ExerciseDefinition]` (Many-to-Many with `ExerciseDefinition`)
- **Initialization:** `init(name: String)`

#### 3.5.4. `ExerciseMajorContribution.swift`

- **Purpose:** Maps exercises to major muscle groups with percentage contribution.
- **Fields:**
  - `id: UUID` (Primary key, unique)
  - `share: Int` (Percentage contribution, 0-100)
- **Relationships:**
  - `exercise: ExerciseDefinition?` (Many-to-One with `ExerciseDefinition`)
  - `majorGroup: MajorMuscleGroup?` (Many-to-One with `MajorMuscleGroup`)
- **Initialization:** `init(exercise: ExerciseDefinition, majorGroup: MajorMuscleGroup, share: Int)`
- **Validation:** Contribution percentages for an exercise must sum to 100%

#### 3.5.5. `ExerciseSpecificContribution.swift`

- **Purpose:** Maps exercises to specific muscles with percentage contribution.
- **Fields:**
  - `id: UUID` (Primary key, unique)
  - `share: Int` (Percentage contribution, 0-100)
- **Relationships:**
  - `exercise: ExerciseDefinition?` (Many-to-One with `ExerciseDefinition`)
  - `specificMuscle: SpecificMuscle?` (Many-to-One with `SpecificMuscle`)
- **Initialization:** `init(exercise: ExerciseDefinition, specificMuscle: SpecificMuscle, share: Int)`
- **Validation:** Contribution percentages for an exercise must sum to 100%

### 3.6. Enhanced WeightConversionService (`Models/Extensions.swift`) - Version 2.8

- **Purpose:** Centralized service for accurate kg/lbs conversions with consistent rounding and dual-unit storage.
- **Key Components:**
  - `WeightMeasurement`: Value type carrying paired kilogram/pound readings
  - `WeightConversionService`: Shared utility for deterministic conversion with input sanitization
  - Enhanced `OneRepMaxCalculator` with proper normalization and unit-aware calculations
- **Features:**
  - Consistent rounding rules (0.5 kg, 0.1 lbs precision)
  - Input sanitization and validation
  - Deterministic, idempotent conversions within the documented increments
  - Integration with `ThemeManager` for unit preferences

### 3.7. Relationships and Cascade Rules

- **`ExerciseDefinition` to `WorkoutRecord`:** One-to-Many. Deleting an `ExerciseDefinition` cascades to delete all its `WorkoutRecord`s.
- **`WorkoutRecord` to `ExerciseDefinition`:** Many-to-One (optional).
- **`WorkoutRecord` to `SetEntry`:** One-to-Many. Deleting a `WorkoutRecord` cascades to delete all its `SetEntry`s.
- **`SetEntry` to `WorkoutRecord`:** Many-to-One (optional).
- **`MajorMuscleGroup` to `SpecificMuscle`:** One-to-Many. Deleting a major muscle group cascades to delete its specific muscles.
- **`ExerciseDefinition` to `ExerciseMajorContribution`:** One-to-Many. Deleting an exercise cascades to delete its contributions.
- **`ExerciseDefinition` to `ExerciseSpecificContribution`:** One-to-Many. Deleting an exercise cascades to delete its contributions.
- **`WorkoutCategoryTag` to `ExerciseDefinition`:** Many-to-Many relationship.

## 4. Core Application (`StrengthLogApp.swift`)

- Standard SwiftUI App entry point, sets up and injects the SwiftData `ModelContainer`.
- **Schema:** `ExerciseDefinition`, `WorkoutRecord`, `SetEntry`, `AppSettings`, `MajorMuscleGroup`, `SpecificMuscle`, `WorkoutCategoryTag`, `ExerciseMajorContribution`, `ExerciseSpecificContribution`.
- **Repository Injection:** `ThemeAwareContentView` constructs a `RepositoryProvider` from the `ModelContext` and injects repositories via environment keys (`exerciseRepository`, `workoutRepository`, `settingsRepository`).
- **Theme Initialization:** `ThemeManager` initializes from `SettingsRepository` and is exposed via `@EnvironmentObject`; preferred color scheme and accent color are applied.
- **User-Controlled Data Seeding:** No automatic reference-data seeding at launch; seeding actions are initiated from Data Management.

## 5. User Interface (SwiftUI Views)

### 5.1. `ContentView.swift` (Main Navigation & Enhanced Exercise Management) (Updated Version 2.8)

- **Purpose:** Main navigation screen with enhanced exercise categorization, filtering, and visual organization.
- **Navigation:** Uses `NavigationStack` for proper back button behavior throughout the app.
- **Enhanced Functionality (Version 2.7):**
  - Links to `WorkoutHistoryListView`, `ProgressChartsView`, `DataManagementView`, and **Settings**.
  - **Advanced Exercise Management with Taxonomy System:**
    - **Category-Based Filtering:** Filter exercises by workout categories and muscle groups
    - **Exercise Grouping:** Smart grouping by primary muscle contributions and categories
    - **Enhanced Exercise Creation:** `ExerciseEditorView` with comprehensive muscle contribution tracking and category assignment
    - **Template-Based Creation:** Intelligent exercise creation using predefined templates with automatic muscle mapping
    - **Exercise Information Display:** Detailed views showing muscle contribution breakdowns and category assignments
  - **New UI Components:**
    - `ExerciseEditorView`: Comprehensive modal for creating/editing exercises with muscle contribution tracking
    - `ExerciseInfoView`: Detailed exercise information with contribution charts and category display
    - `ContributionBreakdownView`: Visual representation of muscle contribution percentages
    - `ReferenceDataManagerView`: Administrative interface for managing taxonomy entities
  - **Enhanced Display:**
    - Exercises organized by primary muscle contributions and categories
    - Visual contribution indicators and percentage displays
    - Category tags with proper relationship tracking
    - Muscle contribution validation feedback

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
  - **Enhanced Validation:** Validates reps for all exercises and routes weight parsing through `WeightConversionService` based on the active `ThemeManager.weightUnit`.
  - **Smart Display:** Lists temporary sets with appropriate labeling (bodyweight vs. weighted).
  - **Volume Calculation:** Displays total volume with context-aware formatting (reps for bodyweight, weight×reps for weighted, "mixed" for combined).
  - Saves the `WorkoutRecord` with its `SetEntry`s. Input fields for weight/reps are not cleared after adding a set to facilitate easier subsequent entries.
  - **Architecture:** Backed by `WorkoutInputViewModel` (validation, normalization, and persistence via `workoutRepository`).

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
  - **Unit-Aware Summaries:** Volume and 1RM badges pull from `WorkoutRecord.totalVolume(in:)`/`bestOneRepMax(in:)` using `ThemeManager.weightUnit`.
  - **Navigation:** Each `DailySummaryRow` is a `NavigationLink` to `DailyWorkoutsView` for that specific day.
  - Handles empty states if no workouts are found in the selected period.
- **Navigation Title:** "Workout History".
 - **Architecture:** Backed by `WorkoutHistoryViewModel` (time filters, derived groupings, and logging).

### 5.5. `Views/DailyWorkoutsView.swift`

- **Purpose:** Displays all individual workout sessions that occurred on a specific selected day.
- **Key State & Data:**
  - `let date: Date`: The specific day for which to show workouts.
  - `@Query var workoutRecords: [WorkoutRecord]`: Fetches workout records filtered for the given `date` (start to end of day).
- **Functionality:**
  - Lists each `WorkoutRecord` for the day, showing exercise name, time, set count, and volume.
  - Volume/1RM details leverage weight-unit conversions for accurate display.
  - Each listed workout is a `NavigationLink` to `WorkoutSessionDetailView`.
- **Navigation Title:** Formatted date (e.g., "May 18, 2025").

### 5.6. `WorkoutSessionDetailView.swift` (Updated Version 2.6)

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
  - `@EnvironmentObject var themeManager: ThemeManager`: Theme integration for consistent styling and unit preferences.
  - States for editing an existing set (`selectedSet`, `isEditingSet`, `editingWeight`, `editingReps`).
  - States for editing the workout date (`isEditingDate`, `editingDate`).
  - States for adding a new set (`newWeight`, `newReps`, `isBodyweightExercise`).
- **Enhanced Functionality:**
  - **Smart Header Display:** Exercise name with dumbbell icon, formatted date with calendar icon.
  - **Visual Summary Card:** Total volume and set count displayed in a styled background card.
    - Metrics dynamically convert using `ThemeManager.weightUnit`.
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
    - **Improved Validation:** Sanitizes weight input via `WeightConversionService` using the active `ThemeManager.weightUnit` before persisting both kg and lbs values.
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
  - Integrates with `ThemeManager` to format metrics in the preferred weight unit.

### 5.8. `Views/SettingsView.swift` (Updated Version 2.6)

- **Purpose:** Comprehensive settings interface for theme preferences and app configuration.
- **Key Features:**
  - **Theme Mode Selection:** Segmented picker for Light, Dark, or System theme modes with visual icons.
  - **Accent Color Picker:** 3x3 grid of color options with visual feedback and selection indicators.
  - **Advanced Statistics Toggle:** Option to enable/disable advanced statistics display.
  - **Weight Unit Preference:** Menu updates `ThemeManager.weightUnit`, triggering immediate kg↔lbs recalculations across charts, history, and detail views.
  - **App Information:** Version display and about section.
- **Navigation:** Uses `NavigationStack` with proper title and styling.
- **Integration:** Direct integration with `ThemeManager` for immediate theme application.

### 5.9. `Views/DataManagementView.swift` (Updated Version 2.8)

- **Purpose:** Allows JSON export/import of all data, manual restoration of reference taxonomy, and clearing data with enhanced categorization support.
- **Enhanced Functionality (Version 2.8):**
  - **Dual-Unit Export:** Serializes both kilogram and pound values for every `SetEntry`, preserving precise conversions.
  - **Minimal-Shape Import:** Heavy JSON decode runs off the main thread via a static decoder and `Task.detached`; `applyImport` and UI updates execute on the main actor.
  - **Resilient Import:** Reconstructs kg/lbs values using `WeightConversionService` while keeping backward compatibility with pre-unit-aware exports.
  - **Manual Reference Seeding:** Adds a "Restore Reference Data" action that invokes `ReferenceDataSeeder` on demand with success/error feedback.
  - **Settings Persistence:** Theme preferences included in export/import operations.
  - `.fileExporter` and `.fileImporter` retain categorization metadata and remain backward compatible with older payloads.
  - Confirmation alert for clearing all data and detailed database statistics.
  - **Observability:** Structured logging with `OSLog` for start/end and error paths.

### 5.10. `AppIcon.swift` & `Views/AppIconPreviewView.swift`

- Programmatic design of the app icon and a preview view for it.

### 5.11. `Views/ExerciseEditorView.swift` (Version 2.7)

- **Purpose:** Comprehensive exercise creation and editing interface with muscle contribution tracking and category management.
- **Architecture:** Modal sheet with form-based interface supporting both create and edit modes.
- **Key Features:**
  - **Dual Mode Support:** Create new exercises or edit existing ones with the same interface.
  - **Muscle Contribution Management:** Interactive UI for setting major muscle group and specific muscle percentages.
  - **Category Assignment:** Multi-select interface for assigning workout category tags.
  - **Template Integration:** Automatic population from `ExerciseTemplateProvider` for common exercises.
  - **Validation System:** Real-time validation ensuring contribution percentages sum to 100%.
  - **Form Sections:** Organized sections for basic details, categories, major groups, and specific muscles.
- **Data Management:**
  - `ExerciseEditorViewModel`: Handles state management and validation logic.
  - Real-time percentage calculation and error display.
  - Automatic save/update operations with proper relationship management.

### 5.12. `Views/ExerciseInfoView.swift` (Version 2.7)

- **Purpose:** Detailed exercise information display with muscle contribution visualization.
- **Features:**
  - **Exercise Overview:** Basic exercise information with category tags.
  - **Contribution Charts:** Visual representation of muscle group and specific muscle contributions.
  - **Category Display:** Color-coded category tags with proper grouping.
  - **Performance Metrics:** Integration with workout history for exercise-specific statistics.
- **UI Components:**
  - Pie charts for muscle contribution visualization.
  - Color-coded progress indicators for contribution percentages.
  - Expandable sections for detailed muscle breakdown.

### 5.13. `Views/ContributionBreakdownView.swift` (Version 2.7)

- **Purpose:** Reusable component for displaying muscle contribution breakdowns across the app.
- **Features:**
  - **Flexible Display:** Supports both major muscle groups and specific muscle breakdowns.
  - **Visual Indicators:** Progress bars and percentage displays for contribution visualization.
  - **Color Coding:** Consistent color scheme for muscle group identification.
  - **Compact Layout:** Optimized for embedding in other views.

### 5.14. `Views/ReferenceDataManagerView.swift` (Version 2.7)

- **Purpose:** Administrative interface for managing muscle groups, specific muscles, and exercise categories.
- **Features:**
  - **CRUD Operations:** Create, read, update, and delete reference data entities.
  - **Relationship Management:** Handle complex relationships between muscle groups and specific muscles.
  - **Validation:** Prevent deletion of entities that are referenced by exercises.
  - **Bulk Operations:** Mass deletion and creation operations with proper error handling.
  - **Import/Export:** Integration with data management for reference data backup and restore.
- **Sections:**
  - Major muscle group management with specific muscle relationships.
  - Specific muscle management with parent group assignment.
  - Exercise category management with exercise relationship tracking.

### 5.15. `Utilities/ThemeManager.swift` (Enhanced Version 2.8)

- **Purpose:** Enhanced centralized experience manager that drives theme, accent color, advanced stats visibility, default weight unit, and weight conversion integration.
- **Architecture:** `ObservableObject` that initializes from `SettingsRepository`; asynchronous bootstrap with improved weight conversion integration.
- **Enhanced Features (Version 2.7):**
  - **Weight Conversion Integration:** Direct integration with `WeightConversionService` for consistent unit handling.
  - **Reactive Weight Updates:** Automatic recalculation of displayed values when weight unit preferences change.
  - **Enhanced Theme State:** Improved state management for complex theme interactions.
  - **Async Initialization:** Non-blocking app startup with proper theme loading.
- **Key Features:**
  - **Reactive Updates:** Automatic UI updates when theme or weight preferences change.
  - **Environment Integration:** Available app-wide via SwiftUI environment values.
  - **Enhanced APIs:** `updateTheme`, `updateAccentColor`, `updateWeightUnit`, `updateAdvancedStats` with improved weight conversion handling.
  - **Unit Accessors:** Exposes computed properties (`weightUnit`, `colorScheme`, `accentColor`, `showAdvancedStats`) used across views for real-time rendering decisions.
- **Environment Integration:**
  - `ThemeManagerKey`: Environment key for dependency injection.
  - `ThemeAware` view modifier for consistent tinting.
  - Global access via `@Environment(\.themeManager)` and `@EnvironmentObject` injection from `ThemeAwareContentView`.
  - **Persistence Boundary:** All reads/writes go through `SettingsRepository`.

### 5.16. `Utilities/ExerciseTemplateProvider.swift` (Version 2.7)

- **Purpose:** Template-based exercise creation system with predefined muscle contributions for common exercises.
- **Architecture:** Static template provider with exercise name matching and alias resolution.
- **Features:**
  - **Exercise Templates:** Comprehensive library of common exercises with predefined muscle contributions.
  - **Intelligent Matching:** Name-based matching with alias support for exercise variations.
  - **Complete Metadata:** Each template includes canonical name, categories, major muscle shares, and specific muscle shares.
  - **Percentage Validation:** All templates provide validated contribution percentages that sum to 100%.
- **Template Structure:**
  - `ExerciseTemplate`: Data structure with exercise metadata and contribution mappings.
  - `MajorShare` and `SpecificShare`: Nested structures for muscle contribution data.
  - Alias mapping system for handling exercise name variations.
- **Integration:** Used by `ExerciseEditorView` for automatic population of muscle contributions during exercise creation.

### 5.17. `Utilities/ReferenceDataSeeder.swift` (Version 2.7)

- **Purpose:** User-controlled seeding system for default muscle groups, specific muscles, and exercise categories.
- **Features:**
  - **On-Demand Seeding:** User-initiated seeding instead of automatic initialization.
  - **Comprehensive Data:** Seeds major muscle groups, specific muscles with proper relationships, and exercise categories.
  - **Error Handling:** Robust error handling with user feedback for seeding operations.
  - **Idempotent Operations:** Safe to run multiple times without creating duplicates.
  - **Progress Feedback:** User notification of successful seeding operations.
- **Data Sets:**
  - Major muscle groups: Chest, Back, Shoulders, Arms, Legs, Core, etc.
  - Specific muscles: Pectoralis Major, Latissimus Dorsi, Anterior Deltoid, etc.
  - Exercise categories: Push, Pull, Squat, Hinge, Core, Cardio, etc.
- **Integration:** Invoked from `DataManagementView` with success/error feedback to users.

### 5.18. `Utilities/ContributionMetricsBuilder.swift` (Version 2.8)

- **Purpose:** Pure, deterministic builder that computes muscle contribution breakdowns for an exercise.
- **Outputs:** Major group slices (fractions), specific muscle slices grouped by major group, and validation messages.
- **Usage:** Consumed by `ExerciseInfoView` and the Exercise Detail section in `ContentView` to remove duplicate logic.

### 5.19. `Utilities/PreviewDependencies.swift` (Version 2.8)

- **Purpose:** Lightweight preview bootstrapper that wires a temporary `ModelContainer`, repositories via `RepositoryProvider`, and initializes `ThemeManager` from `SettingsRepository`.
- **Usage:** `dependencies.apply(to:)` in previews to ensure consistent environment setup without directly mutating `ThemeManager` internals.

## 6. Key Functionalities & Features

### 6.1. Enhanced Exercise Management & Taxonomy System

- **Comprehensive Exercise Creation:** Adding exercises with complete muscle contribution mapping and category assignment.
- **Template-Based Creation:** Intelligent exercise creation using predefined templates with automatic muscle contribution population.
- **Advanced Editing:** Modify exercise names, muscle contributions, and category assignments with validation.
- **Muscle Contribution Tracking:** Percentage-based tracking for both major muscle groups and specific muscles.
- **Category Management:** Multi-select category assignment with visual feedback.
- **Reference Data Management:** User-controlled management of muscle groups, specific muscles, and exercise categories.
- **Validation System:** Real-time validation ensuring contribution percentages sum to 100%.
- **Safe Deletion:** Cascade deletion with referential integrity checks.

### 6.2. Enhanced Workout Logging

- **Session Creation:** Log new workouts via `WorkoutInputView` with bodyweight exercise support.
- **Flexible Set Entry:** Log date, multiple sets with weight and reps (weighted exercises) or reps only (bodyweight exercises).
- **Mixed Workouts:** Support for combining weighted and bodyweight sets in the same session.
- **Smart 1RM Calculation:** Uses `OneRepMaxCalculator` for rounded, stable estimates in kilograms and converts on demand for pounds. Bodyweight sets show 0.0 for 1RM.
- **Unit-Aware Logging:** Every set stores synchronized kg/lbs values, enabling accurate history summaries regardless of the active preference.

### 6.3. Improved Workout History Review

- **Daily Grouping:** `WorkoutHistoryListView` groups workouts by day.
- **Filtering:** Filter history by Week (default), Month, Year, or All Time.
- **Period Navigation:** Navigate to previous/next week, month, or year.
- **Seamless Navigation:** Fixed back button behavior throughout the navigation flow.
- **Individual Session View:** Drill down from daily summary to `DailyWorkoutsView` (listing sessions for that day) and then to `WorkoutSessionDetailView` (specifics of one session).

### 6.4. Progress Tracking

- Interactive 1RM and Volume trend charts in `ProgressChartsView` with exercise and time range filters.
- **Enhanced 1RM Charts:** Only considers weighted exercises for 1RM calculations and display.
- **Preference-Aware Metrics:** Summaries and axis labels convert values via `ThemeManager.weightUnit` for consistent kg or lbs presentation.

### 6.5. Enhanced Data Editing

- **Set Editing:** Edit weight/reps of existing sets in `WorkoutSessionDetailView`. Convert between weighted and bodyweight. 1RM updates automatically.
- **Set Deletion:** Delete individual sets in `WorkoutSessionDetailView`.
- **Flexible Set Addition:** Add new weighted or bodyweight sets directly within `WorkoutSessionDetailView`.
- **Set Order:** Sets in `WorkoutSessionDetailView` are displayed chronologically (oldest first, last added at the bottom).
- **Workout Date Editing:** Edit the date of a workout session.
- **Workout Deletion:** Delete entire workout sessions from `ExerciseDetailView`.

### 6.6. Advanced Data Management & Taxonomy Integration

- **Comprehensive Export/Import:** JSON export/import captures exercise taxonomy data, muscle contributions, category assignments, synchronized kg/lbs weights, and theme preferences with backward compatibility.
- **Taxonomy Data Management:** Complete backup and restoration of muscle groups, specific muscles, exercise categories, and contribution mappings.
- **User-Controlled Reference Seeding:** On-demand restoration of default muscle groups, specific muscles, exercise categories, and exercise templates with detailed user feedback.
- **Enhanced Database Statistics:** Detailed statistics including exercise counts by category, muscle group distributions, contribution data, and relationship integrity.
- **Reference Data Manager:** Administrative interface for managing all taxonomy entities with CRUD operations and validation.
- **Safe Operations:** Clear all data functionality with confirmation dialogs and referential integrity checks.
- **Template Integration:** Automatic seeding of exercise templates with predefined muscle contributions when reference data is restored.

## 7. Configuration

- SwiftData `ModelConfiguration` for persistent storage.
- App Sandbox and User Selected Files (read-only) entitlements.

## 8. Performance Considerations & Optimizations

- SwiftData lazy loading and `@Query` efficiency.
- Explicit `modelContext.save()` calls for predictable persistence in repositories.
- UI responsiveness through SwiftUI's declarative updates and ViewModel state isolation.
- **Enhanced Navigation:** `NavigationStack` usage throughout for better performance and user experience.
- **Import Off‑Main:** Heavy JSON decode runs off the main thread; only apply-import and UI updates occur on the main actor.
- **Deterministic Conversions:** Centralized `WeightConversionService` enforces 0.5 kg / 0.1 lb increments for stable, idempotent conversions.
- **Reduced Duplication:** `ContributionMetricsBuilder` consolidates contribution calculations across views.
- **Structured Logging:** `OSLog` instrumentation for import/export paths.

## 9. Inter-Component Interactions

- **`StrengthLogApp` -> `ContentView`**: Environment setup.
- **`ContentView` -> Feature Views**: Navigation to `WorkoutHistoryListView`, `ProgressChartsView`, `DataManagementView`, `ExerciseDetailView`.
- **Enhanced Navigation Flow:** `WorkoutHistoryListView` -> `DailyWorkoutsView` -> `WorkoutSessionDetailView` with proper back button behavior.
- **`ExerciseDetailView` -> `WorkoutInputView`**: Sheet presentation for new workout logging.
- **`ExerciseDetailView` -> `WorkoutSessionDetailView`**: Direct navigation to workout details.
- **`WorkoutSessionDetailView`**: Manages its own sheets for editing set/date with `NavigationStack`.
- Views interact with repositories (via environment) for data operations and use `@Query` for reactive observation.

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

## 12. Recent Updates (Version 2.8)

### 12.1. Exercise Taxonomy & Comprehensive Muscle Tracking Implementation

- **Complete Taxonomy System:** Implemented sophisticated exercise categorization with major muscle groups, specific muscles, and percentage-based contribution tracking.
- **New Data Models:**
  - `MajorMuscleGroup`: Primary muscle group categorization with cascade relationships.
  - `SpecificMuscle`: Individual muscle tracking within major groups.
  - `WorkoutCategoryTag`: Exercise category classification with many-to-many relationships.
  - `ExerciseMajorContribution` & `ExerciseSpecificContribution`: Percentage-based muscle contribution mapping.
- **Enhanced Exercise Management:**
  - **Comprehensive Exercise Editor:** Full-featured editor with muscle contribution tracking and category assignment.
  - **Template-Based Creation:** Intelligent exercise creation using predefined templates with automatic muscle mapping.
  - **Validation System:** Real-time validation ensuring contribution percentages sum to 100%.
  - **Exercise Information Views:** Detailed breakdowns with muscle contribution charts.
- **Reference Data Management:**
  - **User-Controlled Seeding:** On-demand restoration of default muscle groups, specific muscles, and exercise categories.
  - **Administrative Interface:** Complete CRUD operations for all taxonomy entities.
  - **Template Integration:** Automatic seeding of exercise templates with predefined contributions.

### 12.2. Enhanced Weight Conversion Architecture Implementation

- **WeightConversionService:** Centralized service for accurate kg/lbs conversions with consistent rounding and dual-unit storage.
- **Dual-Unit Storage:** Enhanced `SetEntry` model to store both kilogram and pound values with synchronized updates.
- **Weight Architecture Improvements:**
  - `WeightMeasurement`: Value type carrying paired kilogram/pound readings.
  - Enhanced `OneRepMaxCalculator` with proper normalization and unit-aware calculations.
  - Consistent rounding rules (0.5 kg, 0.1 lbs precision) with input sanitization.
- **Theme Manager Enhancement:**
  - Direct integration with `WeightConversionService` for consistent unit handling.
  - Reactive weight updates with automatic recalculation when preferences change.
  - Improved state management for complex theme and weight interactions.
- **UI Integration:**
  - Unit-aware calculations throughout all views with preference-based display.
  - Enhanced import/export with dual-unit data preservation.
  - Automatic conversion and display based on user weight unit preference.

### 12.3. User-Controlled Reference Data & App Architecture

- **Performance Optimization:** Removed automatic reference data seeding from app startup for improved launch performance.
- **User Control:** Moved reference data restoration to explicit user action in Data Management with detailed feedback.
- **Enhanced Data Management:**
  - Comprehensive database statistics with taxonomy breakdowns.
  - Safe deletion operations with referential integrity checks.
  - Advanced export/import with complete taxonomy data preservation.
- **Technical Improvements:**
  - Async theme initialization for non-blocking app startup.
  - Enhanced relationship management with proper cascade rules.
  - Improved error handling and user feedback throughout the taxonomy system.

### 12.4. MVVM + Repository Layer Adoption (Version 2.8)

- Introduced protocol-first repositories (`ExerciseRepository`, `WorkoutRepository`, `SettingsRepository`) with SwiftData-backed implementations.
- Injected repositories via environment using a `RepositoryProvider` composition root.
- Extracted ViewModels for major screens to isolate presentation logic and intents from Views.

### 12.5. Standardized Weight Rounding (Version 2.8)

- Removed precision options and legacy rounding. All weights normalize to 0.5 kg / 0.1 lb increments across the app and export/import paths.
- Ensures deterministic displays and idempotent conversions within the documented increments.

### 12.6. Minimal-Shape Import + Observability (Version 2.8)

- Heavy JSON decode now runs off the main thread; `applyImport` executes on the main actor.
- Added structured logging with `OSLog` for start/end and error telemetry.

### 12.7. Contribution Metrics Consolidation (Version 2.8)

- Introduced `ContributionMetricsBuilder` and refactored `ExerciseInfoView` and Exercise Detail section to reuse the builder, removing duplicate logic.

## 13. Previous Updates (Version 2.5)

### 13.1. Session Details UI Overhaul Implementation

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

## 14. Previous Updates (Version 2.4)

### 14.1. Exercise Categories & Muscle Groups Implementation (Legacy System - Replaced in v2.7)

- **Legacy Data Model:** Initial categorization system for exercises with enum-based visual properties (replaced by comprehensive taxonomy system in v2.7).
- **Previous Enums with Visual Properties (Now Deprecated):**
  - **`MuscleGroup`:** 12 primary muscle groups (Chest, Back, Shoulders, Arms, Legs, Glutes, Core, Cardio, Full Body, Flexibility, Functional, Other)
  - **`ExerciseCategory`:** 10 movement categories (Push, Pull, Squat, Hinge, Carry, Core, Cardio, Flexibility, Plyometric, Other)
  - **Visual Integration:** Each enum included display names, colors, SF Symbol icons, and descriptions
- **Legacy Exercise Management (Replaced in v2.7):**
  - **Basic Filtering:** Filter exercises by enum-based muscle groups with visual indicators
  - **Simple Grouping:** Automatic exercise grouping by single muscle group assignment
  - **Basic Creation/Editing:** Simple muscle group and category selection during exercise creation
  - **Visual Categorization:** Color-coded tags and icons for exercise identification
- **Legacy UI Components (Superseded in v2.7):**
  - `FilterOptionsView`: Basic muscle group filter interface
  - `AddExerciseView` & `EditExerciseView`: Simple exercise management modals (replaced by `ExerciseEditorView`)
  - `EnhancedExerciseRowView`: Exercise display with basic categorization tags
- **Legacy Data Management (Enhanced in v2.7):**
  - **Basic Export/Import:** Support for enum-based categorization data
  - **Simple Categorization:** Single muscle group and category assignment per exercise
  - **Basic Database Statistics:** Simple category and muscle group counts
- **Legacy User Experience (Improved in v2.7):**
  - **Basic Visual Organization:** Color-coded exercise organization
  - **Simple Filtering:** Single-criteria muscle group filtering
  - **Basic Categorization:** Enum-based exercise classification system
  - **Limited Discoverability:** Basic exercise organization without contribution tracking

## 15. Previous Updates (Version 2.3)

### 15.1. Dark Mode & Theme System Implementation

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

### 15.2. Comprehensive UI Enhancement Implementation

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

## 16. Previous Updates (Version 2.2)

### 16.1. Timestamp Normalization (Version 2.2)

- **Consistent Midnight Timestamps:** All exercise creation, workout logging, and set entry operations now use midnight (00:00:00.000) timestamps instead of current time.
- **Data Model Changes:** Updated `ExerciseDefinition` and `WorkoutRecord` initializers to default to midnight timestamps.
- **UI Display Consistency:** Modified `DailyWorkoutsView` to always display workout times as 00:00 regardless of timezone conversion.
- **Import/Export Compatibility:** Enhanced data import functions to normalize imported timestamps to midnight for consistency.
- **Utility Functions:** Added Date extension with `midnight` property and `todayAtMidnight` static property for consistent timestamp handling throughout the app.

## 17. Previous Updates (Version 2.1)

### 17.1. Bodyweight Exercise Support

- **Data Model Changes:** Made `SetEntry.weight` optional to support bodyweight exercises.
- **UI Enhancements:** Added bodyweight toggles throughout the app.
- **Smart Calculations:** Volume and 1RM calculations adapt to exercise type.
- **Export/Import:** Updated JSON structures to handle optional weight.

### 17.2. Navigation Improvements

- **Architecture Change:** Replaced `NavigationSplitView` with `NavigationStack` in main ContentView.
- **Modal Sheets:** Updated all modal presentations to use `NavigationStack`.
- **Back Button Fix:** Resolved issue where back button would skip to main page instead of previous screen.
- **Enhanced UX:** Added NavigationLinks to workout rows in ExerciseDetailView.

### 17.3. Backward Compatibility

- **Data Migration:** Existing data with weight values continues to work seamlessly.
- **Import Compatibility:** Can import both old (weight required) and new (weight optional) JSON formats.

## 18. Future Considerations / Potential Enhancements

- **Cloud Sync (iCloud)**
- **More Advanced Charting & Analytics**
- **Workout Templates/Routines**
- **Rest Timers**
- **Exercise Instructions/Media**
- **WatchOS App**
- **Localization**
- **Accessibility Enhancements**
- **Bodyweight Progression Tracking** (weighted pull-ups, progression to harder variations)
  - **Architecture:** Backed by `ContentViewModel` for filters, editor presentation, and delete flows. Uses `exerciseRepository` via environment. Modernized `onChange` handlers (iOS 17 two-parameter variant).
