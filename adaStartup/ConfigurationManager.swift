import Foundation
import Combine // For ObservableObject and @Published
import SwiftUI

class ConfigurationManager: ObservableObject {
    @Published var appConfigs: [AppConfig] = []
    private let userDefaultsKey = "appConfigs_v1" // Added versioning to key for future migrations
    private let defaultPresetName = "Default"

    // Define a set of default configurations that can be used if no saved data exists
    // or if the user wants to reset to defaults.
    // Ensure actual bundle IDs and paths are correct for these defaults if they are to work.
    private var defaultAppConfigs: [AppConfig] = [
        AppConfig(appName: "Cursor", bundleIdentifier: "com.cursor.Cursor", appPath: "/Applications/Cursor.app", soundFileName: "depth"),
        AppConfig(appName: "Windsurf", bundleIdentifier: "com.example.Windsurf", appPath: "/Applications/Windsurf.app", soundFileName: "wooly"),
        AppConfig(appName: "Visual Studio Code", bundleIdentifier: "com.microsoft.VSCode", appPath: "/Applications/Visual Studio Code.app", soundFileName: "sparse")
    ]

    init() {
        loadAppConfigs()
        if appConfigs.isEmpty && !defaultAppConfigs.isEmpty {
            print("No saved configurations, loading initial default set.")
            appConfigs = defaultAppConfigs
            saveAppConfigs() // Save them immediately
        }
    }

    func loadAppConfigs() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey) {
            do {
                let decoder = JSONDecoder()
                var loadedConfigs = try decoder.decode([AppConfig].self, from: data) // Make mutable
                print("Loaded \(loadedConfigs.count) app configurations from UserDefaults.")

                // Migration/Normalization step for default app soundFileNames
                for i in 0..<loadedConfigs.count {
                    // Create a mutable copy of the config to modify it
                    var config = loadedConfigs[i]
                    
                    // Check and normalize Cursor
                    if config.bundleIdentifier == "com.cursor.Cursor" && config.soundFileName == "depth.wav" {
                        config.soundFileName = "depth"
                    }
                    // Check and normalize Windsurf
                    else if config.bundleIdentifier == "com.example.Windsurf" && config.soundFileName == "wooly.wav" {
                        config.soundFileName = "wooly"
                    }
                    // Check and normalize Visual Studio Code
                    else if config.bundleIdentifier == "com.microsoft.VSCode" && config.soundFileName == "sparse.wav" {
                        config.soundFileName = "sparse"
                    }
                    // Update the array with the potentially modified config
                    loadedConfigs[i] = config
                }
                self.appConfigs = loadedConfigs // Assign the potentially modified array
                print("Normalized soundFileNames for default apps if necessary.")
                return
            } catch {
                print("Error decoding app configs: \(error). Will attempt to load defaults if available.")
            }
        }
        // If loading fails or no data, appConfigs remains empty or gets defaults in init.
        print("No configurations found in UserDefaults or decoding failed.")
    }

    func saveAppConfigs() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(appConfigs)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
            print("Saved \(appConfigs.count) app configurations to UserDefaults.")
        } catch {
            print("Error encoding app configs: \(error)")
        }
    }

    func addAppConfig(_ config: AppConfig) {
        if !appConfigs.contains(where: { $0.bundleIdentifier == config.bundleIdentifier }) {
            appConfigs.append(config)
            saveAppConfigs()
            print("Added new app config: \(config.appName)")
        } else {
            print("App config for \(config.bundleIdentifier) already exists.")
        }
    }

    func updateAppConfig(_ config: AppConfig) {
        if let index = appConfigs.firstIndex(where: { $0.id == config.id }) {
            appConfigs[index] = config
            saveAppConfigs()
            print("Updated app config: \(config.appName) (ID: \(config.id))")
        } else {
            print("Could not find app config with ID \(config.id) to update.")
        }
    }

    // Provides a binding to a specific AppConfig, enabling two-way updates from views
    func bindingForApp(id: UUID) -> Binding<AppConfig>? {
        guard let index = appConfigs.firstIndex(where: { $0.id == id }) else {
            return nil
        }
        // Explicitly create the binding
        return Binding(
            get: { self.appConfigs[index] },
            set: { self.appConfigs[index] = $0 }
        )
    }

    func deleteAppConfig(at offsets: IndexSet) {
        appConfigs.remove(atOffsets: offsets)
        saveAppConfigs()
        print("Deleted app config at offsets: \(offsets)")
    }
    
    func deleteAppConfig(with id: UUID) {
        if let index = appConfigs.firstIndex(where: { $0.id == id }) {
            appConfigs.remove(at: index)
            saveAppConfigs()
            print("Deleted app config with ID: \(id)")
        }
    }

    func getConfig(for bundleId: String) -> AppConfig? {
        return appConfigs.first(where: { $0.bundleIdentifier == bundleId })
    }
    
    // Function to reset to default configurations
    func resetToDefaults() {
        appConfigs = defaultAppConfigs
        saveAppConfigs()
        print("Reset configurations to defaults (\(defaultAppConfigs.count) items)." )
    }

    // MARK: - Preset Management

    private func presetKey(forName name: String) -> String {
        return "appConfigPreset_\(name)"
    }

    func savePreset(name: String) {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("Preset name cannot be empty.")
            return
        }
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(appConfigs)
            UserDefaults.standard.set(data, forKey: presetKey(forName: name))
            print("Saved preset '\(name)' with \(appConfigs.count) app configurations.")
        } catch {
            print("Error encoding preset '\(name)': \(error)")
        }
    }

    func loadPreset(name: String) {
        if name == defaultPresetName {
            print("Loading Default preset.")
            resetToDefaults()
            // Note: resetToDefaults already calls saveAppConfigs, so current config becomes default
            return
        }

        let key = presetKey(forName: name)
        if let data = UserDefaults.standard.data(forKey: key) {
            do {
                let decoder = JSONDecoder()
                appConfigs = try decoder.decode([AppConfig].self, from: data)
                saveAppConfigs() // Save the loaded preset as the current configuration
                print("Loaded preset '\(name)' with \(appConfigs.count) app configurations.")
            } catch {
                print("Error decoding preset '\(name)': \(error).")
            }
        } else {
            print("No preset found with name '\(name)'.")
        }
    }

    func deletePreset(name: String) {
        if name == defaultPresetName {
            print("Cannot delete the Default preset.")
            return
        }
        let key = presetKey(forName: name)
        if UserDefaults.standard.object(forKey: key) != nil {
            UserDefaults.standard.removeObject(forKey: key)
            print("Deleted preset '\(name)'.")
        } else {
            print("No preset found with name '\(name)' to delete.")
        }
    }

    func listPresets() -> [String] {
        let prefix = "appConfigPreset_"
        let presetKeys = UserDefaults.standard.dictionaryRepresentation().keys.filter { $0.hasPrefix(prefix) }
        var presetNames = presetKeys.map { $0.replacingOccurrences(of: prefix, with: "") }
        
        // Ensure "Default" is always an option, and appears first
        if !presetNames.contains(defaultPresetName) {
            presetNames.append(defaultPresetName) // Add if not saved by user (legacy or if user named a preset "Default")
        }
        presetNames.sort()
        if let defaultIndex = presetNames.firstIndex(of: defaultPresetName) {
            let defaultName = presetNames.remove(at: defaultIndex)
            presetNames.insert(defaultName, at: 0)
        }

        print("Found presets: \(presetNames)")
        return presetNames
    }

    // Function to get the default configurations array
    func getDefaultConfigs() -> [AppConfig] {
        return defaultAppConfigs
    }
} 
