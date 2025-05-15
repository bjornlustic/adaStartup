import SwiftUI
import AppKit

struct AppConfig: Identifiable, Codable, Equatable {
    var id = UUID()
    var appName: String
    var bundleIdentifier: String
    var appPath: String // Store as String, convert to URL when needed
    var soundFileName: String
    var isActivated: Bool = true // Default to true, sound is active
    var volume: Float = 1.0 // Default volume is 100%

    enum CodingKeys: String, CodingKey {
        case id
        case appName
        case bundleIdentifier
        case appPath
        case soundFileName
        case isActivated // Make sure to include new properties for persistence
        case volume // Add volume to coding keys
    }

    // Computed property for the icon, not saved directly in JSON
    var icon: NSImage? {
        // Attempt 1: Use appPath with NSWorkspace if appPath is valid and exists
        if !appPath.isEmpty && FileManager.default.fileExists(atPath: appPath) {
            let image = NSWorkspace.shared.icon(forFile: appPath)
            // NSImage.isValid is not a standard property. A simple check is if size > 0.
            // NSWorkspace.shared.icon(forFile:) for an app should return its actual icon.
            if image.size.width > 0 && image.size.height > 0 {
                return image
            }
        }

        // Attempt 2: Use bundleIdentifier to find app path, then NSWorkspace
        // This is useful if appPath was incorrect, or app moved but is findable by bundleID.
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            if FileManager.default.fileExists(atPath: appURL.path) {
                let image = NSWorkspace.shared.icon(forFile: appURL.path)
                if image.size.width > 0 && image.size.height > 0 {
                    return image
                }
            }
        }
        
        // Final Fallback: Generic application icon
        // This might be returned by NSWorkspace calls too if it can't find a specific icon 
        // but finds the app (it might return a generic document icon for a non-app file).
        // Explicitly returning the system generic app icon here is a clear fallback.
        return NSImage(named: NSImage.applicationIconName)
    }
    
    // Sound file URL (assuming .wav and in main bundle for now)
    var soundFileURL: URL? {
        Bundle.main.url(forResource: soundFileName, withExtension: "wav")
    }

    // Equatable conformance
    static func == (lhs: AppConfig, rhs: AppConfig) -> Bool {
        return lhs.id == rhs.id && // IDs should be unique, but good to include for structural equality if needed
               lhs.appName == rhs.appName &&
               lhs.bundleIdentifier == rhs.bundleIdentifier &&
               lhs.appPath == rhs.appPath &&
               lhs.soundFileName == rhs.soundFileName &&
               lhs.isActivated == rhs.isActivated &&
               lhs.volume == rhs.volume
    }
} 