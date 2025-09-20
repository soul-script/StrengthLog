import SwiftUI
import Charts
import SwiftData

struct ProgressChartsView: View {
    @Query var exerciseDefinitions: [ExerciseDefinition]
    @State private var selectedExercise: ExerciseDefinition? = nil
    @State private var selectedDataPoint: (date: Date, value: Double)? = nil
    @State private var chartType: ChartType = .oneRepMax
    @State private var timeRange: TimeRange = .allTime
    @EnvironmentObject private var themeManager: ThemeManager
    
    enum ChartType: String, CaseIterable, Identifiable {
        case oneRepMax = "1RM"
        case volume = "Volume"
        
        var id: String { self.rawValue }
    }
    
    enum TimeRange: String, CaseIterable, Identifiable {
        case month = "1 Month"
        case threeMonths = "3 Months"
        case sixMonths = "6 Months"
        case year = "1 Year"
        case allTime = "All Time"
        
        var id: String { self.rawValue }
        
        var days: Int? {
            switch self {
            case .month: return 30
            case .threeMonths: return 90
            case .sixMonths: return 180
            case .year: return 365
            case .allTime: return nil
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if exerciseDefinitions.isEmpty {
                    Spacer()
                    ContentUnavailableView(
                        "No exercises available",
                        systemImage: "chart.xyaxis.line",
                        description: Text("Add exercises first to see your progress charts")
                    )
                    Spacer()
                } else {
                    // Enhanced header section
                    VStack(spacing: 20) {
                        // Exercise selection with enhanced styling
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "dumbbell.fill")
                                    .foregroundColor(.blue)
                                Text("Exercise")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                            }
                            
                            Picker("Select Exercise", selection: $selectedExercise) {
                                ForEach(exerciseDefinitions, id: \.id) { exercise in
                                    Text(exercise.name).tag(Optional(exercise))
                                }
                            }
                            .pickerStyle(.menu)
                            .accentColor(.blue)
                        }
                        .padding(16)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                        
                        // Chart controls with enhanced styling
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .foregroundColor(.green)
                                    Text("Chart Type")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Spacer()
                                }
                                
                                Picker("Chart Type", selection: $chartType) {
                                    ForEach(ChartType.allCases) { type in
                                        Text(type.rawValue).tag(type)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "calendar.badge.clock")
                                        .foregroundColor(.orange)
                                    Text("Time Range")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Spacer()
                                }
                                
                                Picker("Time Range", selection: $timeRange) {
                                    ForEach(TimeRange.allCases) { range in
                                        Text(range.rawValue).tag(range)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                        .padding(16)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .onChange(of: selectedExercise) { _, _ in
                        selectedDataPoint = nil
                    }
                    .onChange(of: chartType) { _, _ in
                        selectedDataPoint = nil
                    }
                    .onChange(of: timeRange) { _, _ in
                        selectedDataPoint = nil
                    }
                    .onAppear {
                        if selectedExercise == nil, let firstExercise = exerciseDefinitions.first {
                            selectedExercise = firstExercise
                        }
                    }
                
                    // Chart section
                    if let exercise = selectedExercise {
                        let records = exercise.workoutRecords
                        if !records.isEmpty {
                            let filteredRecords = filterRecordsByTimeRange(records.sorted(by: { $0.date < $1.date }))
                            
                            if filteredRecords.isEmpty {
                                VStack(spacing: 16) {
                                    ContentUnavailableView(
                                        "No data in selected time range",
                                        systemImage: "chart.xyaxis.line",
                                        description: Text("Try selecting a different time range")
                                    )
                                }
                                .padding(.top, 40)
                            } else {
                                // Enhanced chart container
                                VStack(spacing: 0) {
                                    // Chart header with summary stats
                                    VStack(spacing: 16) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(chartTitle)
                                                    .font(.headline)
                                                    .fontWeight(.semibold)
                                                Text("\(filteredRecords.count) data points")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                        }
                                        
                                        // Quick stats
                                        HStack(spacing: 16) {
                                            ProgressStatCard(
                                                icon: "chart.line.uptrend.xyaxis",
                                                title: "Latest",
                                                value: formattedMetric(
                                                    chartType == .oneRepMax
                                                        ? convertOneRepMax(filteredRecords.last?.bestOneRepMaxInSession ?? 0, to: themeManager.weightUnit)
                                                        : (filteredRecords.last.map { $0.totalVolume(in: themeManager.weightUnit) } ?? 0)
                                                ),
                                                unit: metricUnitLabel,
                                                color: .blue
                                            )
                                            
                                            ProgressStatCard(
                                                icon: "arrow.up.right",
                                                title: "Best",
                                                value: formattedMetric(
                                                    chartType == .oneRepMax
                                                        ? convertOneRepMax(filteredRecords.map { $0.bestOneRepMaxInSession }.max() ?? 0, to: themeManager.weightUnit)
                                                        : (filteredRecords.map { $0.totalVolume(in: themeManager.weightUnit) }.max() ?? 0)
                                                ),
                                                unit: metricUnitLabel,
                                                color: .green
                                            )
                                            
                                            ProgressStatCard(
                                                icon: "chart.bar.fill",
                                                title: "Average",
                                                value: formattedMetric(
                                                    averageMetric(for: filteredRecords)
                                                ),
                                                unit: metricUnitLabel,
                                                color: .orange
                                            )
                                        }
                                    }
                                    .padding(20)
                                    .background(Color(.systemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 24)
                                    
                                    // Chart view
                                    VStack(spacing: 16) {
                                        chartView(for: filteredRecords)
                                            .frame(height: 300)
                                            .padding(.horizontal, 8)
                                        
                                        // Selected data point information
                                        if let selected = selectedDataPoint {
                                            HStack(spacing: 12) {
                                                Image(systemName: "info.circle.fill")
                                                    .foregroundColor(.blue)
                                                
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text("Data Point Details")
                                                        .font(.subheadline)
                                                        .fontWeight(.medium)
                                                    Text("Date: \(selected.date, format: .dateTime.day().month().year())")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                    Text("\(chartType == .oneRepMax ? "Estimated 1RM" : "Total Volume"): \(formattedMetric(selected.value)) \(metricUnitLabel)")
                                                        .font(.subheadline)
                                                        .fontWeight(.semibold)
                                                }
                                                Spacer()
                                            }
                                            .padding(16)
                                            .background(Color(.systemGray6))
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .padding(.horizontal, 20)
                                        }
                                        
                                        // Instructions
                                        Text("Tap on a data point for details")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                            .padding(.bottom, 20)
                                    }
                                    .padding(.top, 20)
                                }
                            }
                        } else {
                            VStack(spacing: 16) {
                                ContentUnavailableView(
                                    "No workout records",
                                    systemImage: "chart.xyaxis.line",
                                    description: Text("Log workouts for \(exercise.name) to see progress charts")
                                )
                            }
                            .padding(.top, 40)
                        }
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Progress Charts")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private func filterRecordsByTimeRange(_ records: [WorkoutRecord]) -> [WorkoutRecord] {
        guard let days = timeRange.days else {
            return records // All time, no filtering
        }
        
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return records.filter { $0.date >= cutoffDate }
    }
    
    private var chartTitle: String {
        guard let exercise = selectedExercise else { return "" }
        let typeLabel = chartType == .oneRepMax ? "Estimated 1RM Trend" : "Training Volume Trend"
        return "\(typeLabel) for \(exercise.name) (\(timeRange.rawValue))"
    }

    private var metricUnitLabel: String {
        chartType == .volume ? "\(themeManager.weightUnit.abbreviation) vol" : themeManager.weightUnit.abbreviation
    }
    
    private func formattedMetric(_ value: Double) -> String {
        String(Int(value.rounded(.toNearestOrAwayFromZero)))
    }

    private func averageMetric(for records: [WorkoutRecord]) -> Double {
        guard !records.isEmpty else { return 0 }
        let values: [Double]
        switch chartType {
        case .oneRepMax:
            values = records.map { convertOneRepMax($0.bestOneRepMaxInSession, to: themeManager.weightUnit) }
        case .volume:
            values = records.map { $0.totalVolume(in: themeManager.weightUnit) }
        }
        let total = values.reduce(0, +)
        return total / Double(values.count)
    }

    private func metricValue(for record: WorkoutRecord) -> Double {
        switch chartType {
        case .oneRepMax:
            return convertOneRepMax(record.bestOneRepMaxInSession, to: themeManager.weightUnit)
        case .volume:
            return record.totalVolume(in: themeManager.weightUnit)
        }
    }
    
    @ViewBuilder
    private func chartView(for records: [WorkoutRecord]) -> some View {
        Chart {
            ForEach(records) { record in
                let yValue = metricValue(for: record)
                
                LineMark(
                    x: .value("Date", record.date),
                    y: .value(chartType == .oneRepMax ? "Est. 1RM" : "Volume", yValue)
                )
                .foregroundStyle(chartType == .oneRepMax ? Color.blue : Color.green)
                .interpolationMethod(.catmullRom)
                
                PointMark(
                    x: .value("Date", record.date),
                    y: .value(chartType == .oneRepMax ? "Est. 1RM" : "Volume", yValue)
                )
                .foregroundStyle(chartType == .oneRepMax ? Color.blue : Color.green)
                .symbolSize(selectedDataPoint?.date == record.date ? 150 : 100)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month().day())
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .chartYScale(domain: .automatic(includesZero: true))
        .chartXScale(domain: .automatic)
        .chartLegend(.hidden)
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let xPosition = value.location.x
                                guard let date = proxy.value(atX: xPosition, as: Date.self) else { return }
                                
                                // Find the closest data point
                                var closestRecord: WorkoutRecord?
                                var minDistance: TimeInterval = .infinity
                                
                                for record in records {
                                    let distance = abs(record.date.timeIntervalSince(date))
                                    if distance < minDistance {
                                        minDistance = distance
                                        closestRecord = record
                                    }
                                }
                                
                                if let record = closestRecord {
                                    let value = metricValue(for: record)
                                    selectedDataPoint = (date: record.date, value: value)
                                }
                            }
                    )
            }
        }
    }
}

// Enhanced stat card component for progress charts
struct ProgressStatCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(unit)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ProgressChartsView_Previews: PreviewProvider {
    @MainActor // Ensures Core Data/SwiftData access is on the main thread for previews
    static func createSampleData(modelContext: ModelContext) {
        let sampleExercise1 = ExerciseDefinition(name: "Bench Press")
        let sampleExercise2 = ExerciseDefinition(name: "Squat")
        modelContext.insert(sampleExercise1)
        modelContext.insert(sampleExercise2)
        
        let record1Ex1 = WorkoutRecord(date: Calendar.current.date(byAdding: .day, value: -10, to: Date())!, exerciseDefinition: sampleExercise1)
        let set1Ex1Rec1 = SetEntry(weight: 80, reps: 5, workoutRecord: record1Ex1)
        modelContext.insert(record1Ex1) // Insert parent first
        modelContext.insert(set1Ex1Rec1) // Insert child
        // SwiftData should automatically link relationships if defined correctly.
        // If manual linking is needed (e.g. one-way or specific cases):
        // record1Ex1.setEntries.append(set1Ex1Rec1) 
        // sampleExercise1.workoutRecords.append(record1Ex1)

        let record2Ex1 = WorkoutRecord(date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, exerciseDefinition: sampleExercise1)
        let set1Ex1Rec2 = SetEntry(weight: 85, reps: 5, workoutRecord: record2Ex1)
        modelContext.insert(record2Ex1)
        modelContext.insert(set1Ex1Rec2)
        // record2Ex1.setEntries.append(set1Ex1Rec2)
        // sampleExercise1.workoutRecords.append(record2Ex1)
        
        // Add a record for the second exercise to test selection
        let record1Ex2 = WorkoutRecord(date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!, exerciseDefinition: sampleExercise2)
        let set1Ex2Rec1 = SetEntry(weight: 100, reps: 5, workoutRecord: record1Ex2)
        modelContext.insert(record1Ex2)
        modelContext.insert(set1Ex2Rec1)
        // record1Ex2.setEntries.append(set1Ex2Rec1)
        // sampleExercise2.workoutRecords.append(record1Ex2)
    }

    static var previews: some View {
        PreviewFactory.make()
    }
    
    private enum PreviewFactory {
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
            createSampleData(modelContext: container.mainContext)
            let dependencies = PreviewDependencies(container: container)
            return dependencies.apply(to: ProgressChartsView())
        }
    }
}
