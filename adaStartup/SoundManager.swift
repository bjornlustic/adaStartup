import Foundation
import AVFoundation
import Combine // For @Published

enum SoundManagementError: Error, LocalizedError {
    case failedToCreateCustomSoundsDirectory(Error?)
    case soundFileTooLong(duration: Double)
    case failedToGetSoundDuration(Error?)
    case failedToCopySoundFile(Error)
    case fileAlreadyExistsInCustomSounds(fileName: String)
    case unsupportedFileType

    var errorDescription: String? {
        switch self {
        case .failedToCreateCustomSoundsDirectory(let err):
            return "Could not create custom sounds directory. \(err?.localizedDescription ?? "")"
        case .soundFileTooLong(let duration):
            return String(format: "Sound is too long (%.2f seconds). Maximum is 3.25 seconds.", duration)
        case .failedToGetSoundDuration(let err):
            return "Could not determine the duration of the sound file. \(err?.localizedDescription ?? "")"
        case .failedToCopySoundFile(let err):
            return "Could not copy sound file to custom sounds directory: \(err.localizedDescription)"
        case .fileAlreadyExistsInCustomSounds(let fileName):
            return "A sound file named '\(fileName)' already exists in custom sounds."
        case .unsupportedFileType:
            return "The selected file type is not supported. Please use WAV, MP3, M4A, or AIFF."
        }
    }
}

@MainActor
class SoundManager: ObservableObject {
    private var players: [String: AVAudioPlayer] = [:] // Keyed by soundFileName
    
    static let noSoundIdentifier = "-- No Sound --" // Identifier for no sound selection
    
    private let maxSoundDuration: Double = 3.25
    
    @Published var availableSoundFilesForPicker: [String] = []
    
    private var customSoundsDirURL: URL? {
        guard let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let bundleID = Bundle.main.bundleIdentifier ?? "StartupSoundsApp" // Fallback bundle ID
        return appSupportURL.appendingPathComponent(bundleID).appendingPathComponent("CustomSounds")
    }
    
    init() {
        print("SoundManager initializing...")
        createCustomSoundsDirectoryIfNeeded()
        refreshAvailableSounds()
    }
    
    private func createCustomSoundsDirectoryIfNeeded() {
        guard let url = customSoundsDirURL else {
            print("Error: Could not get custom sounds directory URL.")
            return
        }
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                print("Custom sounds directory created at: \(url.path)")
            } catch {
                print("Error creating custom sounds directory: \(error)")
                // Optionally propagate this error to UI
            }
        }
    }
    
    func refreshAvailableSounds() {
        var sounds: [String] = [SoundManager.noSoundIdentifier]
        
        // 1. Add bundled sounds (assuming .wav)
        let bundledSoundNames = ["depth", "wooly", "sparse"] // Add your bundled sound names here (without extension)
        sounds.append(contentsOf: bundledSoundNames)
        
        // 2. Add custom sounds from Application Support
        if let customDir = customSoundsDirURL {
            do {
                let fileURLs = try FileManager.default.contentsOfDirectory(at: customDir, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                for fileURL in fileURLs {
                    // Add recognized audio extensions
                    if ["wav", "mp3", "m4a", "aiff"].contains(fileURL.pathExtension.lowercased()) {
                        sounds.append(fileURL.lastPathComponent) // Store with extension
                    }
                }
            } catch {
                print("Error reading custom sounds directory: \(error)")
            }
        }
        var uniqueSounds = Array(Set(sounds))
        uniqueSounds.sort()
        if let noSoundIndex = uniqueSounds.firstIndex(of: SoundManager.noSoundIdentifier) {
            let noSound = uniqueSounds.remove(at: noSoundIndex)
            uniqueSounds.insert(noSound, at: 0)
        } else {
            uniqueSounds.insert(SoundManager.noSoundIdentifier, at: 0)
        }
        availableSoundFilesForPicker = uniqueSounds
        print("Refreshed available sounds: \(availableSoundFilesForPicker)")
    }
    
    func addCustomSound(from sourceURL: URL, completion: @escaping (Result<String, SoundManagementError>) -> Void) {
        guard let customDir = customSoundsDirURL else {
            completion(.failure(.failedToCreateCustomSoundsDirectory(nil)))
            return
        }
        
        let fileName = sourceURL.lastPathComponent
        let destinationURL = customDir.appendingPathComponent(fileName)
        
        // Check for supported file types
        let supportedExtensions = ["wav", "mp3", "m4a", "aiff"]
        guard supportedExtensions.contains(sourceURL.pathExtension.lowercased()) else {
            completion(.failure(.unsupportedFileType))
            return
        }
        
        // Check if file with the same name already exists
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            // For now, reject if exists. Could add option to overwrite or rename.
            completion(.failure(.fileAlreadyExistsInCustomSounds(fileName: fileName)))
            return
        }
        
        // Check duration
        Task { // This Task will now inherit the MainActor context from SoundManager
            // Securely access the source URL
            let didStartAccessing = sourceURL.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing {
                    sourceURL.stopAccessingSecurityScopedResource()
                }
            }

            do {
                let asset = AVURLAsset(url: sourceURL)
                // Load duration using the new async/await API
                let duration = try await asset.load(.duration) 
                let durationInSeconds = CMTimeGetSeconds(duration)

                guard durationInSeconds > 0 else {
                    // No need for DispatchQueue.main.async if already on MainActor
                    completion(.failure(.failedToGetSoundDuration(nil)))
                    return
                }
                print("Selected sound duration: \(durationInSeconds) seconds")
                if durationInSeconds > self.maxSoundDuration {
                    completion(.failure(.soundFileTooLong(duration: durationInSeconds)))
                    return
                }
                
                // No need to re-wrap sourceURL for copyItem if it's still within this scope
                // and startAccessingSecurityScopedResource was successful.
                try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                print("Successfully copied \(fileName) to \(destinationURL.path)")
                
                // These are now guaranteed to be on MainActor
                self.refreshAvailableSounds()
                completion(.success(fileName))
            } catch {
                // Handle errors from asset loading or file copying
                print("Error in addCustomSound Task: \(error)")
                // No need for DispatchQueue.main.async if already on MainActor
                if let soundError = error as? SoundManagementError {
                    completion(.failure(soundError))
                } else {
                    // Generic error for duration loading or other issues
                    completion(.failure(.failedToGetSoundDuration(error)))
                }
            }
        }
    }
    
    private func loadSoundIfNeeded(soundFileName: String) {
        guard !soundFileName.isEmpty, soundFileName != SoundManager.noSoundIdentifier else { return }
        if players[soundFileName] != nil { return } // Already loaded
        
        var soundURL: URL? = nil
        
        // Attempt 1: Check bundled sounds (assuming .wav for bundled, or determine from name)
        // For bundled, we assume no extension was stored in soundFileName if it's one of the defaults
        let bundledSoundNames = ["depth", "wooly", "sparse"] // Ensure "sparse" is included here
        if bundledSoundNames.contains(soundFileName) {
            soundURL = Bundle.main.url(forResource: soundFileName, withExtension: "wav")
        } else { // Attempt 2: Check custom sounds directory (filename includes extension)
            if let customDir = customSoundsDirURL {
                let potentialURL = customDir.appendingPathComponent(soundFileName)
                if FileManager.default.fileExists(atPath: potentialURL.path) {
                    soundURL = potentialURL
                }
            }
        }
        guard let finalSoundURL = soundURL else {
            print("Could not find sound file in bundle or custom directory: \(soundFileName)")
            return
        }
        
        print("Loading sound for \(soundFileName) from: \(finalSoundURL)")
        do {
            let player = try AVAudioPlayer(contentsOf: finalSoundURL)
            player.prepareToPlay()
            players[soundFileName] = player
            print("Successfully loaded sound: \(soundFileName)")
        } catch {
            print("Error loading sound \(soundFileName): \(error)")
        }
    }
    
    func playSound(soundFileName: String, volume: Float = 1.0) {
        guard !soundFileName.isEmpty, soundFileName != SoundManager.noSoundIdentifier else { return }
        loadSoundIfNeeded(soundFileName: soundFileName)
        
        if let player = players[soundFileName] {
            player.volume = volume
            player.stop()
            player.currentTime = 0
            if player.play() {
                print("Sound playback started for: \(soundFileName) at volume: \(volume)")
            } else {
                print("Sound playback failed for: \(soundFileName). Player did not start.")
            }
        } else {
            print("No sound player available for: \(soundFileName). It might have failed to load.")
        }
    }
    
    // Function to delete a custom sound (requires UI integration later)
    func deleteCustomSound(fileName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let customDir = customSoundsDirURL else {
            completion(.failure(SoundManagementError.failedToCreateCustomSoundsDirectory(nil)))
            return
        }
        let fileURL = customDir.appendingPathComponent(fileName)
        do {
            try FileManager.default.removeItem(at: fileURL)
            players[fileName] = nil // Remove from cache if loaded
            refreshAvailableSounds()
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
} 
