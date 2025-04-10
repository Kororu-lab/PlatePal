import SwiftUI
import NMapsMap
import CoreLocation
import UIKit

// MARK: - Price Range (Fallback if import doesn't work)
enum PriceRangeFallback: String, CaseIterable {
    case budget = "Budget"
    case medium = "Medium"
    case premium = "Premium"
}

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
                Label("지도", systemImage: "map")
            }
            
            RestaurantListView(restaurants: recommendationViewModel.restaurants)
                .tabItem {
                    Label("목록", systemImage: "list.bullet")
                }
            
            SettingsView()
                .tabItem {
                    Label("설정", systemImage: "gear")
                }
        }
        .background(Color.white)
        .environmentObject(recommendationViewModel)
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
    var restaurants: [Restaurant]
    @EnvironmentObject var viewModel: RecommendationViewModel
    @State private var selectedRestaurant: Restaurant?
    @State private var showingDetails = false
    
    var body: some View {
        NavigationView {
            List {
                if viewModel.restaurants.isEmpty {
                    Text("식당 정보가 없습니다")
                } else {
                    ForEach(viewModel.restaurants) { restaurant in
                        Button(action: {
                            selectedRestaurant = restaurant
                            showingDetails = true
                        }) {
                            VStack(alignment: .leading) {
                                Text(restaurant.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(restaurant.address)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                HStack {
                                    Text(restaurant.category)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    Spacer()
                                    Text("★ \(String(format: "%.1f", restaurant.rating))")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("식당 목록")
            .sheet(isPresented: $showingDetails) {
                if let restaurant = selectedRestaurant {
                    RestaurantDetailView(restaurant: restaurant)
                }
            }
        }
    }
}

struct RestaurantDetailView: View {
    let restaurant: Restaurant
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(restaurant.name)
                    .font(.largeTitle)
                    .bold()
                
                Text(restaurant.address)
                    .font(.subheadline)
                
                Divider()
                
                HStack {
                    Label("\(restaurant.category)", systemImage: "tag")
                    Spacer()
                    Label("★ \(String(format: "%.1f", restaurant.rating)) (\(restaurant.reviewCount))", systemImage: "star.fill")
                        .foregroundColor(.orange)
                }
                
                if let description = restaurant.description {
                    Divider()
                    Text("설명")
                        .font(.headline)
                    Text(description)
                        .font(.body)
                }
                
                if let operatingHours = restaurant.operatingHours {
                    Divider()
                    Text("영업시간")
                        .font(.headline)
                    Text(operatingHours)
                        .font(.body)
                }
                
                if let phoneNumber = restaurant.phoneNumber {
                    Divider()
                    Text("연락처")
                        .font(.headline)
                    Button(action: {
                        let tel = "tel://\(phoneNumber.replacingOccurrences(of: "-", with: ""))"
                        if let url = URL(string: tel) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Text(phoneNumber)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @AppStorage("priceRange") private var priceRange: PriceRangeFallback = .medium
    @AppStorage("maxDistance") private var maxDistance: Double = 2000
    @AppStorage("showFavorites") private var showFavorites = true
    @AppStorage("showDownvoted") private var showDownvoted = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("환경설정")) {
                    Picker("가격대", selection: $priceRange) {
                        ForEach(PriceRangeFallback.allCases, id: \.self) { range in
                            Text(range.rawValue == "Budget" ? "저렴함" :
                                (range.rawValue == "Medium" ? "보통" : "고급")).tag(range)
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("최대 거리: \(Int(maxDistance))m")
                        Slider(value: $maxDistance, in: 500...5000, step: 100)
                    }
                    
                    Toggle("즐겨찾기 표시", isOn: $showFavorites)
                    Toggle("비추천 표시", isOn: $showDownvoted)
                }
                
                Section(header: Text("내 목록")) {
                    NavigationLink("즐겨찾는 음식점") {
                        FavoriteListView()
                    }
                    
                    NavigationLink("비추천 장소") {
                        DownvotedListView()
                    }
                }
                
                Section(header: Text("추천 시스템 설명"), footer: Text("음식점 추천은 당신의 즐겨찾기와 가격대, 위치 등 선호도를 기반으로 맞춤형으로 제공됩니다. 더 많은 음식점을 즐겨찾기에 추가할수록 더 나은 추천을 받을 수 있습니다.")) {
                    HStack {
                        Text("추천 알고리즘")
                        Spacer()
                        Text("협업 필터링")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("개인화 기준")
                        Spacer()
                        Text("카테고리, 가격대, 거리")
                            .foregroundColor(.gray)
                    }
                }
                
                Section(header: Text("정보")) {
                    HStack {
                        Text("버전")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("설정")
        }
    }
}

// MARK: - Favorite and Downvoted Lists
struct FavoriteListView: View {
    @EnvironmentObject var viewModel: RecommendationViewModel
    
    var body: some View {
        List {
            if viewModel.favoriteRestaurants.isEmpty {
                Text("즐겨찾기에 추가된 음식점이 없습니다")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ForEach(viewModel.favoriteRestaurants) { restaurant in
                    VStack(alignment: .leading) {
                        Text(restaurant.name)
                            .font(.headline)
                        Text(restaurant.address)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        HStack {
                            Text(restaurant.category)
                                .font(.caption)
                                .foregroundColor(.blue)
                            Spacer()
                            Text("★ \(String(format: "%.1f", restaurant.rating))")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let restaurant = viewModel.favoriteRestaurants[index]
                        viewModel.dislikeRestaurant(restaurant)
                    }
                }
            }
        }
        .navigationTitle("즐겨찾기 목록")
    }
}

struct DownvotedListView: View {
    @EnvironmentObject var viewModel: RecommendationViewModel
    
    var body: some View {
        List {
            if viewModel.downvotedRestaurants.isEmpty {
                Text("비추천으로 표시된 음식점이 없습니다")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ForEach(viewModel.downvotedRestaurants) { restaurant in
                    VStack(alignment: .leading) {
                        Text(restaurant.name)
                            .font(.headline)
                        Text(restaurant.address)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        HStack {
                            Text(restaurant.category)
                                .font(.caption)
                                .foregroundColor(.blue)
                            Spacer()
                            Text("★ \(String(format: "%.1f", restaurant.rating))")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        viewModel.downvotedRestaurants.remove(at: index)
                    }
                }
            }
        }
        .navigationTitle("비추천 목록")
    }
}

#Preview {
    ContentView()
} 