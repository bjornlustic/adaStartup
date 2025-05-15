import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    // Hold references to shared instances
    var soundManager: SoundManager?
    var appMonitor: AppMonitor?
    
    var mainWindowID: String?
    private var openWindowAction: SwiftUI.OpenWindowAction?
    weak var mainWindow: NSWindow? // Weak reference to the main window

    // Method for OpenWindowInjector to call
    func setOpenWindowAction(_ action: SwiftUI.OpenWindowAction) {
        self.openWindowAction = action
    }
    
    // Method for ContentView (via helper) to report its window
    func setMainWindow(_ window: NSWindow?) {
        self.mainWindow = window
        if let window = window {
            // Define the desired fixed size
            let fixedWidth: CGFloat = 800
            let fixedHeight: CGFloat = 500

            // Ensure the window is titled and closable, but not resizable, miniaturizable, or fullScreen.
            window.styleMask = [.titled, .closable]
            
            // Set the window's content min and max size to the fixed size
            window.contentMinSize = NSSize(width: fixedWidth, height: fixedHeight)
            window.contentMaxSize = NSSize(width: fixedWidth, height: fixedHeight)
            
            // Explicitly set the window's content size to the fixed size
            // This can be important to ensure the window adopts the size immediately
            window.setContentSize(NSSize(width: fixedWidth, height: fixedHeight))
            
            // Optionally, center the window after setting its size
            // window.center()
            
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        // Ensure shared instances (set by adaStartupApp) are available.
        // AppMonitor instance received here is already configured with its dependencies.
        guard self.soundManager != nil, self.appMonitor != nil else {
            fatalError("SoundManager and/or AppMonitor not initialized in AppDelegate by adaStartupApp")
        }
        
        statusBarController = StatusBarController {
            [weak self] in 
            guard let self = self else { return }

            if let window = self.mainWindow {
                // A window instance exists
                if window.isMiniaturized {
                    window.deminiaturize(nil) // Unminimize if needed
                }
                // Whether it was minimized or just not front, bring it to front and activate app
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            } else {
                // No window instance exists (it was closed or never opened).
                // Open a new one.
                guard let action = self.openWindowAction, let windowID = self.mainWindowID else {
                    print("Error: openWindowAction or mainWindowID not set in AppDelegate for new window creation")
                    return
                }
                action(id: windowID) // This will trigger ContentView to appear, and WindowAccessor will call setMainWindow
            }
        }
        
        print("AppDelegate finished launching. StartupSounds is active.")
    }
    
    func applicationWillResignActive(_ notification: Notification) {
        // This was for closing the popover, which is no longer used.
        // statusBarController?.closePopover()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clean up when app is terminating
        statusBarController = nil
        print("StartupSounds is terminating.")
    }
}
