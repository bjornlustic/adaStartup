//
//  ContentView.swift
//  adaStartup
//
//  Created by Bjorn Lustic on 5/9/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var configManager: ConfigurationManager
    @EnvironmentObject var soundManager: SoundManager
    
    // For the NSOpenPanel & Alerts
    @State private var showingFileImporter = false // Keep if needed for add sound/app
    @State private var showingAlert = false // Generic alert
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    // State to manage which view is shown in the main content area
    @State private var selectedContent: ContentAreaView = .dashboard // Default view
    @State private var selectedAppConfigId: UUID? = nil
    @State private var searchText: String = "" // State for the search text

    // State for app deletion confirmation alert
    @State private var showingAppDeleteConfirmationAlert = false
    @State private var appConfigToDelete: AppConfig? = nil

    // State for sound deletion confirmation
    @State private var showingSoundDeleteConfirmationAlert = false
    @State private var soundFileToDelete: String? = nil

    // State for saving presets (These were missing)
    @State private var presetNameToSave: String = ""
    @State private var showingSavePresetAlert: Bool = false

    enum ContentAreaView {
        case dashboard
        case appDetail
        case settings
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // --- Sidebar ---
            VStack(alignment: .leading, spacing: 0) {

                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Search Apps", text: $searchText) // Bind to searchText
                        .textFieldStyle(PlainTextFieldStyle())
                }
                        .padding()
                .background(Color(NSColor.controlBackgroundColor)) // Slightly different background
                .border(Color.gray.opacity(0.5), width: 0.5)

                // List of Applications (Filtered)
                List { // Removed direct binding to configManager.appConfigs
                    ForEach(filteredAppConfigs) { appConfig in // Use filtered list
                        Button(action: {
                            selectedAppConfigId = appConfig.id
                            selectedContent = .appDetail
                        }) {
                            HStack {
                                Image(nsImage: appConfig.icon ?? NSImage(named: NSImage.applicationIconName)!)
                                    .resizable().aspectRatio(contentMode: .fit).frame(width: 30, height: 30)
                                Text(appConfig.appName)
                                    .font(.body)
                                Spacer()
                                if selectedAppConfigId == appConfig.id {
                                    Image(systemName: "chevron.right") // Indicate selection
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle()) // To make list items clickable
                    }
                }
                .listStyle(SidebarListStyle()) // More appropriate for a sidebar

                Spacer() // Pushes settings to the bottom

                // Settings Button
                HStack {
                    Button(action: {
                        selectedContent = .settings
                        selectedAppConfigId = nil
                    }) {
                        HStack {
                            Image(systemName: "gear")
                            Text("Settings")
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    // Remove Selected App Button
                    Button(action: removeSelectedApp) {
                        Image(systemName: "minus.circle")
                            .font(.title2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(selectedAppConfigId == nil) // Disable if no app selected
                    
                    // Add App Button
                    Button(action: presentAddAppPanel) {
                        Image(systemName: "plus.circle")
                            .font(.title2)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding()
                .frame(maxWidth: .infinity) // Ensure HStack takes full width for Spacer to work
            }
            .frame(minWidth: 200, idealWidth: 250, maxWidth: 300) // Sidebar width
            .background(Color(NSColor.windowBackgroundColor))


            // --- Main Content Area ---
            VStack {
                switch selectedContent {
                case .dashboard:
                    Text("") // Placeholder
                        .font(.largeTitle)
                case .appDetail:
                    if let appConfigId = selectedAppConfigId,
                       let appConfigBinding = configManager.bindingForApp(id: appConfigId) {
                        AppDetailView(appConfig: appConfigBinding, soundManager: soundManager)
                    } else {
                        Text("Select an app to see details.")
                    }
                case .settings:
                    SettingsView(configManager: configManager, 
                                 showingAlert: $showingAlert, 
                                 alertTitle: $alertTitle, 
                                 alertMessage: $alertMessage,
                                 // Pass bindings for app deletion confirmation
                                 showingAppDeleteConfirmationAlert: $showingAppDeleteConfirmationAlert,
                                 appConfigToDelete: $appConfigToDelete)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Takes remaining space
            .background(Color(NSColor.controlBackgroundColor)) // Different background for content
        }
        .frame(minWidth: 700, idealWidth: 800, maxWidth: 1000, minHeight: 400, idealHeight: 500, maxHeight: 600) // Overall window size
        .alert(isPresented: $showingAlert) { // Generic info alert
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .alert("Confirm Application Deletion", isPresented: $showingAppDeleteConfirmationAlert, presenting: appConfigToDelete) { configToDel in
            Button("OK") { 
                let idToDelete = configToDel.id // Capture the ID to delete

                // First, ensure the UI navigates away if the deleted app is the selected one
                if selectedAppConfigId == idToDelete {
                    selectedAppConfigId = nil
                    selectedContent = .dashboard 
                }
                
                // Then, dispatch the actual deletion to the next run loop cycle
                // This allows SwiftUI to process UI state changes first.
                DispatchQueue.main.async {
                    self.configManager.deleteAppConfig(with: idToDelete)
                }
                
                // Do not show success alert
                // alertTitle = "Application Removed"
                // alertMessage = "Successfully removed \'\\(configToDel.appName)\'."
                // showingAlert = true
            }
            Button("Cancel", role: .cancel) { }
        } message: { configToDel in
            Text("Are you sure you want to remove this app from monitoring? This action cannot be undone.")
        }
        // Remove .navigationTitle and .toolbar as we're not using NavigationView in the same way
    }

    // Computed property to filter appConfigs based on searchText
    var filteredAppConfigs: [AppConfig] {
        if searchText.isEmpty {
            return configManager.appConfigs
        } else {
            return configManager.appConfigs.filter { $0.appName.localizedCaseInsensitiveContains(searchText) }
        }
    }

    // Method to present the panel for adding a new application
    private func presentAddAppPanel() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedContentTypes = [.applicationBundle] 

        if openPanel.runModal() == .OK {
            if let url = openPanel.url {
                let appPath = url.path
                guard let bundle = Bundle(url: url), 
                      let bundleIdentifier = bundle.bundleIdentifier else {
                    self.alertTitle = "Error Adding App"
                    self.alertMessage = "Could not get bundle identifier for the selected application. Make sure it is a valid .app file."
                    self.showingAlert = true
                    return
                }
                
                let appName = (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String) ?? 
                              (bundle.object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String) ?? 
                              FileManager.default.displayName(atPath: appPath)
                
                let newConfig = AppConfig(appName: appName, 
                                          bundleIdentifier: bundleIdentifier, 
                                          appPath: appPath, 
                                          soundFileName: "")
                configManager.addAppConfig(newConfig)
                // Optionally, select the newly added app
                if let addedConfig = configManager.appConfigs.first(where: { $0.bundleIdentifier == bundleIdentifier }) {
                    selectedAppConfigId = addedConfig.id
                    selectedContent = .appDetail
                }
            }
        }
    }

    // Method to remove the currently selected application
    private func removeSelectedApp() {
        guard let appIdToRemove = selectedAppConfigId else { return }
        
        if let appToDel = configManager.appConfigs.first(where: { $0.id == appIdToRemove }) {
            self.appConfigToDelete = appToDel
            self.showingAppDeleteConfirmationAlert = true
        } else {
            // Should not happen if selectedAppConfigId is valid
            print("Error: Tried to delete an app that no longer exists in configManager.")
        }
    }

    // Functions like presentAddAppPanel, presentAddSoundPanel, deleteItems will need to be
    // refactored or integrated into the new views (e.g., AddSoundView, SettingsView, etc.)
    // For now, I'm commenting out the old ones.

//    private func deleteItems(at offsets: IndexSet) {
//        configManager.deleteAppConfig(at: offsets)
//    }
//    
//    private func presentAddSoundPanel() {
//        // ... (This logic will move to AddSoundView)
//    }
}

// Placeholder for AppDetailView
struct AppDetailView: View {
    @Binding var appConfig: AppConfig
    @ObservedObject var soundManager: SoundManager // Changed to ObservedObject

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(nsImage: appConfig.icon ?? NSImage(named: NSImage.applicationIconName)!)
                    .resizable().aspectRatio(contentMode: .fit).frame(width: 48, height: 48)
                Text(appConfig.appName)
                    .font(.title)
            }
            .padding(.bottom)

            // Text("Bundle ID: \\(appConfig.bundleIdentifier)") // Removed
            // Text("Path: \\(appConfig.appPath)") // Removed
            
            // Group Picker and Preview button for cleaner look
            HStack {
                Picker("Sound", selection: $appConfig.soundFileName) {
                    ForEach(soundManager.availableSoundFilesForPicker, id: \.self) { soundName in
                        Text(soundName).tag(soundName)
                    }
                }
                .onChange(of: appConfig.soundFileName) { oldValue, newValue in
                     if newValue == SoundManager.noSoundIdentifier {
                         appConfig.soundFileName = ""
                     } else {
                         appConfig.soundFileName = newValue
                     }
                }
                .frame(maxWidth: 200)

                if !appConfig.soundFileName.isEmpty && appConfig.soundFileName != SoundManager.noSoundIdentifier {
                    Button {
                        // Pass the current volume when previewing
                        soundManager.playSound(soundFileName: appConfig.soundFileName, volume: appConfig.volume)
                    } label: {
                        Image(systemName: "play.circle.fill")
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.leading, 5)
                }
            }
            .padding(.top)

            Toggle("Activate Startup Sound", isOn: $appConfig.isActivated)
                 // .onChange will also automatically save due to the binding.
                .padding(.top)

            // Volume Slider
            HStack {
                Text("Volume:")
                Slider(value: $appConfig.volume, in: 0.0...1.0) {
                    Text("Volume")
                } minimumValueLabel: {
                    Image(systemName: "speaker.fill")
                } maximumValueLabel: {
                    Image(systemName: "speaker.wave.3.fill")
                } 
                // Display the volume as a percentage
                Text(String(format: "%.0f%%", appConfig.volume * 100))
                    .frame(width: 50, alignment: .trailing) // Increased width for 100%
            }
            .padding(.top)

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}


// Placeholder for AddSoundView - This is where sound duration check will be handled
struct AddSoundView: View {
    @ObservedObject var soundManager: SoundManager // Changed to ObservedObject
    @State private var showingFileImporter = false
    @Binding var showingAlert: Bool
    @Binding var alertTitle: String
    @Binding var alertMessage: String

    var body: some View {
        VStack {
            Text("Add Custom Sound")
                .font(.title)
                .padding()
            
            Button("Select Sound File") {
                showingFileImporter = true
            }
            .padding()
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: [.audio], // Use UTType.audio if available and preferred
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    // IMPORTANT: Ensure SoundManager's addCustomSound uses @MainActor for UI updates
                    soundManager.addCustomSound(from: url) { addResult in
                        switch addResult {
                        case .success(let addedFileName):
                            alertTitle = "Sound Added"
                            alertMessage = "Successfully added \'\(addedFileName)\' talento."
                            soundManager.refreshAvailableSounds() // Ensure picker lists are updated
                        case .failure(let anError):
                            alertTitle = "Error Adding Sound"
                            // This will now correctly display "Sound is too long..."
                            alertMessage = anError.localizedDescription 
                        }
                        showingAlert = true
                    }
                case .failure(let selectionError):
                    alertTitle = "Error Selecting File"
                    alertMessage = selectionError.localizedDescription
                    showingAlert = true
                }
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// Placeholder for SoundManagerView
struct SoundManagerView: View {
    @ObservedObject var soundManager: SoundManager // Changed to ObservedObject

    var body: some View {
        VStack(alignment: .leading) {
            Text("Manage Sounds")
                .font(.title)
                .padding(.bottom)

            List {
                ForEach(soundManager.availableSoundFilesForPicker.filter { $0 != SoundManager.noSoundIdentifier }, id: \.self) { soundFile in
                    HStack {
                        Text(soundFile)
                        Spacer()
                        // Only allow deleting custom sounds (simple check: not bundled)
                        // This is a basic check; a more robust system might be needed.
                        if !["depth.wav", "wooly.wav", "sparse.wav", "depth", "wooly", "sparse"].contains(soundFile) {
                            Button {
                                soundManager.deleteCustomSound(fileName: soundFile) { result in
                                    // Handle result, maybe show an alert
                                    switch result {
                                    case .success():
                                        print("Deleted \\(soundFile)")
                                        // UI should refresh automatically if availableSoundFilesForPicker is @Published
                                    case .failure(_):
                                        print("Error deleting \\(soundFile): \\(deletionError.localizedDescription)")
                                        // Show alert to user
                                    }
                                }
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}


// Placeholder for SettingsView
struct SettingsView: View {
    @ObservedObject var configManager: ConfigurationManager
    @EnvironmentObject var soundManager: SoundManager // Add SoundManager
    
    // Access LaunchAtLoginManager state
    @StateObject private var launchAtLoginManager = LaunchAtLoginManager.shared
    
    // Remove selectedContent binding
    // @Binding var selectedContent: ContentView.ContentAreaView 

    // States for managing sound adding and alerts
    @State private var showingAddSoundFileImporter = false
    @Binding var showingAlert: Bool
    @Binding var alertTitle: String
    @Binding var alertMessage: String
    // Add state for confirmation dialog
    @Binding var showingAppDeleteConfirmationAlert: Bool
    @Binding var appConfigToDelete: AppConfig?

    // State for sound deletion confirmation
    @State private var showingSoundDeleteConfirmationAlert = false
    @State private var soundFileToDelete: String? = nil

    // State for loading and deleting presets
    @State private var selectedPresetToLoad: String? = nil
    @State private var selectedPresetToDelete: String? = nil
    @State private var availablePresets: [String] = []
    @State private var activePresetName: String? = nil // Initialize to nil, set in onAppear/refresh

    // State for preset deletion confirmation
    @State private var presetNameToDeleteConfirm: String? = nil
    @State private var showingDeletePresetConfirmationAlert: Bool = false

    // State for saving presets (These were missing)
    @State private var presetNameToSave: String = ""
    @State private var showingSavePresetAlert: Bool = false

    // Computed property for filtered sound files to help with type checking
    private var filteredSoundFiles: [String] {
        soundManager.availableSoundFilesForPicker.filter { $0 != SoundManager.noSoundIdentifier }
    }

    var body: some View {
        ScrollView { // Added ScrollView to handle potentially long content
            VStack(alignment: .leading) {
                Text("Application Settings")
                    .font(.title)
                    .padding(.bottom)
 

                // UPDATED Sound Library Header with Plus Button
                HStack {
                    Text("Sound Library")
                        .font(.headline) // Matching "Sound Management"
                    Spacer()
                    Button(action: {
                        showingAddSoundFileImporter = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2) // Larger icon
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.top)

                if filteredSoundFiles.isEmpty { // Use the computed property
                    Text("No custom sounds in library.")
                        .foregroundColor(.secondary)
                        .padding(.vertical)
                } else {
                    List {
                        ForEach(filteredSoundFiles, id: \.self) { soundFile in // Use the computed property
                            HStack {
                                Text(soundFile)
                                Spacer()
                                
                                // Delete button (moved to the left of play)
                                if !["depth.wav", "wooly.wav", "sparse.wav", "depth", "wooly", "sparse"].contains(soundFile) {
                                    Button {
                                        // Set the sound to delete and show confirmation alert
                                        self.soundFileToDelete = soundFile
                                        self.showingSoundDeleteConfirmationAlert = true
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.trailing, 5) // Add some spacing before play button
                                }
                                
                                // Play button for previewing the sound
                                Button {
                                    soundManager.playSound(soundFileName: soundFile)
                                } label: {
                                    Image(systemName: "play.circle")
                                }
                                .buttonStyle(PlainButtonStyle()) // Use plain style for subtle button
                            }
                        }
                    }
                    .frame(minHeight: 100) // Give some min height to the list
                }

               
                // List of currently monitored applications (ensure this section exists and is complete)
                Text("Monitored Applications")
                    .font(.headline)
                    .padding(.top)

                if configManager.appConfigs.isEmpty {
                    Text("No applications being monitored.")
                        .foregroundColor(.secondary)
                        .padding(.vertical)
                } else {
                    List {
                        ForEach(configManager.appConfigs) { appConfig in
                            HStack {
                                Image(nsImage: appConfig.icon ?? NSImage(named: NSImage.applicationIconName)!)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20, height: 20)
                                Text(appConfig.appName)
                                Spacer()
                                Button {
                                    self.appConfigToDelete = appConfig
                                    self.showingAppDeleteConfirmationAlert = true
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .frame(minHeight: 100) // Give some min height to the list
                }
                
                // MARK: - Configuration Presets Management
                HStack {
                    Text("Configuration Presets")
                        .font(.headline)
                    Spacer()
                    Button(action: {
                        presetNameToSave = "" // Reset before showing
                        showingSavePresetAlert = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.top)

                if availablePresets.isEmpty {
                    // This case should ideally not happen if "Default" is always present
                    // but as a fallback:
                    Text("No presets available. Click + to save current as a new preset.")
                        .foregroundColor(.secondary)
                        .padding(.vertical)
                } else {
                    List {
                        ForEach(availablePresets, id: \.self) { presetName in
                            HStack {
                                Text(presetName)
                                Spacer()
                                if presetName == activePresetName {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                                if presetName != "Default" { // "Default" preset cannot be deleted
                                    Button {
                                        self.presetNameToDeleteConfirm = presetName
                                        self.showingDeletePresetConfirmationAlert = true
                                        // configManager.deletePreset(name: presetName) // Moved to alert
                                        // // alertTitle = "Preset Deleted" // No success pop-up as per request
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .contentShape(Rectangle()) // Make the whole row tappable
                            .onTapGesture {
                                configManager.loadPreset(name: presetName)
                                activePresetName = presetName // Set as active
                                // alertTitle = "Preset Loaded" // No success pop-up for load either if desired
                                // alertMessage = "Successfully loaded preset \'\(presetName)\'."
                                // showingAlert = true
                                refreshPresets() // Refresh in case loaded state affects something (e.g. current config becomes the preset)
                            }
                        }
                    }
                    .frame(minHeight: 100) // Give some min height to the list
                }
                
                // Launch at Login Toggle
                // Divider().padding(.vertical) // Separator before this new setting

                Toggle(isOn: $launchAtLoginManager.isLaunchAtLoginEnabled) {
                    Text("Launch at Login")
                }
                .padding(.top)

                // Quit Application Button
                Divider().padding(.vertical)
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    HStack {
                        Image(systemName: "power")
                        Text("Quit Application")
                    }
                    .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top)

                //Spacer() // Pushes content to the top
            }
            .padding() // Add padding to the VStack content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading) // Ensure SettingsView takes available space
        .fileImporter( // File importer for adding sounds
            isPresented: $showingAddSoundFileImporter,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                soundManager.addCustomSound(from: url) { addResult in
                    switch addResult {
                    case .success(_):
//                        alertTitle = "Sound Added"
//                        alertMessage = "Successfully added \\'\\(addedFileName)\\'."
                        soundManager.refreshAvailableSounds()
                    case .failure(let anError):
                        alertTitle = "Error Adding Sound"
                        alertMessage = anError.localizedDescription
                    }
                    showingAlert = true
                }
            case .failure(let error):
                alertTitle = "Error Selecting File"
                alertMessage = error.localizedDescription
                showingAlert = true
            }
        }
        .alert("Confirm Sound Deletion", isPresented: $showingSoundDeleteConfirmationAlert, presenting: soundFileToDelete) { soundToDelete in
            Button("Delete", role: .destructive) {
                soundManager.deleteCustomSound(fileName: soundToDelete) { result in
                    switch result {
                    case .success(_):
//                        alertTitle = "Sound Deleted"
//                        alertMessage = "Successfully deleted \\'\\(soundToDelete)\\'."
                        soundManager.refreshAvailableSounds() // Refresh list
                    case .failure(_):
                        alertTitle = "Error Deleting Sound"
                        alertMessage = "Could not delete \\'\\(soundToDelete)\\': \\(error.localizedDescription)"
                    }
                    showingAlert = true // Show feedback alert
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: { soundToDelete in
            Text("Are you sure you want to delete this sound file? This action cannot be undone.")
        }
        // Alert for saving preset
        .alert("Save Preset", isPresented: $showingSavePresetAlert) {
            TextField("Preset Name", text: $presetNameToSave)
            Button("Save") {
                if !presetNameToSave.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    if presetNameToSave == "Default" {
                        alertTitle = "Invalid Name"
                        alertMessage = "Cannot name a preset 'Default'. Please choose a different name."
                        showingAlert = true
                    } else {
                        configManager.savePreset(name: presetNameToSave)
                        activePresetName = presetNameToSave // Set newly saved preset as active
                        // alertTitle = "Preset Saved" // No success pop-up as per request
                        // alertMessage = "Configuration saved as preset \'\(presetNameToSave)\'."
                        // showingAlert = true 
                        refreshPresets() // Refresh the list of presets
                    }
                } else {
                    alertTitle = "Error"
                    alertMessage = "Preset name cannot be empty."
                    showingAlert = true
                }
            }
            Button("Cancel", role: .cancel) { }
        }
        // Alert for deleting preset confirmation
        .alert("Confirm Preset Deletion", isPresented: $showingDeletePresetConfirmationAlert, presenting: presetNameToDeleteConfirm) { presetName in
            Button("Delete", role: .destructive) {
                configManager.deletePreset(name: presetName)
                refreshPresets() // Refresh the list after deletion
                // If the deleted preset was active, clear the active state or set to Default
                if activePresetName == presetName {
                    if configManager.appConfigs == configManager.getDefaultConfigs() {
                        activePresetName = "Default"
                    } else {
                        activePresetName = nil
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: { presetName in
            Text("Are you sure you want to delete the preset \'\(presetName)\'? This action cannot be undone.")
        }
        .onAppear { // Refresh presets when the view appears
            refreshPresets()
            // Set initial active preset if none is set and current config matches default
            if activePresetName == nil && configManager.appConfigs == configManager.getDefaultConfigs() {
                 activePresetName = "Default"
            } else if activePresetName == nil && !configManager.listPresets().contains(where: { $0 != "Default"}) {
                 // If no user presets exist and nothing else is active, mark Default as active
                 activePresetName = "Default"
            }
        }
    }
    
    private func refreshPresets() {
        let previouslyActive = activePresetName // Store before refresh
        availablePresets = configManager.listPresets() // listPresets now sorts "Default" to top

        // If the previously active preset is still available, keep it active.
        // Otherwise, if current configs match default, set Default as active.
        // Otherwise, clear active preset.
        if let active = previouslyActive, availablePresets.contains(active) {
            activePresetName = active
        } else if configManager.appConfigs == configManager.getDefaultConfigs() {
            activePresetName = "Default"
        } else {
            activePresetName = nil
        }

        // If the selected preset for loading/deletion is no longer available, reset selection
        if let currentLoadSelection = selectedPresetToLoad, !availablePresets.contains(currentLoadSelection) {
            selectedPresetToLoad = nil
        }
        if let currentDeleteSelection = selectedPresetToDelete, !availablePresets.contains(currentDeleteSelection) {
            selectedPresetToDelete = nil
        }
    }
}


#Preview {
    let configManager = ConfigurationManager()
    let soundManager = SoundManager()
    // Example of adding a preview item:
    // configManager.addAppConfig(AppConfig(appName: "Preview App", bundleIdentifier: "com.preview.app", appPath: "/System/Applications/Utilities/Terminal.app", soundFileName: "cursor_startup"))
    return ContentView()
        .environmentObject(configManager)
        .environmentObject(soundManager)
}
