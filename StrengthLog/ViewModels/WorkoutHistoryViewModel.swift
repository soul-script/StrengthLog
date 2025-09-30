import Foundation
import OSLog

@MainActor
final class WorkoutHistoryViewModel: ObservableObject {
    enum TimeFilter: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        case allTime = "All Time"

        var id: String { rawValue }
    }

    @Published var timeFilter: TimeFilter = .week {
        didSet { updateDateRange(for: timeFilter, referenceDate: Date()) }
    }
    @Published private(set) var currentDateRange: (start: Date, end: Date)
    @Published private(set) var displayWorkouts: [Date: [WorkoutRecord]] = [:]

    private let calendar: Calendar
    private var workoutRepository: WorkoutRepository?
    private var allWorkouts: [WorkoutRecord] = []
    private let logger = Logger(subsystem: "com.adityamishra.StrengthLog", category: "WorkoutHistoryViewModel")

    init(calendar: Calendar = .current) {
        self.calendar = calendar
        self.currentDateRange = calendar.weekDateRange(for: Date())
    }

    func configureIfNeeded(repository: WorkoutRepository) {
        guard workoutRepository == nil else { return }
        workoutRepository = repository
    }

    func updateWorkouts(_ workouts: [WorkoutRecord]) {
        allWorkouts = workouts
        refreshDisplay()
    }

    func refreshDisplay() {
        let filtered: [WorkoutRecord]
        switch timeFilter {
        case .allTime:
            filtered = allWorkouts
        case .week, .month, .year:
            filtered = allWorkouts.filter { record in
                record.date >= currentDateRange.start && record.date < currentDateRange.end
            }
        }

        let grouped = Dictionary(grouping: filtered) { record in
            calendar.startOfDay(for: record.date)
        }

        displayWorkouts = grouped
    }

    func updateDateRange(for filter: TimeFilter, referenceDate: Date) {
        switch filter {
        case .week:
            currentDateRange = calendar.weekDateRange(for: referenceDate)
        case .month:
            currentDateRange = calendar.monthDateRange(for: referenceDate)
        case .year:
            currentDateRange = calendar.yearDateRange(for: referenceDate)
        case .allTime:
            currentDateRange = (start: Date.distantPast, end: Date.distantFuture)
        }
        refreshDisplay()
    }

    func navigateDate(forward: Bool) {
        guard timeFilter != .allTime else { return }
        let delta = forward ? 1 : -1
        let reference: Date
        switch timeFilter {
        case .week:
            reference = calendar.date(byAdding: .weekOfYear, value: delta, to: currentDateRange.start) ?? Date()
        case .month:
            reference = calendar.date(byAdding: .month, value: delta, to: currentDateRange.start) ?? Date()
        case .year:
            reference = calendar.date(byAdding: .year, value: delta, to: currentDateRange.start) ?? Date()
        case .allTime:
            reference = Date()
        }
        updateDateRange(for: timeFilter, referenceDate: reference)
    }

    func dateTitle() -> String {
        switch timeFilter {
        case .week:
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            let endDate = calendar.date(byAdding: .day, value: -1, to: currentDateRange.end) ?? currentDateRange.end
            return "\(formatter.string(from: currentDateRange.start)) - \(formatter.string(from: endDate))"
        case .month:
            return currentDateRange.start.formatted(.dateTime.month().year())
        case .year:
            return currentDateRange.start.formatted(.dateTime.year())
        case .allTime:
            return "All Time"
        }
    }
}
