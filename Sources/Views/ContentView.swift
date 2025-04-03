import SwiftUI

struct ContentView: View {
    let locationManager: LocationManager
    
    var body: some View {
        TabView {
            RecommendationView(locationManager: locationManager)
                .tabItem {
                    Label("추천", systemImage: "fork.knife")
                }
            
            Text("내역")
                .tabItem {
                    Label("내역", systemImage: "clock")
                }
            
            Text("설정")
                .tabItem {
                    Label("설정", systemImage: "gear")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(locationManager: LocationManager())
    }
} 