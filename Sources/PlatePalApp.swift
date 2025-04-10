import SwiftUI
import NMapsMap

@main
struct PlatePalApp: App {
    init() {
        // NaverMapService initialization is handled in its own init()
        _ = NaverMapService.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
} 