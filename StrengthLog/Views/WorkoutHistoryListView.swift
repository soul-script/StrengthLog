import SwiftUI
import SwiftData

struct WorkoutHistoryListView: View {
    @Query(sort: [SortDescriptor(\WorkoutRecord.date, order: .reverse)]) var allWorkoutRecords: [WorkoutRecord]
    
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
        VStack {
            // Time period selector
            HStack {
                Picker("Filter", selection: $timeFilter) {
                    ForEach(TimeFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: timeFilter) { oldValue, newValue in
                    updateDateRange(for: newValue)
                }
                .padding(.horizontal)
            }
            
            // Date range navigation
            if timeFilter != .allTime {
                HStack {
                    Button(action: {
                        navigateDate(forward: false)
                    }) {
                        Image(systemName: "chevron.left")
                            .padding(8)
                            .background(Color(.systemGray5))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text(dateTitle)
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: {
                        navigateDate(forward: true)
                    }) {
                        Image(systemName: "chevron.right")
                            .padding(8)
                            .background(Color(.systemGray5))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            
            // Workout list
            if displayWorkouts.isEmpty {
                ContentUnavailableView(
                    "No Workouts",
                    systemImage: "dumbbell",
                    description: Text("No workouts found in this time period")
                )
                .padding(.top, 50)
            } else {
                List {
                    ForEach(displayWorkouts.keys.sorted().reversed(), id: \.self) { day in
                        if let workouts = displayWorkouts[day] {
                            NavigationLink {
                                DailyWorkoutsView(date: day)
                            } label: {
                                DailySummaryRow(date: day, workouts: workouts)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Workout History")
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
    
    var totalSets: Int {
        workouts.reduce(0) { $0 + $1.setEntries.count }
    }
    
    var totalVolume: Double {
        workouts.reduce(0.0) { $0 + $1.totalVolume }
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
                
                Text("Volume: \(totalVolume, format: .number.precision(.fractionLength(1)))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
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
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: ExerciseDefinition.self, WorkoutRecord.self, SetEntry.self, configurations: config)
    
    // Add some sample data
    let exercise1 = ExerciseDefinition(name: "Bench Press")
    let exercise2 = ExerciseDefinition(name: "Squat")
    container.mainContext.insert(exercise1)
    container.mainContext.insert(exercise2)
    
    // Create records for different days
    let today = Date()
    let calendar = Calendar.current
    
    // Today workouts
    let morningWorkout = WorkoutRecord(date: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today)!, exerciseDefinition: exercise1)
    let eveningWorkout = WorkoutRecord(date: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: today)!, exerciseDefinition: exercise2)
    
    // Yesterday workout
    let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
    let yesterdayWorkout = WorkoutRecord(date: calendar.date(bySettingHour: 17, minute: 0, second: 0, of: yesterday)!, exerciseDefinition: exercise1)
    
    // Last week workout
    let lastWeek = calendar.date(byAdding: .day, value: -7, to: today)!
    let lastWeekWorkout = WorkoutRecord(date: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: lastWeek)!, exerciseDefinition: exercise2)
    
    container.mainContext.insert(morningWorkout)
    container.mainContext.insert(eveningWorkout)
    container.mainContext.insert(yesterdayWorkout)
    container.mainContext.insert(lastWeekWorkout)
    
    // Add sets
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
    
    return NavigationView {
        WorkoutHistoryListView()
    }
    .modelContainer(container)
} 