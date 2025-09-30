import Foundation
import SwiftData

protocol SettingsRepository {
    @MainActor
    func fetchOrCreateSettings() throws -> AppSettings
    @MainActor
    func save(settings: AppSettings) throws
}

@MainActor
final class SwiftDataSettingsRepository: SettingsRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchOrCreateSettings() throws -> AppSettings {
        let descriptor = FetchDescriptor<AppSettings>()
        if let existing = try context.fetch(descriptor).first {
            return existing
        }
        let settings = AppSettings()
        context.insert(settings)
        try context.save()
        return settings
    }

    func save(settings: AppSettings) throws {
        let targetID = settings.id
        let descriptor = FetchDescriptor<AppSettings>(
            predicate: #Predicate { $0.id == targetID }
        )
        if try context.fetch(descriptor).isEmpty {
            context.insert(settings)
        }
        try context.save()
    }
}

final class UnimplementedSettingsRepository: SettingsRepository {
    func fetchOrCreateSettings() throws -> AppSettings {
        fatalError("SettingsRepository not injected")
    }

    func save(settings: AppSettings) throws {
        fatalError("SettingsRepository not injected")
    }
}
