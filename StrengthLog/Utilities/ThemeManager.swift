import SwiftUI
import OSLog

/// A utility class to help manage theme-aware functionality throughout the app
class ThemeManager: ObservableObject {
    @Published private(set) var currentSettings: AppSettings?
    
    private var settingsRepository: SettingsRepository?
    private let logger = Logger(subsystem: "com.adityamishra.StrengthLog", category: "ThemeManager")
    
    init() {}
    
    @MainActor
    func initialize(with repository: SettingsRepository) {
        settingsRepository = repository
        loadSettings()
    }
    
    @MainActor
    private func loadSettings() {
        guard let repository = settingsRepository else { return }
        do {
            let settings = try repository.fetchOrCreateSettings()
            objectWillChange.send()
            currentSettings = settings
        } catch {
            logger.error("Error loading settings: \(String(describing: error))")
            let fallback = AppSettings()
            objectWillChange.send()
            currentSettings = fallback
        }
    }

    @MainActor
    func updateTheme(_ themeMode: ThemeMode) {
        objectWillChange.send()
        currentSettings?.themeMode = themeMode
        saveSettings()
    }
    
    @MainActor
    func updateAccentColor(_ color: AppAccentColor) {
        objectWillChange.send()
        currentSettings?.accentColor = color
        saveSettings()
    }
    
    @MainActor
    func updateWeightUnit(_ unit: WeightUnit) {
        objectWillChange.send()
        currentSettings?.defaultWeightUnit = unit
        saveSettings()
    }
    
    @MainActor
    func updateAdvancedStats(_ enabled: Bool) {
        objectWillChange.send()
        currentSettings?.showAdvancedStats = enabled
        saveSettings()
    }
    
    @MainActor
    private func saveSettings() {
        guard let repository = settingsRepository, let settings = currentSettings else { return }
        do {
            try repository.save(settings: settings)
        } catch {
            logger.error("Error saving settings: \(String(describing: error))")
        }
    }
    
    // MARK: - Convenience Properties
    
    @MainActor
    var colorScheme: ColorScheme? {
        currentSettings?.themeMode.colorScheme
    }
    
    @MainActor
    var accentColor: Color {
        currentSettings?.accentColor.color ?? .blue
    }
    
    @MainActor
    var weightUnit: WeightUnit {
        currentSettings?.defaultWeightUnit ?? .kg
    }
    
    @MainActor
    var showAdvancedStats: Bool {
        currentSettings?.showAdvancedStats ?? true
    }

}

/// Environment key for ThemeManager
struct ThemeManagerKey: EnvironmentKey {
    static let defaultValue = ThemeManager()
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}

/// View modifier to apply theme-aware styling
struct ThemeAware: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager
    
    func body(content: Content) -> some View {
        content
            .tint(themeManager.accentColor)
    }
}

extension View {
    func themeAware() -> some View {
        modifier(ThemeAware())
    }
}
