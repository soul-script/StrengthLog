import SwiftUI
import SwiftData

struct WorkoutHistoryListView: View {
    @Query(sort: [SortDescriptor(\WorkoutRecord.date, order: .reverse)]) var allWorkoutRecords: [WorkoutRecord]
    @EnvironmentObject private var themeManager: ThemeManager
    
    @State private var timeFilter: TimeFilter = .week
    @State private var currentDateRange: (start: Date, end: Date) = Calendar.current.weekDateRange(for: Date())
    
    enum TimeFilter: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        case allTime = "All Time"
        
        var id: String { self.rawValue }
    }
    
    var displayWorkouts: [Date: [WorkoutRecord]] {
        let calendar = Calendar.current
        
        // Filter records by the selected time period
        let filteredRecords: [WorkoutRecord]
        if timeFilter == .allTime {
            filteredRecords = allWorkoutRecords
        } else {
            filteredRecords = allWorkoutRecords.filter { record in
                (record.date >= currentDateRange.start && record.date < currentDateRange.end)
            }
        }
        
        // Group records by day
        var recordsByDay: [Date: [WorkoutRecord]] = [:]
        for record in filteredRecords {
            let startOfDay = calendar.startOfDay(for: record.date)
            if recordsByDay[startOfDay] == nil {
                recordsByDay[startOfDay] = []
            }
            recordsByDay[startOfDay]?.append(record)
        }
        
        return recordsByDay
    }
    
    var dateTitle: String {
        switch timeFilter {
        case .week:
            let dateFormat = Date.FormatStyle().month().day()
            return "\(currentDateRange.start.formatted(dateFormat)) - \(Calendar.current.date(byAdding: .day, value: -1, to: currentDateRange.end)!.formatted(dateFormat))"
        case .month:
            return currentDateRange.start.formatted(.dateTime.month().year())
        case .year:
            return currentDateRange.start.formatted(.dateTime.year())
        case .allTime:
            return "All Time"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Enhanced header section with background
            VStack(spacing: 16) {
                // Time period selector with enhanced styling
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                        Text("Time Period")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    
                    Picker("Filter", selection: $timeFilter) {
                        ForEach(TimeFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: timeFilter) { oldValue, newValue in
                        updateDateRange(for: newValue)
                    }
                }
                .padding(.horizontal, 20)
                
                // Enhanced date range navigation
                if timeFilter != .allTime {
                    VStack(spacing: 12) {
                        HStack {
                            Button(action: {
                                navigateDate(forward: false)
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.blue)
                                    .frame(width: 36, height: 36)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            
                            Spacer()
                            
                            VStack(spacing: 2) {
                                Text(dateTitle)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Text(timeFilter.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                navigateDate(forward: true)
                            }) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.blue)
                                    .frame(width: 36, height: 36)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Summary stats for the period
                        if !displayWorkouts.isEmpty {
                            HStack(spacing: 24) {
                                StatCard(
                                    icon: "calendar.badge.plus",
                                    title: "Days",
                                    value: "\(displayWorkouts.keys.count)",
                                    color: .green
                                )
                                
                                StatCard(
                                    icon: "dumbbell.fill",
                                    title: "Workouts",
                                    value: "\(displayWorkouts.values.flatMap { $0 }.count)",
                                    color: .blue
                                )
                                
                                StatCard(
                                    icon: "chart.bar.fill",
                                    title: "Total Sets",
                                    value: "\(displayWorkouts.values.flatMap { $0 }.reduce(0) { $0 + $1.setEntries.count })",
                                    color: .orange
                                )
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
            }
            .padding(.vertical, 16)
            .background(Color(.systemGroupedBackground))
            
            // Workout list with enhanced styling
            if displayWorkouts.isEmpty {
                Spacer()
                ContentUnavailableView(
                    "No Workouts",
                    systemImage: "dumbbell",
                    description: Text("No workouts found in this time period")
                )
                Spacer()
            } else {
                List {
                    ForEach(displayWorkouts.keys.sorted().reversed(), id: \.self) { day in
                        if let workouts = displayWorkouts[day] {
                            NavigationLink {
                                DailyWorkoutsView(date: day)
                            } label: {
                                EnhancedDailySummaryRow(date: day, workouts: workouts)
                            }
                            .listRowBackground(Color(.systemBackground))
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                    }
                }
                .listStyle(.plain)
                .background(Color(.systemGroupedBackground))
            }
        }
        .navigationTitle("Workout History")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            updateDateRange(for: timeFilter)
        }
    }
    
    private func updateDateRange(for filter: TimeFilter) {
        switch filter {
        case .week:
            currentDateRange = Calendar.current.weekDateRange(for: Date())
        case .month:
            currentDateRange = Calendar.current.monthDateRange(for: Date())
        case .year:
            currentDateRange = Calendar.current.yearDateRange(for: Date())
        case .allTime:
            // No specific range for "All Time"
            let distantPast = Date.distantPast
            let distantFuture = Date.distantFuture
            currentDateRange = (distantPast, distantFuture)
        }
    }
    
    private func navigateDate(forward: Bool) {
        let calendar = Calendar.current
        var dateComponent: Calendar.Component
        var value: Int
        
        switch timeFilter {
        case .week:
            dateComponent = .weekOfYear
            value = forward ? 1 : -1
        case .month:
            dateComponent = .month
            value = forward ? 1 : -1
        case .year:
            dateComponent = .year
            value = forward ? 1 : -1
        case .allTime:
            return // No navigation for "All Time"
        }
        
        if let newDate = calendar.date(byAdding: dateComponent, value: value, to: currentDateRange.start) {
            switch timeFilter {
            case .week:
                currentDateRange = calendar.weekDateRange(for: newDate)
            case .month:
                currentDateRange = calendar.monthDateRange(for: newDate)
            case .year:
                currentDateRange = calendar.yearDateRange(for: newDate)
            case .allTime:
                break // Should not happen
            }
        }
    }
}

// Helper struct for displaying daily summary
struct DailySummaryRow: View {
    let date: Date
    let workouts: [WorkoutRecord]
    @EnvironmentObject private var themeManager: ThemeManager
    
    var totalSets: Int {
        workouts.reduce(0) { $0 + $1.setEntries.count }
    }
    
    var totalVolume: Double {
        workouts.reduce(0.0) { $0 + $1.totalVolume(in: themeManager.weightUnit) }
    }
    
    var exercises: String {
        let exerciseNames = workouts.compactMap { $0.exerciseDefinition?.name }
        return exerciseNames.joined(separator: ", ")
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(date, format: .dateTime.day().month().year())
                    .font(.headline)
                
                Text(exercises)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(workouts.count) workouts, \(totalSets) sets")
                    .font(.subheadline)
                
                if let volumeLabel = volumeSummaryText {
                    Text(volumeLabel)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var volumeSummaryText: String? {
        let volumeValue = Int(totalVolume.rounded(.toNearestOrAwayFromZero))
        guard volumeValue > 0 else { return nil }
        let hasWeighted = workouts.contains { record in record.setEntries.contains { $0.isWeighted } }
        let hasBodyweight = workouts.contains { record in record.setEntries.contains { !$0.isWeighted } }
        if hasWeighted && hasBodyweight {
            return "Volume: \(volumeValue) \(themeManager.weightUnit.abbreviation) vol (mixed)"
        }
        if hasBodyweight && !hasWeighted {
            return "Volume: \(volumeValue) reps"
        }
        return "Volume: \(volumeValue) \(themeManager.weightUnit.abbreviation) vol"
    }
}

// StatCard component for displaying summary statistics
struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// Enhanced daily summary row with better visual design
struct EnhancedDailySummaryRow: View {
    let date: Date
    let workouts: [WorkoutRecord]
    @EnvironmentObject private var themeManager: ThemeManager
    
    var totalSets: Int {
        workouts.reduce(0) { $0 + $1.setEntries.count }
    }
    
    var totalVolume: Double {
        workouts.reduce(0.0) { $0 + $1.totalVolume(in: themeManager.weightUnit) }
    }
    
    var exercises: String {
        let exerciseNames = workouts.compactMap { $0.exerciseDefinition?.name }
        if exerciseNames.isEmpty {
            return "No exercises"
        }
        return exerciseNames.prefix(2).joined(separator: ", ") + (exerciseNames.count > 2 ? "..." : "")
    }
    
    var dayOfWeek: String {
        date.formatted(.dateTime.weekday(.wide))
    }
    
    var dayAndMonth: String {
        date.formatted(.dateTime.day().month(.abbreviated))
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Date section with circular background
            VStack(spacing: 4) {
                Text(dayOfWeek)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
                
                Text(dayAndMonth)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .frame(width: 60)
            
            // Workout summary
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                    
                    Text("\(workouts.count) workout\(workouts.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(totalSets) sets")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())
                }
                
                Text(exercises)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                if let volumeLabel = volumeSummaryText {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                        
                        Text(volumeLabel)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private var volumeSummaryText: String? {
        let volumeValue = Int(totalVolume.rounded(.toNearestOrAwayFromZero))
        guard volumeValue > 0 else { return nil }
        let hasWeightedSets = workouts.contains { record in record.setEntries.contains { $0.isWeighted } }
        let hasBodyweightSets = workouts.contains { record in record.setEntries.contains { !$0.isWeighted } }

        if hasWeightedSets && hasBodyweightSets {
            return "Volume: \(volumeValue) \(themeManager.weightUnit.abbreviation) vol (mixed)"
        }
        if hasBodyweightSets && !hasWeightedSets {
            return "Volume: \(volumeValue) reps"
        }
        return "Volume: \(volumeValue) \(themeManager.weightUnit.abbreviation) vol"
    }
}

// Date range extensions for Calendar
extension Calendar {
    func weekDateRange(for date: Date) -> (start: Date, end: Date) {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        let startOfWeek = self.date(from: components)!
        let endOfWeek = self.date(byAdding: .day, value: 7, to: startOfWeek)!
        return (startOfWeek, endOfWeek)
    }
    
    func monthDateRange(for date: Date) -> (start: Date, end: Date) {
        let components = dateComponents([.year, .month], from: date)
        let startOfMonth = self.date(from: components)!
        let endOfMonth = self.date(byAdding: .month, value: 1, to: startOfMonth)!
        return (startOfMonth, endOfMonth)
    }
    
    func yearDateRange(for date: Date) -> (start: Date, end: Date) {
        let components = dateComponents([.year], from: date)
        let startOfYear = self.date(from: components)!
        let endOfYear = self.date(byAdding: .year, value: 1, to: startOfYear)!
        return (startOfYear, endOfYear)
    }
}

#Preview {
    WorkoutHistoryListViewPreviewFactory.make()
}

private enum WorkoutHistoryListViewPreviewFactory {
    @MainActor
    static func make() -> some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: ExerciseDefinition.self,
                 WorkoutRecord.self,
                 SetEntry.self,
                 AppSettings.self,
                 MajorMuscleGroup.self,
                 SpecificMuscle.self,
                 WorkoutCategoryTag.self,
                 ExerciseMajorContribution.self,
                 ExerciseSpecificContribution.self,
            configurations: config
        )
        
        let exercise1 = ExerciseDefinition(name: "Bench Press")
        let exercise2 = ExerciseDefinition(name: "Squat")
        container.mainContext.insert(exercise1)
        container.mainContext.insert(exercise2)
        
        let today = Date()
        let calendar = Calendar.current
        
        let morningWorkout = WorkoutRecord(date: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today)!, exerciseDefinition: exercise1)
        let eveningWorkout = WorkoutRecord(date: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: today)!, exerciseDefinition: exercise2)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let yesterdayWorkout = WorkoutRecord(date: calendar.date(bySettingHour: 17, minute: 0, second: 0, of: yesterday)!, exerciseDefinition: exercise1)
        let lastWeek = calendar.date(byAdding: .day, value: -7, to: today)!
        let lastWeekWorkout = WorkoutRecord(date: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: lastWeek)!, exerciseDefinition: exercise2)
        
        [morningWorkout, eveningWorkout, yesterdayWorkout, lastWeekWorkout].forEach { container.mainContext.insert($0) }
        
        [
            SetEntry(weight: 80, reps: 8, workoutRecord: morningWorkout),
            SetEntry(weight: 85, reps: 6, workoutRecord: morningWorkout),
            SetEntry(weight: 120, reps: 5, workoutRecord: eveningWorkout),
            SetEntry(weight: 75, reps: 10, workoutRecord: yesterdayWorkout),
            SetEntry(weight: 110, reps: 8, workoutRecord: lastWeekWorkout)
        ].forEach { set in
            container.mainContext.insert(set)
            set.workoutRecord?.setEntries.append(set)
        }
        
        let appSettings = AppSettings()
        container.mainContext.insert(appSettings)
        let themeManager = ThemeManager()
        themeManager.currentSettings = appSettings

        return NavigationStack {
            WorkoutHistoryListView()
        }
        .modelContainer(container)
        .environmentObject(themeManager)
    }
}
