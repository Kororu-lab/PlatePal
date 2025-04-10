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
    // Create shared instances to be used throughout the app
    let locationManager = LocationManager()
    
    @StateObject private var viewModel: RecommendationViewModel
    
    init() {
        // Initialize NMFAuthManager
        _ = NMFAuthManager.shared()
        
        // Load debug mode from UserDefaults if exists
        let isDebugMode = UserDefaults.standard.bool(forKey: "isDebugMode")
        
        // Initialize viewModel with loaded values
        let vm = RecommendationViewModel(locationManager: locationManager)
        vm.isDebugMode = isDebugMode
        
        // Create StateObject
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .onDisappear {
                    // Save debug mode when app closes
                    UserDefaults.standard.set(viewModel.isDebugMode, forKey: "isDebugMode")
                }
        }
    }
} 