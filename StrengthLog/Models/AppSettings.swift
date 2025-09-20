import Foundation
import SwiftData
import SwiftUI

@Model
final class AppSettings {
    @Attribute(.unique) var id: UUID
    var themeMode: ThemeMode
    var accentColor: AppAccentColor
    var showAdvancedStats: Bool
    var defaultWeightUnit: WeightUnit

    init() {
        self.id = UUID()
        self.themeMode = .system
        self.accentColor = .blue
        self.showAdvancedStats = true
        self.defaultWeightUnit = .kg
    }
}

enum ThemeMode: String, CaseIterable, Codable, Identifiable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"
    
    var id: String { self.rawValue }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
    
    var systemImage: String {
        switch self {
        case .light: return "sun.max"
        case .dark: return "moon"
        case .system: return "circle.lefthalf.filled"
        }
    }
}

enum AppAccentColor: String, CaseIterable, Codable, Identifiable {
    case blue = "Blue"
    case green = "Green"
    case orange = "Orange"
    case red = "Red"
    case purple = "Purple"
    case pink = "Pink"
    case indigo = "Indigo"
    case teal = "Teal"
    
    var id: String { self.rawValue }
    
    var color: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .red: return .red
        case .purple: return .purple
        case .pink: return .pink
        case .indigo: return .indigo
        case .teal: return .teal
        }
    }
}

enum WeightUnit: String, CaseIterable, Codable, Identifiable {
    case kg = "Kilograms"
    case lbs = "Pounds"
    
    var id: String { self.rawValue }
    
    var abbreviation: String {
        switch self {
        case .kg: return "kg"
        case .lbs: return "lbs"
        }
    }
}
