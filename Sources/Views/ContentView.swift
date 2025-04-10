import SwiftUI
import NMapsMap
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var recommendationViewModel: RecommendationViewModel
    
    init() {
        let locationManager = LocationManager()
        _locationManager = StateObject(wrappedValue: locationManager)
        _recommendationViewModel = StateObject(wrappedValue: RecommendationViewModel(locationManager: locationManager))
    }
    
    var body: some View {
        TabView {
            RecommendationView(
                viewModel: recommendationViewModel,
                locationManager: locationManager
            )
            .tabItem {
                Label("Map", systemImage: "map")
            }
            
            RestaurantListView()
                .tabItem {
                    Label("List", systemImage: "list.bullet")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .background(Color.white)
        .onAppear {
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithOpaqueBackground()
            tabBarAppearance.backgroundColor = .white
            
            let separator = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
            separator.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 1)
            separator.backgroundColor = .gray
            
            UITabBar.appearance().standardAppearance = tabBarAppearance
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
}

// MARK: - Supporting Views
struct RestaurantListView: View {
    var body: some View {
        NavigationView {
            List {
                Text("음식점 목록")
            }
            .navigationTitle("식당 목록")
        }
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("계정")) {
                    Text("프로필 정보")
                    Text("로그아웃")
                }
                
                Section(header: Text("앱 설정")) {
                    Text("알림 설정")
                    Text("언어 설정")
                }
                
                Section(header: Text("정보")) {
                    Text("버전 1.0.0")
                    Text("개인정보 처리방침")
                }
            }
            .navigationTitle("설정")
        }
    }
}

#Preview {
    ContentView()
} 