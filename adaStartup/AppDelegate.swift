import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from dock
        NSApp.setActivationPolicy(.accessory)
        
        // Create the status bar controller with the main content view
        statusBarController = StatusBarController {
            ContentView()
                .environmentObject(SoundManager())
                .environmentObject(AppMonitor(soundManager: SoundManager()))
        }
    }
    
    func applicationWillResignActive(_ notification: Notification) {
        // Close the popover when the app is no longer active
        statusBarController?.closePopover()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clean up when app is terminating
        statusBarController = nil
    }
} 
