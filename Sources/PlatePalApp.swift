import SwiftUI
import NMapsMap

//
// PlatePal - Korean Restaurant Recommendation App
//
// IMPORTANT SETUP NOTES:
// 1. Make sure to open the PlatePal.xcworkspace file, not the .xcodeproj file
// 2. The app requires CocoaPods for NMapsMap and other dependencies
// 3. If you encounter build errors, try running `pod install` in the project directory
// 4. The recommendation engine functionality is now integrated directly in RecommendationViewModel
//

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