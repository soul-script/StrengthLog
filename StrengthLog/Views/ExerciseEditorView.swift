import SwiftUI
import SwiftData

struct ExerciseEditorView: View {
    enum Mode {
        case create
        case edit

        var title: String {
            switch self {
            case .create:
                return "New Exercise"
            case .edit:
                return "Edit Exercise"
            }
        }

        var actionTitle: String {
            switch self {
            case .create:
                return "Create"
            case .edit:
                return "Save"
            }
        }
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \WorkoutCategoryTag.name) private var categoryTags: [WorkoutCategoryTag]
    @Query(sort: \MajorMuscleGroup.name) private var majorGroups: [MajorMuscleGroup]
    @Query(sort: \SpecificMuscle.name) private var specificMuscles: [SpecificMuscle]

    @StateObject private var viewModel: ExerciseEditorViewModel

    private let mode: Mode
    private weak var exercise: ExerciseDefinition?

    init(mode: Mode, exercise: ExerciseDefinition? = nil) {
        self.mode = mode
        self.exercise = exercise
        _viewModel = StateObject(wrappedValue: ExerciseEditorViewModel(mode: mode, exercise: exercise))
    }

    var body: some View {
        Form {
            detailsSection
            categoriesSection
            majorGroupsSection
            validationSection
        }
        .navigationTitle(mode.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel", role: .cancel) { dismiss() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(mode.actionTitle, action: persistChanges)
                    .disabled(!viewModel.canPersist)
            }
        }
        .onAppear(perform: configureReferences)
        .onChange(of: categoryTags.map(\.id)) { _ in configureReferences() }
        .onChange(of: majorGroups.map(\.id)) { _ in configureReferences() }
        .onChange(of: specificMuscles.map(\.id)) { _ in configureReferences() }
        .alert("Validation", isPresented: $viewModel.showingBlockingError, actions: {
            Button("OK", role: .cancel) { viewModel.showingBlockingError = false }
        }, message: {
            Text(viewModel.blockingErrorMessage)
        })
    }

    private func configureReferences() {
        viewModel.configureIfNeeded(
            categories: categoryTags,
            majorGroups: majorGroups,
            specificMuscles: specificMuscles
        )
    }

    private var detailsSection: some View {
        Section(header: label("Exercise Details", systemImage: "info.circle")) {
            TextField("Exercise name", text: $viewModel.name)
                .textInputAutocapitalization(.words)
                .onChange(of: viewModel.name) { _ in viewModel.validate() }

            if let template = ExerciseTemplateProvider.template(for: viewModel.name) {
                Button {
                    viewModel.apply(template: template)
                } label: {
                    HStack {
                        Image(systemName: "wand.and.stars")
                        Text("Suggest from template")
                        Spacer()
                        Text(template.canonicalName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private var categoriesSection: some View {
        Section(header: label("Workout Categories", systemImage: "tag")) {
            if viewModel.categories.isEmpty {
                HStack {
                    ProgressView()
                    Text("Loading categories…")
                        .foregroundColor(.secondary)
                }
            } else {
                CategoryChipsView(
                    categories: viewModel.categories,
                    selection: $viewModel.selectedCategoryIDs
                )
            }
        }
    }

    private var majorGroupsSection: some View {
        Section(header: label("Muscle Contributions", systemImage: "figure.flexibility")) {
            ForEach(viewModel.majorGroups, id: \.id) { group in
                MajorGroupEditorRow(
                    group: group,
                    isActive: viewModel.isGroupActive(group),
                    majorShareBinding: viewModel.bindingForMajorSharePercent(group),
                    onToggle: { isOn in viewModel.toggleMajorGroup(group, isActive: isOn) },
                    specificMuscles: viewModel.specificMuscles(for: group),
                    specificBindings: viewModel.specificBindings(for: group),
                    normalizedSpecificAction: { viewModel.evenSpecificDistribution(for: group) }
                )
            }

            if !viewModel.majorShares.isEmpty {
                Button("Normalize totals") {
                    viewModel.normalizeMajorShares()
                }
            }
        }
    }

    private var validationSection: some View {
        Section(header: label("Summary", systemImage: "checkmark.seal")) {
            if !viewModel.majorShares.isEmpty {
                HStack {
                    Text("Major Total")
                    Spacer()
                    Text(viewModel.formattedMajorTotal)
                        .foregroundColor(viewModel.majorTotalWithinTolerance ? .green : .orange)
                }
            }

            if viewModel.hasSpecificBreakdown {
                HStack {
                    Text("Specific Total")
                    Spacer()
                    Text(viewModel.formattedSpecificTotal)
                        .foregroundColor(viewModel.specificTotalWithinTolerance ? .green : .orange)
                }
            }

            ForEach(viewModel.validationMessages, id: \.self) { message in
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.footnote)
            }
        }
    }

    private func persistChanges() {
        viewModel.validate()
        guard viewModel.canPersist else { return }

        do {
            let targetExercise: ExerciseDefinition
            if let existing = exercise, mode == .edit {
                targetExercise = existing
                targetExercise.name = viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                targetExercise = ExerciseDefinition(name: viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines))
                modelContext.insert(targetExercise)
            }

            updateCategories(for: targetExercise)
            updateMajorContributions(for: targetExercise)
            updateSpecificContributions(for: targetExercise)

            try modelContext.save()
            dismiss()
        } catch {
            viewModel.present(error: error)
        }
    }

    private func updateCategories(for exercise: ExerciseDefinition) {
        let categoryLookup = Dictionary(uniqueKeysWithValues: categoryTags.map { ($0.id, $0) })
        let selected = viewModel.selectedCategoryIDs.compactMap { categoryLookup[$0] }
        exercise.categories.removeAll()
        exercise.categories.append(contentsOf: selected)
    }

    private func updateMajorContributions(for exercise: ExerciseDefinition) {
        for contribution in exercise.majorContributions {
            modelContext.delete(contribution)
        }
        exercise.majorContributions.removeAll()

        for (groupID, share) in viewModel.majorShares {
            guard share > 0, let group = majorGroups.first(where: { $0.id == groupID }) else { continue }
            let contribution = ExerciseMajorContribution(exercise: exercise, majorGroup: group, share: share)
            modelContext.insert(contribution)
        }
    }

    private func updateSpecificContributions(for exercise: ExerciseDefinition) {
        for contribution in exercise.specificContributions {
            modelContext.delete(contribution)
        }
        exercise.specificContributions.removeAll()

        for (groupID, _) in viewModel.specificRatios {
            guard let groupShare = viewModel.majorShares[groupID], groupShare > 0 else { continue }
            let specificLookup = viewModel.specificMusclesByGroup[groupID] ?? []
            let muscleDictionary = Dictionary(uniqueKeysWithValues: specificLookup.map { ($0.id, $0) })
            let absoluteShares = viewModel.absoluteSpecificShares(for: groupID)

            for (muscleID, share) in absoluteShares {
                guard share > 0, let muscle = muscleDictionary[muscleID] else { continue }
                let contribution = ExerciseSpecificContribution(exercise: exercise, specificMuscle: muscle, share: share)
                modelContext.insert(contribution)
            }
        }
    }

    private func label(_ text: String, systemImage: String) -> some View {
        HStack {
            Image(systemName: systemImage)
            Text(text)
        }
        .textCase(.uppercase)
        .font(.footnote)
        .foregroundColor(.secondary)
    }
}

// MARK: - View Model

final class ExerciseEditorViewModel: ObservableObject {
    @Published var name: String
    @Published var selectedCategoryIDs: Set<UUID> = []
    @Published var majorShares: [UUID: Int] = [:]
    @Published var specificRatios: [UUID: [UUID: Double]] = [:]
    @Published var categories: [WorkoutCategoryTag] = []
    @Published var majorGroups: [MajorMuscleGroup] = []
    @Published var specificMusclesByGroup: [UUID: [SpecificMuscle]] = [:]
    @Published var validationMessages: [String] = []
    @Published var showingBlockingError = false
    @Published var blockingErrorMessage: String = ""

    private let mode: ExerciseEditorView.Mode
    private weak var exercise: ExerciseDefinition?
    private var isConfigured = false

    init(mode: ExerciseEditorView.Mode, exercise: ExerciseDefinition?) {
        self.mode = mode
        self.exercise = exercise
        self.name = exercise?.name ?? ""
    }

    var formattedMajorTotal: String {
        "\(totalMajorShare)%"
    }

    var formattedSpecificTotal: String {
        "\(totalSpecificShare)%"
    }

    var majorTotalWithinTolerance: Bool {
        totalMajorShare == 100
    }

    var specificTotalWithinTolerance: Bool {
        guard hasSpecificBreakdown else { return true }
        return totalSpecificShare == 100
    }

    var hasSpecificBreakdown: Bool {
        // Only consider specifics when majors are present; otherwise specifics are ignored.
        guard !majorShares.isEmpty else { return false }
        return majorShares.keys.contains { !(specificRatios[$0] ?? [:]).isEmpty }
    }

    var canPersist: Bool {
        // Allow saving without muscle contributions; only block on hard validation errors.
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && validationMessages.isEmpty
    }

    var totalMajorShare: Int {
        majorShares.values.reduce(0, +)
    }

    var totalSpecificShare: Int {
        majorShares.keys.reduce(0) { total, groupID in
            total + absoluteSpecificShares(for: groupID).values.reduce(0, +)
        }
    }

    func configureIfNeeded(categories: [WorkoutCategoryTag], majorGroups: [MajorMuscleGroup], specificMuscles: [SpecificMuscle]) {
        self.categories = categories
        self.majorGroups = majorGroups
        self.specificMusclesByGroup = specificMuscles.reduce(into: [UUID: [SpecificMuscle]]()) { storage, muscle in
            guard let groupID = muscle.majorGroup?.id else { return }
            storage[groupID, default: []].append(muscle)
        }

        guard !isConfigured else {
            pruneSelections()
            return
        }

        if let exercise {
            selectedCategoryIDs = Set(exercise.categories.map { $0.id })
            majorShares = Dictionary(uniqueKeysWithValues: exercise.majorContributions.compactMap { contribution in
                guard let groupID = contribution.majorGroup?.id else { return nil }
                return (groupID, contribution.share)
            })
            let specificByGroup = exercise.specificContributions.reduce(into: [UUID: [ExerciseSpecificContribution]]()) { storage, contribution in
                guard contribution.share > 0, let groupID = contribution.specificMuscle?.majorGroup?.id else { return }
                storage[groupID, default: []].append(contribution)
            }
            specificRatios = majorShares.reduce(into: [:]) { storage, entry in
                let groupID = entry.key
                guard entry.value > 0, let contributions = specificByGroup[groupID] else { return }
                let ratios = contributions.reduce(into: [UUID: Double]()) { ratiosStorage, specificContribution in
                    guard let muscle = specificContribution.specificMuscle else { return }
                    let ratio = Double(specificContribution.share) / Double(entry.value)
                    ratiosStorage[muscle.id] = max(0, ratio)
                }
                storage[groupID] = normalizeRatios(ratios)
            }
        } else {
            name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        for (groupID, _) in majorShares where specificRatios[groupID] == nil {
            if let muscles = specificMusclesByGroup[groupID], !muscles.isEmpty {
                specificRatios[groupID] = evenRatios(for: muscles)
            }
        }

        isConfigured = true
        pruneSelections()
        validate()
    }

    func validate() {
        var messages: [String] = []

        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            messages.append("Exercise name is required.")
        }

        let majorTotal = totalMajorShare
        // Major muscle contributions are optional; only validate when provided.
        if !majorShares.isEmpty && majorTotal != 100 {
            messages.append("Major muscle shares must total 100%. Currently \(majorTotal)%.")
        }

        if hasSpecificBreakdown {
            let specificTotal = totalSpecificShare
            if specificTotal != 100 {
                messages.append("Specific muscle shares must total 100%. Currently \(specificTotal)%.")
            }

            for (groupID, share) in majorShares where share > 0 {
                let groupSpecificTotal = absoluteSpecificShares(for: groupID).values.reduce(0, +)
                if groupSpecificTotal != share, let groupName = majorGroups.first(where: { $0.id == groupID })?.name {
                    messages.append("Specific muscle shares for \(groupName) must total \(share)% of the exercise.")
                }
            }
        }

        validationMessages = messages
    }

    func isGroupActive(_ group: MajorMuscleGroup) -> Bool {
        majorShares[group.id] != nil
    }

    func toggleMajorGroup(_ group: MajorMuscleGroup, isActive: Bool) {
        if isActive {
            let remaining = max(0, 100 - totalMajorShare)
            let defaultShare = remaining > 0 ? remaining : 1
            majorShares[group.id] = max(1, defaultShare)
            if let muscles = specificMusclesByGroup[group.id], !muscles.isEmpty {
                specificRatios[group.id] = evenRatios(for: muscles)
            }
        } else {
            majorShares.removeValue(forKey: group.id)
            specificRatios[group.id] = nil
        }
        validate()
    }

    func bindingForMajorSharePercent(_ group: MajorMuscleGroup) -> Binding<Double> {
        Binding<Double>(
            get: {
                Double(self.majorShares[group.id] ?? 0)
            },
            set: { newValue in
                let clamped = max(0, min(100, newValue.rounded()))
                let newShare = Int(clamped)
                if newShare > 0 {
                    self.majorShares[group.id] = newShare
                } else {
                    self.majorShares.removeValue(forKey: group.id)
                    self.specificRatios[group.id] = nil
                }
                self.validate()
            }
        )
    }

    func specificMuscles(for group: MajorMuscleGroup) -> [SpecificMuscle] {
        specificMusclesByGroup[group.id]?.sorted(by: { $0.name < $1.name }) ?? []
    }

    func specificBindings(for group: MajorMuscleGroup) -> [SpecificMuscleBinding] {
        guard let muscles = specificMusclesByGroup[group.id] else { return [] }
        var ratios = specificRatios[group.id] ?? [:]
        if ratios.isEmpty {
            ratios = evenRatios(for: muscles)
            specificRatios[group.id] = ratios
        }
        return muscles.map { muscle in
            SpecificMuscleBinding(
                muscle: muscle,
                binding: Binding<Double>(
                    get: { (ratios[muscle.id] ?? 0) * 100 },
                    set: { newValue in
                        self.setSpecificRatio(newValue / 100, for: muscle, in: group)
                        self.validate()
                    }
                ),
                absoluteShare: absoluteShare(for: muscle, in: group)
            )
        }
    }

    func evenSpecificDistribution(for group: MajorMuscleGroup) {
        guard let muscles = specificMusclesByGroup[group.id], !muscles.isEmpty else { return }
        specificRatios[group.id] = evenRatios(for: muscles)
        validate()
    }

    func normalizeMajorShares() {
        let total = totalMajorShare
        guard total > 0 else { return }
        if total == 100 { return }

        var scaled = majorShares.mapValues { share in
            Int(round(Double(share) * 100.0 / Double(total)))
        }

        var remainder = 100 - scaled.values.reduce(0, +)
        if remainder != 0 {
            let orderedKeys = scaled.keys.sorted { lhs, rhs in
                let leftValue = scaled[lhs] ?? 0
                let rightValue = scaled[rhs] ?? 0
                return remainder > 0 ? leftValue < rightValue : leftValue > rightValue
            }
            var index = 0
            let count = orderedKeys.count
            while remainder != 0 && count > 0 {
                let key = orderedKeys[index % count]
                var value = scaled[key] ?? 0
                if remainder > 0 {
                    value += 1
                    remainder -= 1
                } else {
                    if value == 0 {
                        index += 1
                        continue
                    }
                    value -= 1
                    remainder += 1
                }
                scaled[key] = value
                index += 1
            }
        }

        majorShares = scaled.filter { $0.value > 0 }
        validate()
    }

    func apply(template: ExerciseTemplate) {
        let groupLookup = Dictionary(uniqueKeysWithValues: majorGroups.map { ($0.name.lowercased(), $0) })
        let muscleLookup = specificMusclesByGroup.reduce(into: [String: SpecificMuscle]()) { storage, entry in
            entry.value.forEach { storage[$0.name.lowercased()] = $0 }
        }
        let categoryLookup = Dictionary(uniqueKeysWithValues: categories.map { ($0.name.lowercased(), $0.id) })

        majorShares.removeAll()
        specificRatios.removeAll()

        for share in template.majorShares {
            guard let group = groupLookup[share.name.lowercased()] else { continue }
            majorShares[group.id] = share.share
        }

        for share in template.specificShares {
            guard
                let muscle = muscleLookup[share.name.lowercased()],
                let groupID = muscle.majorGroup?.id,
                let groupShare = majorShares[groupID],
                groupShare > 0
            else { continue }
            let ratio = Double(share.share) / Double(groupShare)
            if var groupRatios = specificRatios[groupID] {
                groupRatios[muscle.id] = ratio
                specificRatios[groupID] = normalizeRatios(groupRatios)
            } else {
                specificRatios[groupID] = normalizeRatios([muscle.id: ratio])
            }
        }

        let categoryIDs = template.categories.compactMap { categoryLookup[$0.lowercased()] }
        if !categoryIDs.isEmpty {
            selectedCategoryIDs = Set(categoryIDs)
        }

        if mode == .create && name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            name = template.canonicalName
        }

        validate()
    }

    func present(error: Error) {
        blockingErrorMessage = error.localizedDescription
        showingBlockingError = true
    }

    private func pruneSelections() {
        let categoryIDs = Set(categories.map { $0.id })
        selectedCategoryIDs = selectedCategoryIDs.filter { categoryIDs.contains($0) }
        majorShares = majorShares.filter { key, _ in majorGroups.contains(where: { $0.id == key }) }
        specificRatios = specificRatios.filter { key, _ in majorShares[key] != nil }
    }

    private func setSpecificRatio(_ ratio: Double, for muscle: SpecificMuscle, in group: MajorMuscleGroup) {
        guard ratio >= 0 else { return }
        var ratios = specificRatios[group.id] ?? [:]
        ratios[muscle.id] = max(0, min(1, ratio))
        var normalized = normalizeRatios(ratios)
        let total = normalized.values.reduce(0, +)
        if total == 0, let muscles = specificMusclesByGroup[group.id], !muscles.isEmpty {
            normalized = evenRatios(for: muscles)
        }
        specificRatios[group.id] = normalized
    }

    private func absoluteShare(for muscle: SpecificMuscle, in group: MajorMuscleGroup) -> Int {
        absoluteSpecificShares(for: group.id)[muscle.id] ?? 0
    }

    private func evenRatios(for muscles: [SpecificMuscle]) -> [UUID: Double] {
        guard !muscles.isEmpty else { return [:] }
        let share = 1.0 / Double(muscles.count)
        return muscles.reduce(into: [UUID: Double]()) { storage, muscle in
            storage[muscle.id] = share
        }
    }

    private func normalizeRatios(_ ratios: [UUID: Double]) -> [UUID: Double] {
        let positive = ratios.filter { $0.value > 0 }
        guard !positive.isEmpty else { return [:] }
        let total = positive.values.reduce(0, +)
        guard total > 0 else { return positive.mapValues { _ in 0 } }
        return positive.reduce(into: [UUID: Double]()) { storage, entry in
            storage[entry.key] = entry.value / total
        }
    }

    func absoluteSpecificShares(for groupID: UUID) -> [UUID: Int] {
        guard let groupShare = majorShares[groupID], groupShare > 0 else { return [:] }
        guard var ratios = specificRatios[groupID], !ratios.isEmpty else { return [:] }

        ratios = normalizeRatios(ratios)
        let rawShares = ratios.mapValues { Double(groupShare) * $0 }
        var result = rawShares.mapValues { Int(floor($0)) }
        var assigned = result.values.reduce(0, +)
        var remainder = groupShare - assigned

        if remainder > 0 {
            let sorted = rawShares
                .map { (key: $0.key, remainder: $0.value - Double(result[$0.key] ?? 0)) }
                .sorted { $0.remainder > $1.remainder }
            for entry in sorted where remainder > 0 {
                result[entry.key, default: 0] += 1
                remainder -= 1
            }
        }

        return result
    }
}

// MARK: - Supporting Views & Models

private struct CategoryChipsView: View {
    let categories: [WorkoutCategoryTag]
    @Binding var selection: Set<UUID>

    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 110), spacing: 8)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(categories) { category in
                let isSelected = selection.contains(category.id)
                Button {
                    if isSelected {
                        selection.remove(category.id)
                    } else {
                        selection.insert(category.id)
                    }
                } label: {
                    Text(category.name)
                        .font(.footnote)
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
        .padding(.vertical, 4)
    }
}

private struct MajorGroupEditorRow: View {
    let group: MajorMuscleGroup
    let isActive: Bool
    let majorShareBinding: Binding<Double>
    let onToggle: (Bool) -> Void
    let specificMuscles: [SpecificMuscle]
    let specificBindings: [SpecificMuscleBinding]
    let normalizedSpecificAction: () -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: Binding(get: { isActive }, set: onToggle)) {
                HStack {
                    Text(group.name)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(majorShareBinding.wrappedValue, specifier: "%.0f")%")
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: .accentColor))

            if isActive {
                Slider(value: majorShareBinding, in: 0...100, step: 1)
                if !specificMuscles.isEmpty {
                    DisclosureGroup(isExpanded: $isExpanded) {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(specificBindings, id: \.muscle.id) { binding in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(binding.muscle.name)
                                        Spacer()
                                        Text("\(binding.binding.wrappedValue, specifier: "%.0f")% of group")
                                            .foregroundColor(.secondary)
                                    }
                                    Slider(value: binding.binding, in: 0...100, step: 1)
                                    Text("Exercise share: \(binding.absoluteShare)%")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Button("Evenly distribute") {
                                normalizedSpecificAction()
                            }
                            .font(.footnote)
                        }
                        .padding(.top, 8)
                    } label: {
                        Text("Specific muscles")
                            .font(.footnote)
                            .foregroundColor(.accentColor)
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }
}

struct SpecificMuscleBinding {
    let muscle: SpecificMuscle
    let binding: Binding<Double>
    let absoluteShare: Int
}
