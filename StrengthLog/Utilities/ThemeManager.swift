import SwiftUI
import SwiftData

/// A utility class to help manage theme-aware functionality throughout the app
class ThemeManager: ObservableObject {
    @Published var currentSettings: AppSettings?
    
    private var modelContext: ModelContext?
    
    init() {}
    
    @MainActor
    func initialize(with context: ModelContext) {
        self.modelContext = context
        loadSettings()
    }
    
    @MainActor
    private func loadSettings() {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<AppSettings>()
        do {
            let settings = try context.fetch(descriptor)
            if let existingSettings = settings.first {
                currentSettings = existingSettings
            } else {
                // Create default settings
                let newSettings = AppSettings()
                context.insert(newSettings)
                try context.save()
                currentSettings = newSettings
            }
        } catch {
            print("Error loading settings: \(error)")
            // Fallback to default settings
            currentSettings = AppSettings()
        }
    }
    
    @MainActor
    func updateTheme(_ themeMode: ThemeMode) {
        currentSettings?.themeMode = themeMode
        saveSettings()
    }
    
    @MainActor
    func updateAccentColor(_ color: AppAccentColor) {
        currentSettings?.accentColor = color
        saveSettings()
    }
    
    @MainActor
    func updateWeightUnit(_ unit: WeightUnit) {
        currentSettings?.defaultWeightUnit = unit
        saveSettings()
    }
    
    @MainActor
    func updateAdvancedStats(_ enabled: Bool) {
        currentSettings?.showAdvancedStats = enabled
        saveSettings()
    }
    
    @MainActor
    private func saveSettings() {
        guard let context = modelContext else { return }
        do {
            try context.save()
        } catch {
            print("Error saving settings: \(error)")
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
    @Environment(\.themeManager) var themeManager
    
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
