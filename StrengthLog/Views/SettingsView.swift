import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.settingsRepository) private var settingsRepository
    @EnvironmentObject private var themeManager: ThemeManager

    private var currentSettings: AppSettings {
        if let managerSettings = themeManager.currentSettings {
            return managerSettings
        }
        themeManager.initialize(with: settingsRepository)
        return themeManager.currentSettings ?? AppSettings()
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: HStack {
                    Image(systemName: "paintbrush.fill")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 14, weight: .medium))
                    Text("Appearance")
                        .textCase(.uppercase)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }) {
                    // Enhanced Theme Mode Selection
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "moon.stars.fill")
                                .foregroundColor(.purple)
                                .font(.system(size: 16, weight: .medium))
                                .frame(width: 24)
                            Text("Theme")
                                .font(.system(size: 16, weight: .medium))
                            Spacer()
                        }
                        
                        HStack(spacing: 12) {
                            ForEach(ThemeMode.allCases) { mode in
                                Button(action: {
                                    themeManager.updateTheme(mode)
                                }) {
                                    VStack(spacing: 6) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(currentSettings.themeMode == mode ? Color.accentColor.opacity(0.1) : Color.clear)
                                                .frame(width: 44, height: 44)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                            .stroke(currentSettings.themeMode == mode ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: currentSettings.themeMode == mode ? 2 : 1)
                                                )
                                            
                                            Image(systemName: mode.systemImage)
                                                .foregroundColor(currentSettings.themeMode == mode ? .accentColor : .secondary)
                                                .font(.system(size: 18, weight: .medium))
                                        }
                                        
                                        Text(mode.rawValue)
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(currentSettings.themeMode == mode ? .accentColor : .secondary)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // Enhanced Accent Color Selection
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "palette.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 16, weight: .medium))
                                .frame(width: 24)
                            Text("Accent Color")
                                .font(.system(size: 16, weight: .medium))
                            Spacer()
                        }
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                            ForEach(AppAccentColor.allCases) { color in
                                Button(action: {
                                    themeManager.updateAccentColor(color)
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(color.color)
                                            .frame(width: 44, height: 44)
                                            .shadow(color: color.color.opacity(0.3), radius: currentSettings.accentColor == color ? 4 : 0, x: 0, y: 2)
                                        
                                        Circle()
                                            .stroke(currentSettings.accentColor == color ? Color.white : Color.clear, lineWidth: 3)
                                            .frame(width: 44, height: 44)
                                        
                                        if currentSettings.accentColor == color {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.white)
                                                .font(.system(size: 16, weight: .bold))
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                .scaleEffect(currentSettings.accentColor == color ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: currentSettings.accentColor)
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: HStack {
                    Image(systemName: "gear.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 14, weight: .medium))
                    Text("Data & Display")
                        .textCase(.uppercase)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "scalemass.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 16, weight: .medium))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Weight Unit")
                                .font(.system(size: 16, weight: .medium))
                            Text("Default unit for weights")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Picker("Weight Unit", selection: Binding(
                            get: { themeManager.weightUnit },
                            set: { newValue in
                                themeManager.updateWeightUnit(newValue)
                            }
                        )) {
                            ForEach(WeightUnit.allCases) { unit in
                                Text(unit.rawValue).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .padding(.vertical, 4)
                    
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.green.opacity(0.1))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "chart.xyaxis.line")
                                .foregroundColor(.green)
                                .font(.system(size: 16, weight: .medium))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Advanced Statistics")
                                .font(.system(size: 16, weight: .medium))
                            Text("Show detailed analytics")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { currentSettings.showAdvancedStats },
                            set: { newValue in
                                themeManager.updateAdvancedStats(newValue)
                            }
                        ))
                    }
                    .padding(.vertical, 4)
                }

                Section(header: HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 14, weight: .medium))
                    Text("About")
                        .textCase(.uppercase)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.purple.opacity(0.1))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.purple)
                                .font(.system(size: 16, weight: .medium))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Version")
                                .font(.system(size: 16, weight: .medium))
                            Text("App version number")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("2.3.0")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.accentColor)
                    }
                    .padding(.vertical, 4)
                    
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.orange.opacity(0.1))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "hammer.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 16, weight: .medium))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Build")
                                .font(.system(size: 16, weight: .medium))
                            Text("Latest update")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("Enhanced UI")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.accentColor)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ExerciseDefinition.self, WorkoutRecord.self, SetEntry.self, AppSettings.self,
        configurations: config
    )
    let dependencies = PreviewDependencies(container: container)
    return dependencies.apply(to: SettingsView())
}
