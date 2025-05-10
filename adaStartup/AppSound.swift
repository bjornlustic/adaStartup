import Foundation

struct AppSound: Identifiable {
    let id = UUID()
    let appName: String
    let soundFileName: String
    
    var soundFileURL: URL? {
        Bundle.main.url(forResource: soundFileName, withExtension: "wav")
    }
} 