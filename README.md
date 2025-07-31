# StrengthLog 💪

**StrengthLog** is a user-friendly iOS application designed to help you meticulously track your strength training workouts, monitor your progress, and achieve your fitness goals. Built with SwiftUI and SwiftData, it offers a clean interface and powerful features for a seamless logging experience.

## ✨ Features

- **Exercise Management:**
  - Define and manage a custom list of your exercises.
  - Easily add new exercises as your routine evolves.
  - Edit exercise names or delete them if no longer needed.
- **Flexible Workout Logging:**
  - Log workout sessions for each exercise, including the date (automatically normalized to midnight for consistency).
  - **Weighted Exercises:** Record multiple sets with specific weight and repetitions.
  - **Bodyweight Exercises:** Log bodyweight exercises (pull-ups, push-ups, dips, etc.) with reps only - no weight required.
  - **Mixed Workouts:** Combine both weighted and bodyweight sets within the same workout session.
  - Automatic calculation of estimated 1 Rep Max (1RM) for weighted sets using the Epley formula (with special handling for 1-rep sets).
  - Smart volume calculation: weight × reps for weighted exercises, total reps for bodyweight exercises.
  - **Consistent Timestamps:** All workout dates are stored at midnight (00:00:00.000) for better organization and time zone consistency.
- **Comprehensive Workout History:**
  - View a detailed history of all your workout sessions.
  - **Daily Grouping:** Workouts are grouped by day for a clear overview. Tap a day to see all sessions from that day.
  - **Flexible Filters:** Filter your history by Week (default), Month, Year, or All Time.
  - **Period Navigation:** Easily navigate to the previous or next period (week, month, year) when filters are active.
  - **Seamless Navigation:** Improved back button behavior ensures you always return to the previous screen.
- **In-Depth Session Details:**
  - Drill down into individual workout sessions to see all logged sets.
  - Sets are displayed chronologically (oldest first, as they were performed).
  - Clear labeling for bodyweight sets vs. weighted sets.
  - Edit the weight or reps of any existing set, or convert between weighted and bodyweight.
  - Delete individual sets if logged incorrectly.
  - **Add New Sets:** Add more sets directly to a past or current session (weighted or bodyweight).
  - Modify the date of a workout session.
  - Smart volume display adapts to exercise type (mixed, bodyweight-only, or weighted-only).
- **Progress Visualization:**
  - Track your progress with interactive charts.
  - Select specific exercises to visualize trends.
  - Switch between charts for Estimated 1RM (weighted exercises only) and Training Volume.
  - Filter chart data by various time ranges (1 Month, 3 Months, 6 Months, 1 Year, All Time).
  - Tap on data points in the chart to see specific values and dates.
- **Data Management:**
  - **Export Data:** Securely back up all your workout data (exercises, workouts, sets, and theme preferences) to a JSON file with full bodyweight exercise support.
  - **Import Data:** Restore your data from a previously exported JSON file. (Note: Importing replaces existing data).
  - **Clear All Data:** Option to reset all app data with confirmation.
  - View database statistics (counts of exercises, workouts, sets).
- **Modern & Customizable Interface:**
  - **Enhanced Visual Design:** Modern, visually appealing interface with improved visual hierarchy and consistent design language.
  - **Component Architecture:** Reusable UI components for consistent experience across all views.
  - **Color-Coded Interface:** Meaningful use of colors for better user guidance and visual communication.
  - **SF Symbols Integration:** Contextual system icons throughout the app for enhanced visual communication.
  - **Dark Mode Support:** Choose between Light, Dark, or System theme modes (follows device setting).
  - **Accent Colors:** Personalize your experience with 8 beautiful accent colors (Blue, Green, Orange, Red, Purple, Pink, Indigo, Teal).
  - **Instant Application:** Theme changes apply immediately without restarting the app.
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
