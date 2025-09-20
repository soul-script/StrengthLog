# StrengthLog 💪

**StrengthLog** is a user-friendly iOS application designed to help you meticulously track your strength training workouts, monitor your progress, and achieve your fitness goals. Built with SwiftUI and SwiftData, it offers a clean interface and powerful features for a seamless logging experience.

## ✨ Features

- **Advanced Exercise Management & Comprehensive Taxonomy:**
  - Define and manage a custom list of your exercises with sophisticated muscle tracking and categorization.
  - **Exercise Taxonomy System:** Complete muscle tracking with both major muscle groups and specific muscle contributions.
  - **Major Muscle Groups:** Organize exercises by primary muscle groups (Chest, Back, Shoulders, Arms, Legs, Glutes, Core, Cardio, Full Body, Flexibility, Functional, Other).
  - **Specific Muscle Tracking:** Track individual muscle contributions (e.g., Pectoralis Major, Latissimus Dorsi, Anterior Deltoid) with percentage-based contribution tracking.
  - **Exercise Categories:** Classify exercises by movement patterns (Push, Pull, Squat, Hinge, Carry, Core, Cardio, Flexibility, Plyometric, Other).
  - **Visual Organization:** Color-coded exercise categories and muscle groups for quick identification.
  - **Smart Filtering:** Filter exercises by muscle group with visual indicators and exercise counts.
  - **Template-Based Creation:** Intelligent exercise creation using predefined templates with automatic muscle contribution mapping for common exercises.
  - **Enhanced Exercise Editor:** Comprehensive exercise editor with muscle contribution tracking, category assignment, and percentage validation.
  - **Contribution Validation:** Ensures muscle contribution percentages sum to 100% for accurate tracking.
  - **Exercise Information Views:** Detailed exercise breakdowns showing muscle contribution charts and category information.
  - **Reference Data Management:** User-controlled seeding of default muscle groups, specific muscles, and exercise categories.
- **Flexible Workout Logging:**
  - Log workout sessions for each exercise, including the date (automatically normalized to midnight for consistency).
  - **Weighted Exercises:** Record multiple sets with specific weight and repetitions.
  - **Bodyweight Exercises:** Log bodyweight exercises (pull-ups, push-ups, dips, etc.) with reps only - no weight required.
  - **Mixed Workouts:** Combine both weighted and bodyweight sets within the same workout session.
  - **Unit-Aware Logging:** Store both kilogram and pound values with automatic conversions that respect each user's preferred weight unit.
  - Automatic calculation of estimated 1 Rep Max (1RM) for weighted sets using the Epley formula (with special handling for 1-rep sets).
  - Smart volume calculation: weight × reps for weighted exercises, total reps for bodyweight exercises.
  - **Consistent Timestamps:** All workout dates are stored at midnight (00:00:00.000) for better organization and time zone consistency.
- **Comprehensive Workout History:**
  - View a detailed history of all your workout sessions.
  - **Daily Grouping:** Workouts are grouped by day for a clear overview. Tap a day to see all sessions from that day.
  - **Flexible Filters:** Filter your history by Week (default), Month, Year, or All Time.
  - **Period Navigation:** Easily navigate to the previous or next period (week, month, year) when filters are active.
  - **Seamless Navigation:** Improved back button behavior ensures you always return to the previous screen.
- **Enhanced Session Details:**
  - **Modern Interface:** Completely redesigned session details with improved visual hierarchy and user experience.
  - **Smart Summary Cards:** Visual overview showing total volume, set count, and exercise information at a glance.
  - **Numbered Set Display:** Sets displayed with numbered badges and clear weight/reps information.
  - **Clear Weight Display:** Weights are normalized to 0.5 kg / 0.1 lb and shown with up to one decimal place (e.g., 52.3 → 52.5 kg) for clarity and consistency.
  - **Interactive Set Management:** Tap any set to edit weight, reps, or convert between weighted and bodyweight.
  - **Streamlined Set Addition:** Enhanced form for adding new sets with improved input validation and visual feedback.
  - **Flexible Date Editing:** Modify workout dates with an intuitive graphical date picker.
  - **Smart Empty States:** Informative messages when no sets are recorded yet.
  - **Consistent Theming:** Full integration with app's theme system including accent colors and dark mode support.
- **Progress Visualization:**
  - Track your progress with interactive charts.
  - Select specific exercises to visualize trends.
  - Switch between charts for Estimated 1RM (weighted exercises only) and Training Volume.
  - Charts automatically adapt units and labels to match your preferred kilogram or pound display.
  - Filter chart data by various time ranges (1 Month, 3 Months, 6 Months, 1 Year, All Time).
  - Tap on data points in the chart to see specific values and dates.
- **Enhanced Data Management:**
  - **Advanced Export:** Securely back up all your workout data (exercises, workouts, sets, muscle contributions, taxonomy data, and theme preferences) to a JSON file with dual kilogram and pound storage for every set.
  - **Smart Import:** Restore your data from a previously exported JSON file with automatic taxonomy reconstruction and backward compatibility. (Note: Importing replaces existing data).
  - **Non‑Blocking Import:** Heavy JSON decode runs off the main thread; only data application and UI updates occur on the main thread to keep the app responsive.
  - **User-Controlled Reference Data:** On-demand restoration of default muscle groups, specific muscles, exercise categories, and exercise templates with user feedback.
  - **Reference Data Manager:** Comprehensive interface for managing muscle groups, specific muscles, and exercise categories with validation and relationship tracking.
  - **Enhanced Database Statistics:** View detailed statistics including exercise counts by category, muscle group distributions, and contribution data.
  - **Safe Data Operations:** Clear all data option with confirmation and referential integrity checks.
- **Modern & Customizable Interface:**
  - **Enhanced Visual Design:** Modern, visually appealing interface with improved visual hierarchy and consistent design language.
  - **Component Architecture:** Reusable UI components for consistent experience across all views.
  - **Color-Coded Interface:** Meaningful use of colors for better user guidance and visual communication.
  - **SF Symbols Integration:** Contextual system icons throughout the app for enhanced visual communication.
  - **Dark Mode Support:** Choose between Light, Dark, or System theme modes (follows device setting).
  - **Accent Colors:** Personalize your experience with 8 beautiful accent colors (Blue, Green, Orange, Red, Purple, Pink, Indigo, Teal).
  - **Instant Application:** Theme changes apply immediately without restarting the app.
  - **Unified Theme State:** A centralized theme manager keeps accent colors, weight units, and mode preferences in sync across every view.
  - **Persistent Preferences:** All theme settings are automatically saved and restored.
  - **Settings Interface:** Easy-to-use settings screen for customizing your experience.
- **Custom App Icon:** A unique, programmatically drawn app icon.

## 🛠 Technology Stack

- **UI Framework:** SwiftUI
- **Data Persistence:** SwiftData
- **Language:** Swift
- **Charting:** SwiftUI Charts
- **IDE:** Xcode
- **Target OS:** iOS

## 🚀 Getting Started

### Prerequisites

- Xcode (latest stable version recommended)
- An Apple Developer account (if you wish to run on a physical device)
- macOS

### Building and Running

1.  **Clone the repository:**
    ```bash
    git clone [Your-Repo-URL-Here]
    cd StrengthLog
    ```
2.  **Open the project:**
    Open `StrengthLog.xcodeproj` in Xcode.
3.  **Select a simulator or device:**
    Choose your target simulator (e.g., iPhone 15 Pro) or a connected physical device.
4.  **Run the app:**
    Click the "Play" button (or `Cmd+R`) in Xcode to build and run the application.

## 📈 Project Status

StrengthLog is currently feature-complete based on its initial and expanded scope, including robust workout logging with bodyweight exercise support, history tracking with improved navigation, progress visualization, comprehensive data management, and modern UI design.

Recent updates include:

- **MVVM + Repositories & DI (v2.8):** Introduced ViewModels for major screens and a repository layer over SwiftData with dependency injection via environment, improving testability, performance, and separation of concerns without changing UI behavior.
- **Standardized Weight Rounding (v2.8):** All weights normalize to documented increments (0.5 kg / 0.1 lb). Precision options and legacy modes were removed; conversions are deterministic and idempotent within these increments.
- **Faster, Safer Import (v2.8):** Implemented minimal-shape import: JSON decoding now occurs off the main thread with `OSLog` instrumentation; apply-import and UI state updates remain on the main thread.
- **De-duplicated Metrics (v2.8):** Added a pure `ContributionMetricsBuilder` used across exercise info/detail views to compute contribution breakdowns consistently.

- **Exercise Taxonomy & Enhanced Weight Management (v2.7):** Complete muscle tracking system with major muscle groups, specific muscle contributions, and percentage-based tracking. Enhanced weight conversion service with dual-unit storage and improved theme management architecture.
- **Comprehensive Muscle Tracking System (v2.7):** Added sophisticated exercise taxonomy with major muscle groups, specific muscles, exercise categories, and contribution tracking. Includes template-based exercise creation and validation systems.
- **Enhanced Weight Conversion Architecture (v2.7):** Implemented comprehensive WeightConversionService for accurate kg/lbs conversions, dual-unit storage in SetEntry models, and unit-aware calculations throughout the application.
- **User-Controlled Reference Data (v2.7):** Refactored automatic seeding to user-controlled restoration with dedicated reference data manager, improving app startup performance and giving users explicit control.
- **Global Weight Units & Theme Manager (v2.6):** Introduced a centralized ThemeManager, dual-unit set storage, and unit-aware analytics so every screen respects the user's kilogram or pound preference.
- **On-Demand Reference Data (v2.6):** Removed automatic seeding at launch in favor of a Data Management action that safely restores default categories and muscle groups on demand.
- **Session Details UI Overhaul (v2.5):** Complete redesign of workout session details with modern interface, smart summary cards, numbered set displays, enhanced editing capabilities, and full theme integration
- **Exercise Categories & Muscle Groups (v2.4):** Comprehensive exercise categorization system with 12 muscle groups and 10 exercise categories, featuring visual organization, smart filtering, and enhanced exercise management
- **Comprehensive UI Enhancement (v2.3):** Complete visual transformation from functional to modern and visually appealing interface while maintaining core simplicity
- **Dark Mode & Theme System (v2.3):** Complete theme customization with dark mode support, 8 accent colors, and instant theme switching
- **Modern Component Architecture (v2.3):** Reusable UI components (StatCard, EnhancedDailySummaryRow, ProgressStatCard, etc.) for consistent design across all views
- **Enhanced Visual Design (v2.3):** Improved visual hierarchy, color-coded interface, SF Symbols integration, and 8-point grid system
- **Timestamp Normalization (v2.2):** All workout dates and exercise creation times are now consistently stored and displayed at midnight (00:00:00.000) for better data organization and consistency across time zones
- **Bodyweight Exercise Support (v2.1):** Full support for logging exercises without weight (pull-ups, push-ups, etc.)
- **Improved Navigation (v2.1):** Fixed back button behavior throughout the app for consistent user experience
- **Enhanced Data Models (v2.1):** Updated to handle optional weight while maintaining backward compatibility

Future considerations for development can be found in the more detailed [Technical Documentation](README-Technical.md).

## 🤝 Contributing

Contributions are welcome! If you have ideas for improvements, new features, or find any bugs, please feel free to:

1.  Fork the repository.
2.  Create a new branch (`git checkout -b feature/YourAmazingFeature`).
3.  Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4.  Push to the branch (`git push origin feature/YourAmazingFeature`).
5.  Open a Pull Request.

Please make sure to update tests as appropriate and adhere to the existing coding style.

_(Optional: Add more specific contribution guidelines if you have them, e.g., related to issue tracking, coding standards, etc.)_

## 📄 License

MIT

---

Thank you for checking out StrengthLog! We hope it helps you on your fitness journey.
