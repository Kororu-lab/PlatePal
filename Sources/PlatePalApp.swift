import SwiftUI

@main
struct PlatePalApp: App {
    @StateObject private var locationManager = LocationManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView(locationManager: locationManager)
        }
    }
} 