import SwiftUI
import Combine

struct SettingsView: View {
    @ObservedObject var viewModel: RecommendationViewModel
    @AppStorage("priceRange") private var priceRange: String = "Medium"
    @AppStorage("maxDistance") private var maxDistance: Double = 2000
    @AppStorage("showFavorites") private var showFavorites = true
    @AppStorage("showDownvoted") private var showDownvoted = false
    @AppStorage("preferredCategories") private var preferredCategories = ""
    @AppStorage("enableDualDinerSystem") private var enableDualDinerSystem = true
    @AppStorage("automaticSelectionEnabled") private var automaticSelectionEnabled = true
    @State private var showingDebugView = false
    
    var body: some View {
        Form {
            Section(header: Text("추천 설정")) {
                Toggle("듀얼 다이너 시스템 사용", isOn: $enableDualDinerSystem)
                    .tint(Color("AccentColor"))
                
                Toggle("자동 선택 활성화", isOn: $automaticSelectionEnabled)
                    .tint(Color("AccentColor"))
                    .disabled(!enableDualDinerSystem)
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("기본 랜덤성")
                        Spacer()
                        Text("\(Int(viewModel.randomnessFactor * 100))%")
                            .foregroundColor(.gray)
                    }
                    
                    Slider(
                        value: Binding(
                            get: { viewModel.randomnessFactor },
                            set: { viewModel.setRandomnessFactor($0) }
                        ),
                        in: 0...1,
                        step: 0.01
                    )
                    .tint(Color("AccentColor"))
                }
            }
            
            Section(header: Text("필터 설정")) {
                Picker("가격대", selection: $priceRange) {
                    Text("저렴함").tag("Budget")
                    Text("보통").tag("Medium")
                    Text("고급").tag("Premium")
                }
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("최대 거리")
                        Spacer()
                        Text("\(Int(maxDistance))m")
                            .foregroundColor(.gray)
                    }
                    
                    Slider(value: $maxDistance, in: 300...3000, step: 100)
                        .tint(Color("AccentColor"))
                }
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("랜덤 레벨")
                        Spacer()
                        Text("\(Int(viewModel.randomnessFactor * 100))%")
                            .foregroundColor(.gray)
                    }
                    
                    Slider(
                        value: Binding(
                            get: { viewModel.randomnessFactor },
                            set: { viewModel.setRandomnessFactor($0) }
                        ),
                        in: 0...1,
                        step: 0.05
                    )
                    .tint(Color("AccentColor"))
                }
                .padding(.vertical, 8)
                
                NavigationLink(destination: CategoryPreferencesView()) {
                    Text("선호 카테고리 설정")
                }
                
                Toggle("즐겨찾기 표시", isOn: $showFavorites)
                    .tint(Color("AccentColor"))
                
                Toggle("비추천 표시", isOn: $showDownvoted)
                    .tint(Color("AccentColor"))
            }
            
            Section(header: Text("내 목록")) {
                NavigationLink(destination: FavoriteListView()) {
                    Text("즐겨찾는 음식점")
                }
                
                NavigationLink(destination: DownvotedListView()) {
                    Text("비추천 장소")
                }
            }
            
            Section(header: Text("개발자 설정")) {
                Toggle("디버그 모드", isOn: Binding(
                    get: { viewModel.isDebugMode },
                    set: { viewModel.isDebugMode = $0 }
                ))
                .tint(Color("AccentColor"))
                
                if viewModel.isDebugMode {
                    Button(action: {
                        showingDebugView = true
                    }) {
                        Text("추천 시스템 디버거 열기")
                    }
                    .foregroundColor(Color("AccentColor"))
                }
            }
            
            Section(header: Text("추천 시스템 정보"), footer: Text("듀얼 다이너 시스템은 두 개의 음식점을 동시에 추천하고, 사용자의 선택이 향후 추천에 영향을 미칩니다. 랜덤성 값이 높을수록 더 다양한 음식점이 추천될 수 있습니다.")) {
                HStack {
                    Text("추천 알고리즘")
                    Spacer()
                    Text("사용자 맞춤형 필터링")
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text("개인화 기준")
                    Spacer()
                    Text("카테고리, 가격대, 거리, 선호도")
                        .foregroundColor(.gray)
                }
            }
            
            Section(header: Text("정보")) {
                HStack {
                    Text("버전")
                    Spacer()
                    Text("1.1.0")
                        .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle("설정")
        .sheet(isPresented: $showingDebugView) {
            // Convert viewModel data into format needed by DebugView
            let debugData = viewModel.dinerRecommendations.map { restaurant in
                RestaurantScore(
                    id: restaurant.id,
                    name: restaurant.name,
                    category: restaurant.category,
                    distance: restaurant.distance,
                    score: viewModel.getRestaurantScore(restaurant),
                    componentScores: ComponentScores(
                        distance: viewModel.getDistanceScore(restaurant),
                        price: viewModel.getPriceScore(restaurant),
                        category: viewModel.getCategorySimilarity(restaurant),
                        favorite: viewModel.getFavoriteScore(restaurant),
                        random: viewModel.getRandomnessScore()
                    )
                )
            }
            
            DebugView(isPresented: $showingDebugView, recommendationData: debugData)
        }
    }
}

struct CategoryPreferencesView: View {
    @AppStorage("preferredCategories") private var preferredCategories = ""
    @State private var selectedCategories: Set<String> = []
    
    let availableCategories = [
        "한식", "중식", "일식", "양식", "분식", 
        "카페", "디저트", "패스트푸드", "치킨", "피자",
        "고기", "해산물", "베이커리", "샐러드", "술집"
    ]
    
    var body: some View {
        List {
            ForEach(availableCategories, id: \.self) { category in
                Button(action: {
                    toggleCategory(category)
                }) {
                    HStack {
                        Text(category)
                        Spacer()
                        if selectedCategories.contains(category) {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color("AccentColor"))
                        }
                    }
                }
                .foregroundColor(.primary)
            }
        }
        .navigationTitle("선호 카테고리")
        .onAppear {
            // Load saved categories
            let savedCategories = preferredCategories.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
            selectedCategories = Set(savedCategories)
        }
    }
    
    private func toggleCategory(_ category: String) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
        
        // Save to UserDefaults
        preferredCategories = selectedCategories.joined(separator: ", ")
    }
}

struct FavoriteListView: View {
    // This would be connected to a real data source in the full app
    var body: some View {
        List {
            Text("즐겨찾기 목록이 여기에 표시됩니다.")
                .foregroundColor(.gray)
        }
        .navigationTitle("즐겨찾는 음식점")
    }
}

struct DownvotedListView: View {
    // This would be connected to a real data source in the full app
    var body: some View {
        List {
            Text("비추천 목록이 여기에 표시됩니다.")
                .foregroundColor(.gray)
        }
        .navigationTitle("비추천 장소")
    }
} 