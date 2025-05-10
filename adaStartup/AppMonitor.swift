import Foundation
import AppKit

class AppMonitor: ObservableObject {
    private let soundManager: SoundManager
    
    init(soundManager: SoundManager) {
        print("AppMonitor initializing...")
        self.soundManager = soundManager
        setupNotificationObservers()
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
        print("App launch detected!")
        
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let appName = app.localizedName else {
            print("Failed to get app information from notification")
            return
        }
        
        print("Launched app: \(appName)")
        
        // Check if this is one of our monitored apps
        if soundManager.configuredAppNames.contains(appName) {
            print("\(appName) app detected - playing sound")
            soundManager.playSound(for: appName)
        } else {
            print("Unmonitored app launched: \(appName)")
        }
    }
    
    deinit {
        print("AppMonitor deinitializing...")
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
} 