import SwiftUI
import SwiftData

struct DailyWorkoutsView: View {
    let date: Date
    @Query var workoutRecords: [WorkoutRecord]
    
    init(date: Date) {
        self.date = date
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = #Predicate<WorkoutRecord> { record in
            record.date >= startOfDay && record.date < endOfDay
        }
        let sortDescriptor = SortDescriptor(\WorkoutRecord.date, order: .forward)
        
        _workoutRecords = Query(filter: predicate, sort: [sortDescriptor])
    }
    
    var body: some View {
        List {
            ForEach(workoutRecords) { record in
                NavigationLink {
                    WorkoutSessionDetailView(workoutRecord: record)
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(record.exerciseDefinition?.name ?? "Unknown Exercise")
                                .font(.headline)
                            Text(record.date, format: .dateTime.hour().minute())
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("\(record.setEntries.count) sets")
                                .font(.subheadline)
                            Text("Volume: \(record.totalVolume, format: .number.precision(.fractionLength(1)))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle(formattedDate)
    }
    
    private var formattedDate: String {
        date.formatted(.dateTime.day().month().year())
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: ExerciseDefinition.self, WorkoutRecord.self, SetEntry.self, configurations: config)
    
    // Create sample data
    let exercise1 = ExerciseDefinition(name: "Bench Press")
    let exercise2 = ExerciseDefinition(name: "Squat")
    container.mainContext.insert(exercise1)
    container.mainContext.insert(exercise2)
    
    // Create records for the same day
    let today = Date()
    let morningWorkout = WorkoutRecord(date: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: today)!, exerciseDefinition: exercise1)
    let eveningWorkout = WorkoutRecord(date: Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: today)!, exerciseDefinition: exercise2)
    
    container.mainContext.insert(morningWorkout)
    container.mainContext.insert(eveningWorkout)
    
    // Add sets
    let set1 = SetEntry(weight: 80, reps: 8, workoutRecord: morningWorkout)
    let set2 = SetEntry(weight: 85, reps: 6, workoutRecord: morningWorkout)
    let set3 = SetEntry(weight: 120, reps: 5, workoutRecord: eveningWorkout)
    
    container.mainContext.insert(set1)
    container.mainContext.insert(set2)
    container.mainContext.insert(set3)
    
    morningWorkout.setEntries = [set1, set2]
    eveningWorkout.setEntries = [set3]
    
    return NavigationStack {
        DailyWorkoutsView(date: today)
    }
    .modelContainer(container)
} 