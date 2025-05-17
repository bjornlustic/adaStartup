import Foundation
import ServiceManagement
import Combine // Import Combine for ObservableObject and Published

class LaunchAtLoginManager: ObservableObject { // Conform to ObservableObject

    // No longer using a separate helper bundle ID for SMAppService.mainApp
    // private let helperBundleID = "com.ada.adaStartupLauncher" 

    static let shared = LaunchAtLoginManager()

    // This is the private, published state that SwiftUI will observe.
    @Published private var launchStateIsEffectivelyEnabled: Bool = false

    private init() {
        // Initialize the launchStateIsEffectivelyEnabled with the actual current system state.
        self.launchStateIsEffectivelyEnabled = getCurrentLaunchState()
    }

    // Helper function to get current state, callable from init and setter.
    private func getCurrentLaunchState() -> Bool {
        if #available(macOS 13.0, *) {
            // Use mainApp for the current application
            return SMAppService.mainApp.status == .enabled
        } else {
            // SMLoginItemSetEnabled was for helper tools. 
            // For self-registration, this path is less straightforward with older APIs.
            // We'll assume false or read a persistent flag if you had one for older systems,
            // but direct self-registration with SMLoginItemSetEnabled is not its primary use.
            // For simplicity, let's reflect that direct self-registration is hard pre-macOS 13.
            print("Launch at login status for self on macOS < 13 is not managed by this version of LaunchAtLoginManager using SMLoginItemSetEnabled.")
            return UserDefaults.standard.bool(forKey: "mainAppLaunchAtLoginEnabled") // Example key
        }
    }

    var isLaunchAtLoginEnabled: Bool {
        get {
            // Return the privately stored and published state.
            return launchStateIsEffectivelyEnabled
        }
        set {
            // Manually call objectWillChange.send() before changing the underlying state
            // and performing side effects. This ensures SwiftUI is notified correctly.
            objectWillChange.send()
            
            let valueChanged = launchStateIsEffectivelyEnabled != newValue
            // Update internal state immediately. If registration fails, we might revert or log.
            launchStateIsEffectivelyEnabled = newValue 

            if valueChanged {
                if #available(macOS 13.0, *) {
                    do {
                        if newValue {
                            try SMAppService.mainApp.register()
                            print("macOS 13+: Successfully registered main app to launch at login.")
                        } else {
                            try SMAppService.mainApp.unregister()
                            print("macOS 13+: Successfully unregistered main app from launch at login.")
                        }
                    } catch {
                        let action = newValue ? "register" : "unregister"
                        print("macOS 13+: Failed to \(action) main app: \(error.localizedDescription)")
                        // Revert state on failure
                        launchStateIsEffectivelyEnabled = !newValue
                        // objectWillChange.send() // Notify observers of reversion if necessary
                    }
                } else {
                    // SMLoginItemSetEnabled is not meant for the main application itself directly.
                    // This path would typically involve a helper tool.
                    // For self-registration, this approach is problematic on older macOS.
                    print("Warning: Attempting to set launch at login for the main app on macOS < 13. This is not supported by SMLoginItemSetEnabled for the main app itself. Please use a helper tool or this will likely not work as expected.")
                    // Persist the desired state if you want to try, but it's unlikely to work.
                    UserDefaults.standard.set(newValue, forKey: "mainAppLaunchAtLoginEnabled")
                    // launchStateIsEffectivelyEnabled = !newValue // Revert if it's known not to work
                }
            }
        }
    }
}

// How to use:
// To enable: LaunchAtLoginManager.shared.isLaunchAtLoginEnabled = true
// To disable: LaunchAtLoginManager.shared.isLaunchAtLoginEnabled = false
// To check status: let status = LaunchAtLoginManager.shared.isLaunchAtLoginEnabled 