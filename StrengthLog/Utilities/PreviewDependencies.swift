import SwiftUI
import SwiftData

/// Lightweight dependency container to hydrate previews with repositories and theme state.
@MainActor
struct PreviewDependencies {
    let container: ModelContainer
    let repositories: RepositoryProvider
    let themeManager: ThemeManager

    init(container: ModelContainer) {
        self.container = container
        self.repositories = RepositoryProvider(context: container.mainContext)
        let manager = ThemeManager()
        manager.initialize(with: repositories.settingsRepository)
        self.themeManager = manager
    }

    init(
        models: [any PersistentModel.Type],
        configuration: ModelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
    ) throws {
        let schema = Schema(models)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        self.init(container: container)
    }

    func apply<V: View>(to view: V) -> some View {
        view
            .modelContainer(container)
            .environmentObject(themeManager)
            .environment(\.exerciseRepository, repositories.exerciseRepository)
            .environment(\.workoutRepository, repositories.workoutRepository)
            .environment(\.settingsRepository, repositories.settingsRepository)
    }
}
