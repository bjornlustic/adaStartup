import Foundation
import AVFoundation

class SoundManager: ObservableObject {
    private var players: [String: AVAudioPlayer] = [:]
    private let appSounds: [AppSound] = [
        AppSound(appName: "Cursor", soundFileName: "cursor_startup"),
        AppSound(appName: "Windsurf", soundFileName: "windsurf_startup")
        // Add more apps here by adding new AppSound instances
    ]
    
    init() {
        print("SoundManager initializing...")
        setupSoundPlayers()
    }
    
    private func setupSoundPlayers() {
        for appSound in appSounds {
            if let soundURL = appSound.soundFileURL {
                print("Found sound for \(appSound.appName) at: \(soundURL)")
                do {
                    let player = try AVAudioPlayer(contentsOf: soundURL)
                    player.prepareToPlay()
                    players[appSound.appName] = player
                    print("Successfully loaded sound for \(appSound.appName)")
                } catch {
                    print("Error loading sound for \(appSound.appName): \(error)")
                }
            } else {
                print("Could not find sound file for \(appSound.appName)")
            }
        }
    }
    
    func playSound(for appName: String) {
        print("Attempting to play sound for \(appName)")
        if let player = players[appName] {
            player.currentTime = 0
            player.play()
            print("Sound playback started for \(appName)")
        } else {
            print("No sound player found for \(appName)")
        }
    }
    
    // Helper method to get all configured app names
    var configuredAppNames: [String] {
        appSounds.map { $0.appName }
    }
} 