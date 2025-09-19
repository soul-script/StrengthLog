import SwiftUI
import SwiftData

struct ReferenceDataManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutCategoryTag.name) private var categories: [WorkoutCategoryTag]
    @Query(sort: \MajorMuscleGroup.name) private var majorGroups: [MajorMuscleGroup]
    @Query(sort: \SpecificMuscle.name) private var specificMuscles: [SpecificMuscle]

    @State private var showingCategoryForm = false
    @State private var categoryName = ""
    @State private var editingCategory: WorkoutCategoryTag?

    @State private var showingMajorGroupForm = false
    @State private var majorGroupName = ""
    @State private var majorGroupInfo = ""
    @State private var editingMajorGroup: MajorMuscleGroup?

    @State private var showingSpecificForm = false
    @State private var specificMuscleName = ""
    @State private var selectedMajorGroupID: UUID?
    @State private var editingSpecificMuscle: SpecificMuscle?

    @State private var errorMessage: String?

    var body: some View {
        List {
            categorySection
            majorGroupSection
            specificMuscleSection
        }
        .navigationTitle("Reference Data")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            if let message = errorMessage {
                Text(message)
            }
        }
        .sheet(isPresented: $showingCategoryForm, onDismiss: resetCategoryForm) {
            NavigationStack { categoryForm }
        }
        .sheet(isPresented: $showingMajorGroupForm, onDismiss: resetMajorGroupForm) {
            NavigationStack { majorGroupForm }
        }
        .sheet(isPresented: $showingSpecificForm, onDismiss: resetSpecificForm) {
            NavigationStack { specificMuscleForm }
        }
    }

    private var categorySection: some View {
        Section(header: sectionHeader("Workout Categories", addAction: startNewCategory)) {
            if categories.isEmpty {
                Text("No categories yet. Tap + to add one.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            ForEach(categories) { category in
                Text(category.name)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("Edit") { beginEditing(category: category) }
                            .tint(.accentColor)
                        Button(role: .destructive) {
                            attemptDelete(category: category)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
    }

    private var majorGroupSection: some View {
        Section(header: sectionHeader("Major Muscle Groups", addAction: startNewMajorGroup)) {
            if majorGroups.isEmpty {
                Text("No major groups yet. Tap + to add one.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            ForEach(majorGroups) { group in
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.body)
                    if let info = group.info, !info.isEmpty {
                        Text(info)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button("Edit") { beginEditing(group: group) }
                        .tint(.accentColor)
                    Button(role: .destructive) {
                        attemptDelete(group: group)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }

    private var specificMuscleSection: some View {
        Section(header: sectionHeader("Specific Muscles", addAction: startNewSpecificMuscle)) {
            if specificMuscles.isEmpty {
                Text("No specific muscles yet. Tap + to add one.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            ForEach(specificMuscles) { muscle in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(muscle.name)
                        if let groupName = muscle.majorGroup?.name {
                            Text(groupName)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button("Edit") { beginEditing(muscle: muscle) }
                        .tint(.accentColor)
                    Button(role: .destructive) {
                        attemptDelete(muscle: muscle)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }

    private func sectionHeader(_ title: String, addAction: @escaping () -> Void) -> some View {
        HStack {
            Text(title.uppercased())
                .font(.footnote)
                .foregroundColor(.secondary)
            Spacer()
            Button(action: addAction) {
                Image(systemName: "plus.circle.fill")
            }
            .accessibilityLabel("Add \(title)")
        }
    }

    private func startNewCategory() {
        editingCategory = nil
        categoryName = ""
        showingCategoryForm = true
    }

    private func beginEditing(category: WorkoutCategoryTag) {
        editingCategory = category
        categoryName = category.name
        showingCategoryForm = true
    }

    private func resetCategoryForm() {
        editingCategory = nil
        categoryName = ""
    }

    private var categoryForm: some View {
        Form {
            Section("Category") {
                TextField("Name", text: $categoryName)
                    .textInputAutocapitalization(.words)
            }
        }
        .navigationTitle(editingCategory == nil ? "New Category" : "Edit Category")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { showingCategoryForm = false }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save", action: saveCategory)
                    .disabled(categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private func saveCategory() {
        let trimmed = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            if let category = editingCategory {
                category.name = trimmed
            } else {
                let tag = WorkoutCategoryTag(name: trimmed)
                modelContext.insert(tag)
            }
            try modelContext.save()
            showingCategoryForm = false
        } catch {
            errorMessage = "Unable to save category: \(error.localizedDescription)"
        }
    }

    private func startNewMajorGroup() {
        editingMajorGroup = nil
        majorGroupName = ""
        majorGroupInfo = ""
        showingMajorGroupForm = true
    }

    private func beginEditing(group: MajorMuscleGroup) {
        editingMajorGroup = group
        majorGroupName = group.name
        majorGroupInfo = group.info ?? ""
        showingMajorGroupForm = true
    }

    private func resetMajorGroupForm() {
        editingMajorGroup = nil
        majorGroupName = ""
        majorGroupInfo = ""
    }

    private var majorGroupForm: some View {
        Form {
            Section("Major Group") {
                TextField("Name", text: $majorGroupName)
                    .textInputAutocapitalization(.words)
                TextField("Details (optional)", text: $majorGroupInfo)
            }
        }
        .navigationTitle(editingMajorGroup == nil ? "New Major Group" : "Edit Major Group")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { showingMajorGroupForm = false }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save", action: saveMajorGroup)
                    .disabled(majorGroupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private func saveMajorGroup() {
        let trimmed = majorGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            if let group = editingMajorGroup {
                group.name = trimmed
                group.info = majorGroupInfo.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                let group = MajorMuscleGroup(name: trimmed, info: majorGroupInfo.trimmingCharacters(in: .whitespacesAndNewlines))
                modelContext.insert(group)
            }
            try modelContext.save()
            showingMajorGroupForm = false
        } catch {
            errorMessage = "Unable to save major group: \(error.localizedDescription)"
        }
    }

    private func startNewSpecificMuscle() {
        guard let firstGroup = majorGroups.first else {
            errorMessage = "Create a major muscle group before adding specific muscles."
            return
        }
        editingSpecificMuscle = nil
        specificMuscleName = ""
        selectedMajorGroupID = firstGroup.id
        showingSpecificForm = true
    }

    private func beginEditing(muscle: SpecificMuscle) {
        editingSpecificMuscle = muscle
        specificMuscleName = muscle.name
        selectedMajorGroupID = muscle.majorGroup?.id
        showingSpecificForm = true
    }

    private func resetSpecificForm() {
        editingSpecificMuscle = nil
        specificMuscleName = ""
        selectedMajorGroupID = nil
    }

    private var specificMuscleForm: some View {
        Form {
            Section("Specific Muscle") {
                TextField("Name", text: $specificMuscleName)
                    .textInputAutocapitalization(.words)

                Picker("Major Group", selection: Binding(get: {
                    selectedMajorGroupID ?? majorGroups.first?.id
                }, set: { selectedMajorGroupID = $0 })) {
                    ForEach(majorGroups) { group in
                        Text(group.name).tag(Optional(group.id))
                    }
                }
            }
        }
        .navigationTitle(editingSpecificMuscle == nil ? "New Specific Muscle" : "Edit Specific Muscle")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { showingSpecificForm = false }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save", action: saveSpecificMuscle)
                    .disabled(disableSpecificSave)
            }
        }
    }

    private var disableSpecificSave: Bool {
        specificMuscleName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedMajorGroupID == nil
    }

    private func saveSpecificMuscle() {
        let trimmed = specificMuscleName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let groupID = selectedMajorGroupID,
              let group = majorGroups.first(where: { $0.id == groupID }) else { return }

        do {
            if let muscle = editingSpecificMuscle {
                muscle.name = trimmed
                muscle.majorGroup = group
            } else {
                let muscle = SpecificMuscle(name: trimmed, majorGroup: group)
                modelContext.insert(muscle)
            }
            try modelContext.save()
            showingSpecificForm = false
        } catch {
            errorMessage = "Unable to save specific muscle: \(error.localizedDescription)"
        }
    }

    // MARK: - Guarded Deletes

    private func attemptDelete(category: WorkoutCategoryTag) {
        if !category.exercises.isEmpty {
            let count = category.exercises.count
            errorMessage = "Cannot delete category ‘\(category.name)’ because it’s used by \(count) exercise\(count == 1 ? "" : "s")."
            return
        }
        do {
            modelContext.delete(category)
            try modelContext.save()
        } catch {
            errorMessage = "Failed to delete category: \(error.localizedDescription)"
        }
    }

    private func attemptDelete(group: MajorMuscleGroup) {
        // Block if used by any exercise major contribution or any specific contribution via its specific muscles.
        let groupName = group.name
        let usedInMajors = exists(ExerciseMajorContribution.self, matching: #Predicate { $0.majorGroup?.name == groupName })
        let usedInSpecifics = exists(ExerciseSpecificContribution.self, matching: #Predicate { $0.specificMuscle?.majorGroup?.name == groupName })

        if usedInMajors || usedInSpecifics {
            errorMessage = "Cannot delete major group ‘\(group.name)’ because it’s referenced by existing exercises. Remove those references first."
            return
        }

        do {
            // This will also cascade delete any unused specific muscles under the group per model relationship.
            modelContext.delete(group)
            try modelContext.save()
        } catch {
            errorMessage = "Failed to delete major group: \(error.localizedDescription)"
        }
    }

    private func attemptDelete(muscle: SpecificMuscle) {
        let muscleName = muscle.name
        let used = exists(ExerciseSpecificContribution.self, matching: #Predicate { $0.specificMuscle?.name == muscleName })
        if used {
            errorMessage = "Cannot delete specific muscle ‘\(muscle.name)’ because it’s referenced by existing exercises."
            return
        }
        do {
            modelContext.delete(muscle)
            try modelContext.save()
        } catch {
            errorMessage = "Failed to delete specific muscle: \(error.localizedDescription)"
        }
    }

    private func exists<T: PersistentModel>(_ type: T.Type, matching predicate: Predicate<T>) -> Bool {
        var descriptor = FetchDescriptor<T>(predicate: predicate)
        descriptor.fetchLimit = 1
        do {
            let results = try modelContext.fetch(descriptor)
            return !results.isEmpty
        } catch {
            // If fetch fails, be safe and assume existence to prevent unsafe deletes.
            return true
        }
    }
}

#Preview {
    NavigationStack {
        ReferenceDataManagerView()
            .modelContainer(for: [
                WorkoutCategoryTag.self,
                MajorMuscleGroup.self,
                SpecificMuscle.self
            ], inMemory: true)
    }
}
