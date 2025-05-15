import Foundation
import AppKit
import Combine // Required for AnyCancellable

@MainActor // Annotate AppMonitor with @MainActor
class AppMonitor: ObservableObject {
    private let soundManager: SoundManager
    private let configManager: ConfigurationManager
    private var cancellables = Set<AnyCancellable>() // To hold cancellable for configManager updates
    
    // We don't need to publish appConfigs here if AppMonitor just reacts to configManager
    // However, if UI elements directly dependent on AppMonitor need this, it could be kept.
    // For now, assume AppMonitor internally uses configManager.appConfigs
    
    init(soundManager: SoundManager, configManager: ConfigurationManager) {
        print("AppMonitor initializing...")
        self.soundManager = soundManager
        self.configManager = configManager
        setupNotificationObservers()
        
        // Observe changes in ConfigurationManager.appConfigs
        // This ensures that if configurations are added/removed/updated while AppMonitor is live,
        // it doesn't need to be manually told to refresh its understanding of what to monitor.
        // However, since handleAppLaunch reads directly from configManager.getConfig each time,
        // explicit observation here might be redundant unless caching is introduced in AppMonitor.
        // For simplicity and to ensure up-to-date checks, direct reads in handleAppLaunch are fine.
        // If performance became an issue with many configs, we might cache bundle IDs, then observe.
        print("AppMonitor initialized. Monitoring for app launches based on ConfigurationManager.")
    }
    
    private func setupNotificationObservers() {
        let workspace = NSWorkspace.shared
        let notificationCenter = workspace.notificationCenter
        
        print("Setting up app launch observer...")
        
        // Observe app launches
        notificationCenter.addObserver(
            self,
            selector: #selector(handleAppLaunch),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )
        
        print("App launch observer setup complete")
    }
    
    @objc private func handleAppLaunch(_ notification: Notification) {
        print("App launch detected by AppMonitor!")
        
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let appBundleID = app.bundleIdentifier else {
            print("AppMonitor: Failed to get app bundle ID from notification")
            return
        }
        
        let appName = app.localizedName ?? "UnknownApp" // For logging
        print("AppMonitor: Launched app - Name: \(appName), BundleID: \(appBundleID)")
        
        // Check ConfigurationManager directly for the current configuration
        if let appConfig = configManager.getConfig(for: appBundleID) {
            print("AppMonitor: Monitored app \(appConfig.appName) detected. Sound: \(appConfig.soundFileName), Activated: \(appConfig.isActivated)")
            if !appConfig.isActivated {
                print("AppMonitor: Startup sound for \(appConfig.appName) is deactivated. No sound will be played.")
                return
            }
            
            if appConfig.soundFileName.isEmpty {
                print("AppMonitor: No sound assigned to \(appConfig.appName). Nothing to play.")
            } else {
                // This call is now safe as both AppMonitor and SoundManager are on MainActor
                soundManager.playSound(soundFileName: appConfig.soundFileName, volume: appConfig.volume)
            }
        } else {
            // This is noisy, consider making it a debug-only log or removing if not needed
            // print("AppMonitor: Unmonitored app launched - \(appName) (\(appBundleID))")
        }
    }
    
    deinit {
        print("AppMonitor deinitializing...")
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        cancellables.forEach { $0.cancel() }
    }
} 