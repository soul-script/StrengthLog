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
        ScrollView {
            VStack(spacing: 0) {
                if workoutRecords.isEmpty {
                    Spacer()
                    ContentUnavailableView(
                        "No Workouts",
                        systemImage: "dumbbell",
                        description: Text("No workouts logged for this day")
                    )
                    Spacer()
                } else {
                    // Day summary header
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(formattedDate)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text(dayOfWeek)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\(workoutRecords.count) workout\(workoutRecords.count == 1 ? "" : "s")")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("\(totalSets) sets")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Quick stats
                        HStack(spacing: 16) {
                            DayStatCard(
                                icon: "dumbbell.fill",
                                title: "Exercises",
                                value: "\(uniqueExercises)",
                                color: .blue
                            )
                            
                            DayStatCard(
                                icon: "list.number",
                                title: "Total Sets",
                                value: "\(totalSets)",
                                color: .green
                            )
                            
                            DayStatCard(
                                icon: "chart.bar.fill",
                                title: "Volume",
                                value: String(format: "%.1f", totalVolume),
                                color: .orange
                            )
                        }
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // Workout list
                    LazyVStack(spacing: 12) {
                        ForEach(workoutRecords) { record in
                            NavigationLink {
                                WorkoutSessionDetailView(workoutRecord: record)
                            } label: {
                                EnhancedWorkoutRow(workoutRecord: record)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 20)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Daily Workouts")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var dayOfWeek: String {
        date.formatted(.dateTime.weekday(.wide))
    }
    
    private var totalSets: Int {
        workoutRecords.reduce(0) { $0 + $1.setEntries.count }
    }
    
    private var totalVolume: Double {
        workoutRecords.reduce(0.0) { $0 + $1.totalVolume }
    }
    
    private var uniqueExercises: Int {
        Set(workoutRecords.compactMap { $0.exerciseDefinition?.name }).count
    }
    
    private var formattedDate: String {
        date.formatted(.dateTime.day().month().year())
    }
}

// Day statistics card component
struct DayStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.subheadline)
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
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// Enhanced workout row component
struct EnhancedWorkoutRow: View {
    let workoutRecord: WorkoutRecord
    
    var formattedTime: String {
        workoutRecord.date.formatted(.dateTime.hour().minute())
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Time indicator
            VStack(spacing: 4) {
                Text(formattedTime)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
            }
            .frame(width: 60)
            
            // Workout details
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                    
                    Text(workoutRecord.exerciseDefinition?.name ?? "Unknown Exercise")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "list.number")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text("\(workoutRecord.setEntries.count) sets")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if workoutRecord.totalVolume > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            Text("Volume: \(workoutRecord.totalVolume, format: .number.precision(.fractionLength(1))) kg")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
            }
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
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
