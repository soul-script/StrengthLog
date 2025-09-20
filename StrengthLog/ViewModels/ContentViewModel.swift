import Foundation
import SwiftUI
import OSLog

@MainActor
final class ContentViewModel: ObservableObject {
    @Published private(set) var filteredExercises: [ExerciseDefinition] = []
    @Published var activeCategoryFilters: Set<UUID> = []
    @Published var activeMajorGroupFilter: UUID?
    @Published var exerciseToDelete: ExerciseDefinition?
    @Published var showingDeleteConfirmation = false
    @Published var isPresentingEditor = false
    @Published var editorMode: ExerciseEditorView.Mode = .create
    @Published var selectedExercise: ExerciseDefinition?

    private var exerciseRepository: ExerciseRepository?
    private var allExercises: [ExerciseDefinition] = []
    private let logger = Logger(subsystem: "com.adityamishra.StrengthLog", category: "ContentViewModel")

    var isFilterActive: Bool {
        !activeCategoryFilters.isEmpty || activeMajorGroupFilter != nil
    }

    func configureIfNeeded(repository: ExerciseRepository) {
        guard exerciseRepository == nil else { return }
        exerciseRepository = repository
    }

    func updateData(exercises: [ExerciseDefinition]) {
        allExercises = exercises
        applyFilters()
    }

    func toggleCategoryFilter(_ category: WorkoutCategoryTag) {
        if activeCategoryFilters.contains(category.id) {
            activeCategoryFilters.remove(category.id)
        } else {
            activeCategoryFilters.insert(category.id)
        }
        applyFilters()
    }

    func setMajorGroupFilter(_ group: MajorMuscleGroup?) {
        activeMajorGroupFilter = group?.id
        applyFilters()
    }

    func validateMajorGroupFilter(availableGroups: [MajorMuscleGroup]) {
        guard let activeID = activeMajorGroupFilter else { return }
        let isStillAvailable = availableGroups.contains { $0.id == activeID }
        if !isStillAvailable {
            activeMajorGroupFilter = nil
            applyFilters()
        }
    }

    func clearFilters() {
        activeCategoryFilters.removeAll()
        activeMajorGroupFilter = nil
        applyFilters()
    }

    func promptForNewExercise() {
        selectedExercise = nil
        editorMode = .create
        isPresentingEditor = true
    }

    func requestDelete(_ exercise: ExerciseDefinition) {
        exerciseToDelete = exercise
        showingDeleteConfirmation = true
    }

    func confirmDelete() {
        guard let repository = exerciseRepository, let exercise = exerciseToDelete else { return }
        do {
            try repository.delete(exercise)
            allExercises.removeAll { $0.id == exercise.id }
            applyFilters()
        } catch {
            logger.error("Failed to delete exercise: \(String(describing: error))")
        }
        exerciseToDelete = nil
        showingDeleteConfirmation = false
    }

    func cancelDelete() {
        exerciseToDelete = nil
        showingDeleteConfirmation = false
    }

    func deleteExercises(at offsets: IndexSet) {
        let targets = offsets.compactMap { index in
            filteredExercises.indices.contains(index) ? filteredExercises[index] : nil
        }
        delete(exercises: targets)
    }

    func delete(exercises: [ExerciseDefinition]) {
        guard let repository = exerciseRepository, !exercises.isEmpty else { return }
        for exercise in exercises {
            do {
                try repository.delete(exercise)
                allExercises.removeAll { $0.id == exercise.id }
            } catch {
                logger.error("Failed to delete exercise during bulk operation: \(String(describing: error))")
            }
        }
        applyFilters()
    }

    private func applyFilters() {
        filteredExercises = allExercises.filter { exercise in
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
}
