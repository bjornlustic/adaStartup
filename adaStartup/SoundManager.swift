import Foundation
import AVFoundation

class SoundManager: ObservableObject {
    private var cursorPlayer: AVAudioPlayer?
    private var windsurfPlayer: AVAudioPlayer?
    
    init() {
        print("SoundManager initializing...")
        setupSoundPlayers()
    }
    
    private func setupSoundPlayers() {
        // Get the bundle path
        let bundlePath = Bundle.main.bundlePath
        print("Bundle path: \(bundlePath)")
        
        // Setup Cursor sound
        let cursorSoundPath = bundlePath + "/Contents/Resources/Sounds/cursor_startup.wav"
        print("Looking for Cursor sound at: \(cursorSoundPath)")
        
        if FileManager.default.fileExists(atPath: cursorSoundPath) {
            print("Found Cursor sound file")
            do {
                cursorPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: cursorSoundPath))
                cursorPlayer?.prepareToPlay()
                print("Successfully loaded Cursor sound")
            } catch {
                print("Error loading Cursor sound: \(error)")
            }
        } else {
            print("Could not find cursor_startup.wav at path: \(cursorSoundPath)")
            
            // Try alternative path
            if let cursorSoundURL = Bundle.main.url(forResource: "cursor_startup", withExtension: "wav", subdirectory: "Sounds") {
                print("Found Cursor sound at alternative path: \(cursorSoundURL)")
                do {
                    cursorPlayer = try AVAudioPlayer(contentsOf: cursorSoundURL)
                    cursorPlayer?.prepareToPlay()
                    print("Successfully loaded Cursor sound from alternative path")
                } catch {
                    print("Error loading Cursor sound from alternative path: \(error)")
                }
            }
        }
        
        // Setup Windsurf sound
        let windsurfSoundPath = bundlePath + "/Contents/Resources/Sounds/windsurf_startup.wav"
        print("Looking for Windsurf sound at: \(windsurfSoundPath)")
        
        if FileManager.default.fileExists(atPath: windsurfSoundPath) {
            print("Found Windsurf sound file")
            do {
                windsurfPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: windsurfSoundPath))
                windsurfPlayer?.prepareToPlay()
                print("Successfully loaded Windsurf sound")
            } catch {
                print("Error loading Windsurf sound: \(error)")
            }
        } else {
            print("Could not find windsurf_startup.wav at path: \(windsurfSoundPath)")
            
            // Try alternative path
            if let windsurfSoundURL = Bundle.main.url(forResource: "windsurf_startup", withExtension: "wav", subdirectory: "Sounds") {
                print("Found Windsurf sound at alternative path: \(windsurfSoundURL)")
                do {
                    windsurfPlayer = try AVAudioPlayer(contentsOf: windsurfSoundURL)
                    windsurfPlayer?.prepareToPlay()
                    print("Successfully loaded Windsurf sound from alternative path")
                } catch {
                    print("Error loading Windsurf sound from alternative path: \(error)")
                }
            }
        }
    }
    
    func playCursorSound() {
        print("Attempting to play Cursor sound")
        if let player = cursorPlayer {
            player.currentTime = 0
            player.play()
            print("Cursor sound playback started")
        } else {
            print("Cursor player is nil - sound not loaded")
        }
    }
    
    func playWindsurfSound() {
        print("Attempting to play Windsurf sound")
        if let player = windsurfPlayer {
            player.currentTime = 0
            player.play()
            print("Windsurf sound playback started")
        } else {
            print("Windsurf player is nil - sound not loaded")
        }
    }
} 