import SwiftUI
import NMapsMap

@main
struct PlatePalApp: App {
    init() {
        // Initialize Naver Maps
        NaverMapService.shared.setupNaverMap()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
} 