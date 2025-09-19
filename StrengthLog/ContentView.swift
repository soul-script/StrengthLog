//
//  ContentView.swift
//  StrengthLog
//
//  Created by Aditya Mishra on 5/13/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExerciseDefinition.name) private var exercises: [ExerciseDefinition]
    @Query(sort: \WorkoutCategoryTag.name) private var categoryTags: [WorkoutCategoryTag]
    @Query(sort: \MajorMuscleGroup.name) private var majorMuscleGroups: [MajorMuscleGroup]
    @State private var selectedExercise: ExerciseDefinition? = nil
    @State private var activeCategoryFilters: Set<UUID> = []
    @State private var activeMajorGroupFilter: UUID? = nil
    @State private var isPresentingExerciseEditor = false
    @State private var editorMode: ExerciseEditorView.Mode = .create
    @State private var exerciseToDelete: ExerciseDefinition? = nil
    @State private var showingExerciseDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Features").textCase(.uppercase).font(.subheadline).foregroundColor(.secondary)) {
                    FeatureRowView(
                        title: "Workout History",
                        subtitle: "View past workouts",
                        systemImage: "clock.fill",
                        color: .blue,
                        destination: AnyView(WorkoutHistoryListView())
                    )
                    
                    FeatureRowView(
                        title: "Progress Charts",
                        subtitle: "Track your improvements",
                        systemImage: "chart.xyaxis.line",
                        color: .green,
                        destination: AnyView(ProgressChartsView())
                    )
                    
                    FeatureRowView(
                        title: "Data Management",
                        subtitle: "Export & import data",
                        systemImage: "square.and.arrow.up.on.square.fill",
                        color: .orange,
                        destination: AnyView(DataManagementView())
                    )
                    
                    FeatureRowView(
                        title: "Settings",
                        subtitle: "Customize your experience",
                        systemImage: "gear",
                        color: .purple,
                        destination: AnyView(SettingsView())
                    )
                }
                if !categoryTags.isEmpty || !majorMuscleGroups.isEmpty {
                    filtersSection
                }
                
                Section(header: HStack {
                    Text("My Exercises")
                        .textCase(.uppercase)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(filteredExercises.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .clipShape(Capsule())
                }) {
                    if filteredExercises.isEmpty {
                        Text(isFilterActive ? "No exercises match the current filters." : "No exercises available yet.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    }

                    ForEach(filteredExercises) { exercise in
                        NavigationLink {
                            ExerciseDetailView(exercise: exercise)
                        } label: {
                            ExerciseRowView(exercise: exercise)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                exerciseToDelete = exercise
                                showingExerciseDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .onDelete(perform: deleteExercise)
                }
            }
            .navigationTitle("StrengthLog")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: promptForNewExercise) {
                        Label("Add Exercise", systemImage: "plus")
                    }
                }
            }
            .alert("Delete Exercise", isPresented: $showingExerciseDeleteConfirmation) {
                Button("Cancel", role: .cancel) { exerciseToDelete = nil }
                Button("Delete", role: .destructive) {
                    if let exercise = exerciseToDelete {
                        modelContext.delete(exercise)
                        do { try modelContext.save() } catch { }
                        exerciseToDelete = nil
                    }
                }
            } message: {
                Text("Are you sure you want to delete this exercise? This action cannot be undone.")
            }
            .sheet(isPresented: $isPresentingExerciseEditor) {
                NavigationStack {
                    ExerciseEditorView(mode: editorMode, exercise: editorMode == .edit ? selectedExercise : nil)
                }
            }
        }
    }

    private func promptForNewExercise() {
        selectedExercise = nil
        editorMode = .create
        isPresentingExerciseEditor = true
    }

    private var filteredExercises: [ExerciseDefinition] {
        exercises.filter { exercise in
            let matchesCategory: Bool
            if activeCategoryFilters.isEmpty {
                matchesCategory = true
            } else {
                let exerciseCategoryIDs = Set(exercise.categories.map { $0.id })
                matchesCategory = !exerciseCategoryIDs.isDisjoint(with: activeCategoryFilters)
            }

            let matchesMajor: Bool
            if let majorID = activeMajorGroupFilter {
                matchesMajor = exercise.majorContributions.contains { $0.majorGroup?.id == majorID }
            } else {
                matchesMajor = true
            }

            return matchesCategory && matchesMajor
        }
    }

    private var isFilterActive: Bool {
        !activeCategoryFilters.isEmpty || activeMajorGroupFilter != nil
    }

    private var filtersSection: some View {
        Section(header: Text("Filters").textCase(.uppercase).font(.subheadline).foregroundColor(.secondary)) {
            if !categoryTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categoryTags) { category in
                            let isSelected = activeCategoryFilters.contains(category.id)
                            Button {
                                toggleCategoryFilter(category)
                            } label: {
                                Text(category.name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.15))
                                    .foregroundColor(isSelected ? Color.accentColor : .primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .padding(.vertical, 4)
            }

            if !majorMuscleGroups.isEmpty {
                Menu {
                    Button("All Groups") { activeMajorGroupFilter = nil }
                    ForEach(majorMuscleGroups) { group in
                        Button(action: { activeMajorGroupFilter = group.id }) {
                            if activeMajorGroupFilter == group.id {
                                Label(group.name, systemImage: "checkmark")
                            } else {
                                Text(group.name)
                            }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "line.3.horizontal.decrease")
                        Text(activeMajorGroupName)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            if isFilterActive {
                Button("Clear Filters", role: .cancel, action: clearFilters)
                    .font(.footnote)
            }
        }
    }

    private var activeMajorGroupName: String {
        guard let majorID = activeMajorGroupFilter, let group = majorMuscleGroups.first(where: { $0.id == majorID }) else {
            return "All Muscle Groups"
        }
        return group.name
    }

    private func toggleCategoryFilter(_ category: WorkoutCategoryTag) {
        if activeCategoryFilters.contains(category.id) {
            activeCategoryFilters.remove(category.id)
        } else {
            activeCategoryFilters.insert(category.id)
        }
    }

    private func clearFilters() {
        activeCategoryFilters.removeAll()
        activeMajorGroupFilter = nil
    }

    private func deleteExercise(offsets: IndexSet) {
        withAnimation {
            let currentFiltered = filteredExercises
            for index in offsets {
                guard index < currentFiltered.count else { continue }
                modelContext.delete(currentFiltered[index])
            }
        }
    }
}

// MARK: - Enhanced UI Components

struct FeatureRowView: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let color: Color
    let destination: AnyView
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.1))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: systemImage)
                        .foregroundColor(color)
                        .font(.system(size: 16, weight: .medium))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(.vertical, 4)
        }
    }
}

struct ExerciseRowView: View {
    let exercise: ExerciseDefinition
    
    private var workoutCount: Int {
        exercise.workoutRecords.count
    }
    
    private var lastWorkoutDate: Date? {
        exercise.workoutRecords.max(by: { $0.date < $1.date })?.date
    }

    private var primaryContribution: (name: String, percent: Int)? {
        guard let topContribution = exercise.majorContributions.max(by: { $0.share < $1.share }),
              let groupName = topContribution.majorGroup?.name
        else { return nil }
        return (groupName, topContribution.share)
    }

    private var categoryNames: [String] {
        exercise.categories
            .sorted(by: { $0.name < $1.name })
            .map { $0.name }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Exercise Icon
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "dumbbell.fill")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 16, weight: .medium))
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(exercise.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                HStack(spacing: 12) {
                    if workoutCount > 0 {
                        Label("\(workoutCount) workout\(workoutCount == 1 ? "" : "s")", systemImage: "clock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        if let lastDate = lastWorkoutDate {
                            Label("Last: \(lastDate, format: .dateTime.day().month())", systemImage: "calendar")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("No workouts yet")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }

                if let primary = primaryContribution {
                    HStack(spacing: 6) {
                        Image(systemName: "target")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.accentColor)
                        Text("Primary: \(primary.name) \(primary.percent)%")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }

                if !categoryNames.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(categoryNames.prefix(3), id: \.self) { name in
                            Text(name)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.accentColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            
            Spacer()
            
            if workoutCount > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }
        }
        .padding(.vertical, 2)
    }
}

struct WorkoutRowView: View {
    let workout: WorkoutRecord
    
    var body: some View {
        HStack(spacing: 12) {
            // Date indicator
            VStack(spacing: 2) {
                Text("\(Calendar.current.component(.day, from: workout.date))")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.accentColor)
                
                Text(workout.date.formatted(.dateTime.month(.abbreviated)))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }
            .frame(width: 36)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor.opacity(0.1))
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.date.formatted(.dateTime.weekday(.wide).day().month().year()))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "repeat")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text("\(workout.setEntries.count) sets")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text("\(workout.totalVolume, specifier: "%.0f") vol")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("Best 1RM")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                Text("\(workout.bestOneRepMaxInSession, specifier: "%.1f")")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }
}

struct ExerciseDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    var exercise: ExerciseDefinition
    @State private var showingAddWorkoutSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var workoutToDelete: WorkoutRecord? = nil
    @State private var isEditingExercise = false
    @State private var showingExerciseDeleteConfirmation = false
    @State private var showingExerciseInfo = false
    
    // Computed properties for best performance metrics
    private var bestOneRepMaxData: (value: Double, date: Date)? {
        guard !exercise.workoutRecords.isEmpty else { return nil }
        
        var bestOneRM: Double = 0
        var bestDate: Date = Date()
        var foundValidOneRM = false
        
        for workout in exercise.workoutRecords {
            for setEntry in workout.setEntries {
                // Only consider sets with weight for 1RM calculation
                if setEntry.weight != nil && setEntry.calculatedOneRepMax > bestOneRM {
                    bestOneRM = setEntry.calculatedOneRepMax
                    bestDate = workout.date
                    foundValidOneRM = true
                }
            }
        }
        
        return foundValidOneRM ? (value: bestOneRM, date: bestDate) : nil
    }
    
    private var bestVolumeWorkout: (volume: Double, date: Date)? {
        guard !exercise.workoutRecords.isEmpty else { return nil }
        
        let workoutWithMaxVolume = exercise.workoutRecords.max { $0.totalVolume < $1.totalVolume }
        if let workout = workoutWithMaxVolume {
            return (volume: workout.totalVolume, date: workout.date)
        }
        return nil
    }

    private var categoryNames: [String] {
        exercise.categories
            .sorted(by: { $0.name < $1.name })
            .map { $0.name }
    }

    private var majorContributionSlices: [ContributionSlice] {
        exercise.majorContributions
            .filter { $0.share > 0 }
            .sorted(by: { $0.share > $1.share })
            .compactMap { contribution in
                guard let name = contribution.majorGroup?.name else { return nil }
                return ContributionSlice(name: name, percentage: Double(contribution.share) / 100.0)
            }
    }

    private struct SpecificGroupBreakdown: Identifiable {
        let id = UUID()
        let groupName: String
        let groupShare: Int
        let slices: [ContributionSlice]
    }

    private var specificGroupBreakdowns: [SpecificGroupBreakdown] {
        let grouped = Dictionary(grouping: exercise.specificContributions.filter { $0.share > 0 }) { contribution -> UUID? in
            contribution.specificMuscle?.majorGroup?.id
        }

        return grouped.compactMap { key, contributions in
            guard
                let groupID = key,
                let groupShare = exercise.majorContributions.first(where: { $0.majorGroup?.id == groupID })?.share,
                groupShare > 0,
                let groupName = contributions.first?.specificMuscle?.majorGroup?.name
            else { return nil }

            let slices = contributions
                .compactMap { contribution -> ContributionSlice? in
                    guard let muscleName = contribution.specificMuscle?.name else { return nil }
                    return ContributionSlice(name: muscleName, percentage: Double(contribution.share) / 100.0)
                }
                .sorted(by: { $0.percentage > $1.percentage })

            return SpecificGroupBreakdown(groupName: groupName, groupShare: groupShare, slices: slices)
        }
        .sorted(by: { $0.groupShare > $1.groupShare })
    }

    private var hasContributionData: Bool {
        !categoryNames.isEmpty || !majorContributionSlices.isEmpty || !specificGroupBreakdowns.isEmpty
    }

    private var validationMessages: [String] {
        exercise.validatePercentages()
    }

    var body: some View {
        ZStack {
            List {
                Section(header: HStack {
                    Image(systemName: "trophy.fill").foregroundColor(.orange)
                    Text("Personal Records")
                    Spacer()
                }) {
                    PRSummaryCard(bestOneRepMaxData: bestOneRepMaxData, bestVolumeWorkout: bestVolumeWorkout)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                Section(header: Text("Workout History")) {
                    if exercise.workoutRecords.isEmpty {
                        Text("No workouts yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(exercise.workoutRecords.sorted(by: { $0.date > $1.date })) { workout in
                            NavigationLink {
                                WorkoutSessionDetailView(workoutRecord: workout)
                            } label: {
                                WorkoutRowView(workout: workout)
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    workoutToDelete = workout
                                    showingDeleteConfirmation = true
                                } label: {
                                    Label("Delete Workout", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    workoutToDelete = workout
                                    showingDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
        .safeAreaInset(edge: .bottom) {
            Button(action: { showingAddWorkoutSheet = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Add Workout")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.accentColor)
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
                )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .alert("Delete Workout", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { workoutToDelete = nil }
            Button("Delete", role: .destructive) {
                if let workout = workoutToDelete {
                    deleteWorkout(workout)
                    workoutToDelete = nil
                }
            }
        } message: {
            Text("Are you sure you want to delete this workout? This action cannot be undone.")
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button("Details") { showingExerciseInfo = true }
                Button("Edit") { isEditingExercise = true }
                Button(role: .destructive) {
                    showingExerciseDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .sheet(isPresented: $showingAddWorkoutSheet) {
            NavigationStack {
                WorkoutInputView(exerciseDefinition: exercise)
            }
        }
        .sheet(isPresented: $isEditingExercise) {
            NavigationStack {
                ExerciseEditorView(mode: .edit, exercise: exercise)
            }
        }
        .sheet(isPresented: $showingExerciseInfo) {
            NavigationStack {
                ExerciseInfoView(exercise: exercise)
            }
        }
        .alert("Delete Exercise", isPresented: $showingExerciseDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                modelContext.delete(exercise)
                do { try modelContext.save() } catch { }
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this exercise? This action cannot be undone.")
        }
    }

    private var contributionSummary: some View {
        Group {
            if hasContributionData {
                VStack(alignment: .leading, spacing: 16) {
                    if !categoryNames.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(categoryNames, id: \.self) { name in
                                    Text(name)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color.accentColor.opacity(0.15))
                                        .foregroundColor(.accentColor)
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }

                    if !majorContributionSlices.isEmpty {
                        ContributionBreakdownView(title: "Major Muscle Groups", slices: majorContributionSlices)
                            .padding(.horizontal, 16)
                    }

                    ForEach(specificGroupBreakdowns) { breakdown in
                        ContributionBreakdownView(
                            title: "\(breakdown.groupName) \(breakdown.groupShare)%",
                            slices: breakdown.slices
                        )
                        .padding(.horizontal, 16)
                    }
                    if !validationMessages.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(validationMessages, id: \.self) { message in
                                Label(message, systemImage: "exclamationmark.triangle.fill")
                                    .font(.footnote)
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    Divider()
                        .padding(.horizontal, 16)
                }
                .padding(.vertical, 12)
            }
        }
    }
    
    private func deleteWorkout(_ workout: WorkoutRecord) {
        // Remove the workout from the exercise's workoutRecords array
        if let index = exercise.workoutRecords.firstIndex(where: { $0.id == workout.id }) {
            exercise.workoutRecords.remove(at: index)
        }
        
        // Delete the workout from the model context
        modelContext.delete(workout)
        
        // Try to save the context explicitly to ensure changes are persisted immediately
        do {
            try modelContext.save()
        } catch {
            print("Error deleting workout: \(error)")
        }
    }
}

// MARK: - Detail Helpers

private struct PRSummaryCard: View {
    let bestOneRepMaxData: (value: Double, date: Date)?
    let bestVolumeWorkout: (volume: Double, date: Date)?

    var body: some View {
        VStack(spacing: 16) {
            // Card content only; title is provided by the Section header.
            Spacer().frame(height: 8)

            HStack(spacing: 0) {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 44, height: 44)
                        Image(systemName: "scalemass.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 18, weight: .medium))
                    }
                    Text("Best 1RM")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    if let best = bestOneRepMaxData {
                        Text("\(best.value, specifier: "%.1f")")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                        Text("\(best.date, format: .dateTime.day().month())")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    } else {
                        Text("N/A")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 1, height: 60)

                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.1))
                            .frame(width: 44, height: 44)
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 18, weight: .medium))
                    }
                    Text("Best Volume")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    if let vol = bestVolumeWorkout {
                        Text("\(vol.volume, specifier: "%.1f")")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                        Text("\(vol.date, format: .dateTime.day().month())")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    } else {
                        Text("N/A")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            ExerciseDefinition.self,
            WorkoutRecord.self,
            SetEntry.self
        ], inMemory: true)
}
