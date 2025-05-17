import SwiftUI
import Charts
import SwiftData

struct ProgressChartsView: View {
    @Query var exerciseDefinitions: [ExerciseDefinition]
    @State private var selectedExercise: ExerciseDefinition? = nil
    @State private var selectedDataPoint: (date: Date, value: Double)? = nil
    @State private var chartType: ChartType = .oneRepMax
    @State private var timeRange: TimeRange = .allTime
    
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
        VStack(alignment: .leading, spacing: 20) {
            if exerciseDefinitions.isEmpty {
                ContentUnavailableView(
                    "No exercises available",
                    systemImage: "chart.xyaxis.line",
                    description: Text("Add exercises first to see your progress charts")
                )
            } else {
                Picker("Select Exercise", selection: $selectedExercise) {
                    ForEach(exerciseDefinitions, id: \.id) { exercise in
                        Text(exercise.name).tag(Optional(exercise))
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal)
                .onChange(of: selectedExercise) { _, _ in
                    // Reset selected data point when changing exercise
                    selectedDataPoint = nil
                }
                .onAppear {
                    if selectedExercise == nil, let firstExercise = exerciseDefinitions.first {
                        selectedExercise = firstExercise
                    }
                }
                
                HStack {
                    Picker("Chart Type", selection: $chartType) {
                        ForEach(ChartType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: .infinity)
                    
                    Picker("Time Range", selection: $timeRange) {
                        ForEach(TimeRange.allCases) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .padding(.horizontal)
                .onChange(of: chartType) { _, _ in
                    // Reset selected data point when changing chart type
                    selectedDataPoint = nil
                }
                .onChange(of: timeRange) { _, _ in
                    // Reset selected data point when changing time range
                    selectedDataPoint = nil
                }
                
                if let exercise = selectedExercise {
                    let records = exercise.workoutRecords
                    if !records.isEmpty {
                        let filteredRecords = filterRecordsByTimeRange(records.sorted(by: { $0.date < $1.date }))
                        
                        if filteredRecords.isEmpty {
                            ContentUnavailableView(
                                "No data in selected time range",
                                systemImage: "chart.xyaxis.line",
                                description: Text("Try selecting a different time range")
                            )
                        } else {
                            // Chart container
                            VStack(alignment: .leading, spacing: 10) {
                                Text(chartTitle)
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                chartView(for: filteredRecords)
                                    .frame(height: 250)
                                    .padding(.horizontal, 8)
                                
                                // Selected data point information
                                if let selected = selectedDataPoint {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text("Date: \(selected.date, format: .dateTime.day().month().year())")
                                                .font(.subheadline)
                                            Text("\(chartType == .oneRepMax ? "1RM" : "Volume"): \(selected.value, specifier: "%.1f")")
                                                .font(.subheadline.bold())
                                        }
                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                                }
                                
                                // Instructions
                                Text("Tap on a data point for details")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 4)
                            }
                        }
                    } else {
                        ContentUnavailableView(
                            "No workout records",
                            systemImage: "chart.xyaxis.line",
                            description: Text("Log workouts for \(exercise.name) to see progress charts")
                        )
                    }
                } else if !exerciseDefinitions.isEmpty {
                    Text("Please select an exercise to see progress.")
                        .padding()
                } else {
                    Text("No data available.")
                        .padding()
                }
            }
        }
        .padding(.vertical)
        .navigationTitle("Progress Charts")
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
    
    @ViewBuilder
    private func chartView(for records: [WorkoutRecord]) -> some View {
        Chart {
            ForEach(records) { record in
                let yValue = chartType == .oneRepMax ? record.bestOneRepMaxInSession : record.totalVolume
                
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
                                    let value = chartType == .oneRepMax ? record.bestOneRepMaxInSession : record.totalVolume
                                    selectedDataPoint = (date: record.date, value: value)
                                }
                            }
                    )
            }
        }
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
        // This is the more modern #Preview macro style. 
        // If your project uses the older PreviewProvider struct, the .modelContainer approach is fine.
        // For clarity and to avoid buildExpression errors, we separate data setup.
        
        // Setup for PreviewProvider struct:
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: ExerciseDefinition.self, WorkoutRecord.self, SetEntry.self, configurations: config)
        createSampleData(modelContext: container.mainContext) // Populate with data

        return ProgressChartsView()
            .modelContainer(container)
    }
} 