//
//  ContentView.swift
//  adaStartup
//
//  Created by Bjorn Lustic on 5/9/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var soundManager: SoundManager
    @EnvironmentObject var appMonitor: AppMonitor
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(.cyan)
                Text("Startup Sounds")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 10, height: 10)
                        .shadow(color: .green.opacity(0.5), radius: 3, x: 0, y: 0)
                    Text("ACTIVE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(Color.black.opacity(0.3))

            Text("MONITORED APPLICATIONS")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.gray.opacity(0.8))
                .padding(.top, 20)
                .padding(.bottom, 10)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if soundManager.configuredAppNames.isEmpty {
                        Text("No applications configured yet.")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 30)
                    } else {
                        ForEach(soundManager.configuredAppNames, id: \.self) { appName in
                            AppListItem(appName: appName)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }

            Spacer(minLength: 0)

            Text("Sounds will play upon application launch.")
                .font(.system(size: 10, design: .rounded))
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.bottom, 15)
        }
        .padding()
        .frame(width: 280, height: 360)
        .background(
            LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.85), Color.black.opacity(0.95)]), startPoint: .top, endPoint: .bottom)
        )
        .cornerRadius(10)
    }
}

struct AppListItem: View {
    let appName: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "app.dashed")
                .font(.system(size: 22, weight: .regular))
                .foregroundColor(.cyan.opacity(0.8))
                .frame(width: 30, height: 30)
                .background(Color.white.opacity(0.05))
                .cornerRadius(6)

            Text(appName)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
            Spacer()
            Image(systemName: "speaker.wave.2.fill")
                 .foregroundColor(.green.opacity(0.7))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(0.08))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
    }
}

class MockSoundManager: SoundManager {
    var localAppSounds: [AppSound] // Renamed from configuredAppSounds and made a property

    override init() {
        // Initialize with the specific sounds mentioned in the error log, fixing AppSound calls
        self.localAppSounds = [
            AppSound(appName: "Cursor", soundFileName: "sound1.mp3"),
            AppSound(appName: "Windsurf", soundFileName: "sound2.m4a")
        ]
        super.init()
    }

    // Override configuredAppNames to use the localAppSounds for the mock
    override var configuredAppNames: [String] {
        return localAppSounds.map { $0.appName }
    }
    
    // If SoundManager's playSound needs to be overridden to use localAppSounds,
    // or if players need to be set up from localAppSounds, that would be an additional step.
    // For now, this addresses the member error and AppSound init errors.
}

#Preview {
    // Ensure the preview uses the MockSoundManager
    let mockSoundManager = MockSoundManager() 
    let mockAppMonitor = AppMonitor(soundManager: mockSoundManager)

    return ContentView()
        .environmentObject(mockSoundManager as SoundManager) // Use 'as SoundManager' if ContentView expects SoundManager type
        .environmentObject(mockAppMonitor)
}
