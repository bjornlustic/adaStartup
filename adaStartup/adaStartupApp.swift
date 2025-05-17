//
//  adaStartupApp.swift
//  adaStartup
//
//  Created by Bjorn Lustic on 5/9/25.
//

import SwiftUI

// Define a name for the notification that AppDelegate will post
extension Notification.Name {
    static let openMainWindow = Notification.Name("openMainWindowNotification")
}

@main
struct adaStartupApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // Create instances of the managers
    let soundManager: SoundManager
    let configManager: ConfigurationManager
    let appMonitor: AppMonitor // AppMonitor now depends on configManager

    let mainWindowID = "StartupSoundsMainWindow"

    init() {
        // Initialize managers in correct order of dependency
        let sm = SoundManager()
        let cm = ConfigurationManager() // Create ConfigurationManager
        
        self.soundManager = sm
        self.configManager = cm
        self.appMonitor = AppMonitor(soundManager: sm, configManager: cm) // Pass both to AppMonitor

        // Pass instances to AppDelegate
        appDelegate.soundManager = self.soundManager
        // appDelegate does not directly need appMonitor or configManager if it only sets them up for StatusBarController
        // However, AppMonitor instance is created here and used by the app globally.
        // AppDelegate needs to pass them to its internal components if they need them.
        // For now, assuming AppDelegate will get AppMonitor instance that includes configManager.
        appDelegate.appMonitor = self.appMonitor 
        appDelegate.configManager = self.configManager // Ensure ConfigurationManager is passed to AppDelegate
        appDelegate.mainWindowID = self.mainWindowID
        // No direct need for appDelegate.configManager if appMonitor handles interactions with it.
    }

    var body: some Scene {
        WindowGroup(id: mainWindowID) {
            ContentView() // ContentView will get configManager and soundManager from environment
                .environmentObject(soundManager)
                .environmentObject(configManager) // Pass configManager to the ContentView environment
                .environmentObject(appMonitor)   // Pass appMonitor if ContentView needs to interact with it directly
                .fixedSize()
                .background(AppSetupView(appDelegate: appDelegate))
        }
        .windowResizability(.contentSize)
        // We might want a Settings window later, as per PRD.
        // Settings { SettingsView().environmentObject(configManager) } 
    }
}

// Helper to get the NSWindow instance using NSViewRepresentable
struct WindowAccessor: NSViewRepresentable {
    var appDelegate: AppDelegate

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            // Pass window to AppDelegate once view is in the hierarchy
            self.appDelegate.setMainWindow(view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // Optionally, re-set the window if it changes, though for a single window app this might be less critical.
        // Ensure it's done async to avoid issues during view updates.
        DispatchQueue.main.async {
            if nsView.window != self.appDelegate.mainWindow {
                self.appDelegate.setMainWindow(nsView.window)
            }
        }
    }
}

// Helper View to inject openWindow and the NSWindow into AppDelegate
struct AppSetupView: View {
    @Environment(\.openWindow) var openWindow
    var appDelegate: AppDelegate

    var body: some View {
        // This view's onAppear captures openWindow.
        // It also includes WindowAccessor to capture the NSWindow.
        Color.clear.frame(width: 0, height: 0) // Minimal, non-intrusive view
            .onAppear {
                appDelegate.setOpenWindowAction(openWindow)
            }
            .background(WindowAccessor(appDelegate: appDelegate))
    }
}
