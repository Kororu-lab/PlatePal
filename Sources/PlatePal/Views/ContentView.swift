import SwiftUI
import NMapsMap
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        NavigationView {
            RecommendationView(locationManager: locationManager)
                .navigationBarTitle("PlatePal", displayMode: .large)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 
