import SwiftUI
import MapKit
import NMapsMap
import NMapsGeometry
import CoreLocation

// MARK: - Define the missing types first
// Local color extension to replace imported Extensions module
extension Color {
    static let platepalAccent = Color(red: 0, green: 0.478, blue: 1.0)
    static let platepalBackground = Color.white
    static let platepalCard = Color(white: 0.97)
}

struct RestaurantScore: Identifiable {
    let id: String
    let name: String
    let category: String
    let distance: Double
    let score: Double
    let componentScores: ComponentScores
}

struct ComponentScores {
    let distance: Double
    let price: Double
    let category: Double
    let favorite: Double
    let random: Double
}

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text("Searching for restaurants...")
                .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct DebugView: View {
    @Binding var isPresented: Bool
    let recommendationData: [RestaurantScore]
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(recommendationData) { restaurant in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(restaurant.name)
                                    .font(.headline)
                                Spacer()
                                Text(String(format: "%.2f", restaurant.score))
                                    .font(.headline)
                            }
                            
                            HStack {
                                Text(restaurant.category)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("\(Int(restaurant.distance))m")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Debug Info")
            .navigationBarItems(trailing: Button("Close") {
                isPresented = false
            })
        }
    }
}

struct ScoreBarView: View {
    let scores: ComponentScores
    
    var body: some View {
        HStack(spacing: 2) {
            ScoreSegmentView(value: scores.distance, label: "D", color: .blue)
            ScoreSegmentView(value: scores.price, label: "P", color: .green)
            ScoreSegmentView(value: scores.category, label: "C", color: .orange)
            ScoreSegmentView(value: scores.favorite, label: "F", color: .red)
            ScoreSegmentView(value: scores.random, label: "R", color: .purple)
        }
        .frame(height: 20)
    }
}

struct ScoreSegmentView: View {
    let value: Double
    let label: String
    let color: Color
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(color.opacity(0.7))
                .frame(width: CGFloat(value * 50))
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - The main view
struct RecommendationView: View {
    @ObservedObject var viewModel: RecommendationViewModel
    @State private var showingSettings = false
    @State private var showingRestaurantDetail = false
    @State private var showingMap = false
    @State private var showingDebugView = false
    @State private var isDownvoteAnimating = false
    @ObservedObject var locationManager: LocationManager
    
    // Local wrapper for Settings
    private struct LocalSettingsView: View {
        @ObservedObject var viewModel: RecommendationViewModel
        @State private var showingSelectionHistory = false
        @State private var localDebugMode: Bool = false
        @Environment(\.dismiss) var dismiss
        
        var body: some View {
            NavigationView {
                Form {
                    Section(header: Text("추천 설정")) {
                        Toggle("듀얼 다이너 시스템 사용", isOn: .constant(true))
                            .tint(Color.blue)
                        
                        Toggle("자동 선택 활성화", isOn: .constant(true))
                            .tint(Color.blue)
                        
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
                            .tint(Color.blue)
                        }
                        .padding(.vertical, 8)
                        
                        Toggle("디버그 모드", isOn: $localDebugMode)
                            .tint(Color.blue)
                            .onChange(of: localDebugMode) { newValue in
                                viewModel.isDebugMode = newValue
                                print("Debug mode toggled to: \(newValue)")
                                
                                // Force a UI update with several notifications
                                DispatchQueue.main.async {
                                    // Notify all interested views
                                    NotificationCenter.default.post(name: .debugModeChanged, object: nil)
                                    viewModel.objectWillChange.send()
                                    
                                    // Send additional notifications after a delay for components that might miss the first one
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        NotificationCenter.default.post(name: .debugModeChanged, object: nil)
                                        viewModel.objectWillChange.send()
                                    }
                                    
                                    // Final refresh
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        viewModel.objectWillChange.send()
                                    }
                                }
                            }
                            .onAppear {
                                localDebugMode = viewModel.isDebugMode
                                print("Settings view appeared, debug mode: \(localDebugMode)")
                                
                                // Ensure UI is refreshed when view appears
                                DispatchQueue.main.async {
                                    NotificationCenter.default.post(name: .debugModeChanged, object: nil)
                                }
                            }
                    }
                    
                    Section(header: Text("내 목록")) {
                        NavigationLink("즐겨찾는 음식점") {
                            FavoriteListView(viewModel: viewModel)
                        }
                        
                        NavigationLink("싫어하는 음식점") {
                            DownvotedListView(viewModel: viewModel)
                        }
                        
                        // Add selection history directly under "내 목록"
                        if viewModel.selectionHistory.count > 0 {
                            NavigationLink("선택 기록") {
                                SelectionHistoryView(viewModel: viewModel)
                            }
                            .foregroundColor(localDebugMode ? .blue : .primary)
                        }
                    }
                    
                    if localDebugMode {
                        Section(header: Text("디버그 메뉴")) {
                            Text("Debug Mode: ON")
                                .foregroundColor(.red)
                                .bold()
                            
                            Text("Selection History Count: \(viewModel.selectionHistory.count)")
                                .foregroundColor(.blue)
                            
                            Button("강제 UI 새로고침") {
                                // Multiple notifications for thorough refresh
                                NotificationCenter.default.post(name: .debugModeChanged, object: nil)
                                viewModel.objectWillChange.send()
                                
                                // Send a refresh notification for debug visuals as well
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    NotificationCenter.default.post(name: .refreshSelectionStatus, object: nil)
                                    NotificationCenter.default.post(name: .refreshDownvotedStatus, object: nil)
                                    NotificationCenter.default.post(name: .refreshFavoritedStatus, object: nil)
                                }
                            }
                            .foregroundColor(.red)
                            .font(.headline)
                        }
                    }
                }
                .navigationTitle("설정")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("완료") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
    
    // New view to show selection history
    private struct SelectionHistoryView: View {
        @ObservedObject var viewModel: RecommendationViewModel
        
        var body: some View {
            List {
                ForEach(viewModel.selectionHistory.indices.reversed(), id: \.self) { index in
                    let record = viewModel.selectionHistory[index]
                    VStack(alignment: .leading, spacing: 10) {
                        // "A over B" format as requested
                        Text("\(record.selectedRestaurant.name) \(Image(systemName: "arrow.up")) ")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.green) +
                        Text("선택됨")
                            .font(.subheadline)
                        
                        Text("\(record.rejectedRestaurant.name) \(Image(systemName: "arrow.down")) ")
                            .font(.headline)
                            .foregroundColor(.red) +
                        Text("거부됨")
                            .font(.subheadline)
                        
                        // Add more context about the selections
                        HStack(spacing: 20) {
                            VStack(alignment: .leading) {
                                Text("선택")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text(record.selectedRestaurant.category)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green.opacity(0.8))
                            }
                            
                            VStack(alignment: .leading) {
                                Text("거부")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text(record.rejectedRestaurant.category)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.red.opacity(0.8))
                            }
                        }
                        
                        // Time of selection
                        Text("선택 시간: \(record.date, formatter: dateFormatter)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    .padding(.vertical, 4)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("선택 기록")
            .navigationBarTitleDisplayMode(.inline)
            .overlay(
                Group {
                    if viewModel.selectionHistory.isEmpty {
                        VStack {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text("선택 기록이 없습니다.")
                                .foregroundColor(.gray)
                        }
                    }
                }
            )
        }
        
        private var dateFormatter: DateFormatter {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.white.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 12) {
                // Diners area
                HStack(spacing: 4) {
                    // First diner
                    if !viewModel.dinerRecommendations.isEmpty {
                        DinerCard(
                            viewModel: viewModel,
                            restaurant: viewModel.dinerRecommendations[0],
                            onToggleSelection: {
                                if !viewModel.dinerRecommendations.isEmpty {
                                    viewModel.toggleSelection(at: 0)
                                }
                            },
                            onUpvote: {
                                if !viewModel.dinerRecommendations.isEmpty {
                                    viewModel.favoriteRestaurant(viewModel.dinerRecommendations[0])
                                }
                            },
                            onDownvote: {
                                if !viewModel.dinerRecommendations.isEmpty {
                                    viewModel.downvoteRestaurant(viewModel.dinerRecommendations[0])
                                }
                            },
                            score: viewModel.dinerRecommendations.isEmpty ? nil : viewModel.getRestaurantScore(viewModel.dinerRecommendations[0]),
                            categorySimilarity: viewModel.dinerRecommendations.isEmpty ? nil : viewModel.getCategorySimilarity(viewModel.dinerRecommendations[0])
                        )
                        .environmentObject(viewModel)
                    } else {
                        EmptyDinerCard()
                    }
                    
                    // Second diner
                    if viewModel.dinerRecommendations.count > 1 {
                        DinerCard(
                            viewModel: viewModel,
                            restaurant: viewModel.dinerRecommendations[1],
                            onToggleSelection: {
                                if viewModel.dinerRecommendations.count > 1 {
                                    viewModel.toggleSelection(at: 1)
                                }
                            },
                            onUpvote: {
                                if viewModel.dinerRecommendations.count > 1 {
                                    viewModel.favoriteRestaurant(viewModel.dinerRecommendations[1])
                                }
                            },
                            onDownvote: {
                                if viewModel.dinerRecommendations.count > 1 {
                                    viewModel.downvoteRestaurant(viewModel.dinerRecommendations[1])
                                }
                            },
                            score: viewModel.dinerRecommendations.count > 1 ? viewModel.getRestaurantScore(viewModel.dinerRecommendations[1]) : nil,
                            categorySimilarity: viewModel.dinerRecommendations.count > 1 ? viewModel.getCategorySimilarity(viewModel.dinerRecommendations[1]) : nil
                        )
                        .environmentObject(viewModel)
                    } else {
                        EmptyDinerCard()
                    }
                }
                .padding(.horizontal, 6)
                .padding(.top)
                
                // Action buttons 
                HStack(spacing: 16) {
                    // Refresh recommendations button
                    Button(action: {
                        viewModel.recommendDiners()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("새로운 추천")
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(Color.platepalAccent)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                        .shadow(radius: 3)
                    }
                    
                    // Debug buttons or location button
                    if viewModel.isDebugMode {
                        VStack(spacing: 10) {
                            // Debug auto-select button
                            Button(action: {
                                viewModel.autoSelectRestaurant()
                            }) {
                                HStack {
                                    Image(systemName: "wand.and.stars")
                                    Text("자동 선택")
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 16)
                                .background(Color.purple.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(20)
                                .shadow(radius: 2)
                            }
                        }
                    } else {
                        // Current location button (if not in debug mode)
                        Button(action: {
                            withAnimation(.easeInOut) {
                                locationManager.requestLocation()
                            }
                        }) {
                            HStack {
                                Image(systemName: "location.fill")
                                Text("현재 위치")
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(Color.gray.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(25)
                            .shadow(radius: 3)
                        }
                    }
                }
                .padding(.vertical)
                
                // Map view
                MapViewContainer(viewModel: viewModel, locationManager: locationManager, parent: self)
                    .frame(height: 250)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .shadow(radius: 3)
                
                Spacer()
            }
            .padding(.top)
            
            // Loading indicator
            if viewModel.isLoading {
                LoadingView()
            }
            
            // Downvote animation
            if isDownvoteAnimating {
                Image(systemName: "hand.thumbsdown.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.red.opacity(0.8))
                    .transition(.scale.combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            withAnimation {
                                isDownvoteAnimating = false
                            }
                        }
                    }
            }
        }
        .navigationBarItems(
            trailing: Button(action: {
                showingSettings = true
            }) {
                Image(systemName: "slider.horizontal.3")
                    .imageScale(.large)
                    .foregroundColor(Color.platepalAccent)
            }
        )
        .onAppear {
            viewModel.fetchRestaurants()
            viewModel.recommendDiners()
            
            // Listen for downvote animation notification
            NotificationCenter.default.addObserver(forName: NSNotification.Name("DownvoteAnimation"), object: nil, queue: .main) { _ in
                withAnimation(.spring()) {
                    isDownvoteAnimating = true
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            if #available(iOS 16.0, *) {
                NavigationStack {
                    LocalSettingsView(viewModel: viewModel)
                }
            } else {
                NavigationView {
                    LocalSettingsView(viewModel: viewModel)
                }
            }
        }
        .sheet(isPresented: $showingDebugView) {
            // Convert viewModel data into format needed by DebugView
            let debugData = viewModel.dinerRecommendations.isEmpty ? [] : viewModel.dinerRecommendations.map { restaurant in
                return RestaurantScore(
                    id: UUID().uuidString,
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

// MARK: - Remaining Views 
struct DinerCard: View {
    @ObservedObject var viewModel: RecommendationViewModel
    var restaurant: Restaurant
    var onToggleSelection: () -> Void
    var onUpvote: () -> Void
    var onDownvote: () -> Void
    @State private var forceUpdate: Bool = false
    @State private var localDebugMode: Bool = false
    var score: Double?
    var categorySimilarity: Double?
    
    var isFavorited: Bool {
        viewModel.isFavorited(restaurant)
    }
    
    var isDownvoted: Bool {
        viewModel.isDownvoted(restaurant)
    }
    
    var isSelected: Bool {
        // Safely find the index of the current restaurant in dinerRecommendations
        if let index = viewModel.dinerRecommendations.firstIndex(where: { $0.id == restaurant.id }) {
            return viewModel.isSelected(at: index)
        }
        return false
    }
    
    var body: some View {
        VStack(spacing: 6) {
            // Restaurant image
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: restaurant.imageURL != nil ? URL(string: restaurant.imageURL!) : nil) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if phase.error != nil {
                        Image(systemName: "photo")
                            .imageScale(.large)
                            .foregroundColor(.gray)
                    } else {
                        ProgressView()
                    }
                }
                .frame(height: 100)
                .clipped()
                .cornerRadius(8)
                
                // Selection indicator (always visible)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .green : .gray.opacity(0.7))
                    .padding(4)
                    .background(Color.white.opacity(0.7))
                    .clipShape(Circle())
                    .padding(6)
            }
            
            // Restaurant info
            VStack(alignment: .leading, spacing: 2) {
                Text(restaurant.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(restaurant.categories.joined(separator: ", "))
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                HStack {
                    Text(restaurant.priceRange.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Text("\(Int(restaurant.distance))m")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Debug information - more explicitly check debug mode status
                if viewModel.isDebugMode == true || localDebugMode == true {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Score: \(String(format: "%.2f", score ?? 0))")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Category Match: \(String(format: "%.2f", categorySimilarity ?? 0))")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.black, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    .padding(.top, 2)
                    .padding(.bottom, 2)
                }
            }
            .padding(.horizontal, 4)
            
            // Action buttons - redesign to follow Cursor guidelines
            HStack(spacing: 8) {
                // Like button
                Button(action: {
                    onUpvote()
                }) {
                    VStack(spacing: 2) {
                        Image(systemName: isFavorited ? "heart.fill" : "heart")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundColor(isFavorited ? .red : .gray)
                            .animation(.spring(), value: isFavorited)
                        Text("Like")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(isFavorited ? .red : .gray)
                    }
                    .frame(width: 46, height: 40)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isFavorited ? Color.red.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
                .id("favorite-\(restaurant.id)-\(isFavorited)")
                
                // Select button
                Button(action: onToggleSelection) {
                    VStack(spacing: 2) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "checkmark.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundColor(isSelected ? .green : .gray)
                            .animation(.spring(), value: isSelected)
                        Text("Select")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(isSelected ? .green : .gray)
                    }
                    .frame(width: 46, height: 40)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.green.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
                .id("select-\(restaurant.id)-\(isSelected)-\(forceUpdate)")
                
                // Dislike button
                Button(action: {
                    onDownvote()
                }) {
                    VStack(spacing: 2) {
                        Image(systemName: isDownvoted ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundColor(isDownvoted ? .blue : .gray)
                            .animation(.spring(), value: isDownvoted)
                        Text("Dislike")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(isDownvoted ? .blue : .gray)
                    }
                    .frame(width: 46, height: 40)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isDownvoted ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
                .id("downvote-\(restaurant.id)-\(isDownvoted)")
            }
            .padding(.vertical, 4)
        }
        .id("DinerCard-\(restaurant.id)-\(forceUpdate)-\(isFavorited)-\(isDownvoted)-\(isSelected)-\(localDebugMode)")
        .padding(6)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
        .frame(maxWidth: .infinity)
        .overlay(
            // Additional safety check to ensure debug info is visible
            ZStack {
                if viewModel.isDebugMode || localDebugMode {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text("DEBUG: \(String(format: "%.2f", score ?? 0))")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.red)
                                .cornerRadius(4)
                                .padding(6)
                        }
                    }
                }
            }
        )
        .onReceive(NotificationCenter.default.publisher(for: .refreshDownvotedStatus)) { _ in
            forceUpdate.toggle()
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshFavoritedStatus)) { _ in
            forceUpdate.toggle()
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshSelectionStatus)) { _ in
            forceUpdate.toggle()
        }
        .onReceive(NotificationCenter.default.publisher(for: .debugModeChanged)) { _ in
            // Explicitly set the local debug mode from the view model
            self.localDebugMode = viewModel.isDebugMode
            print("Debug notification received in DinerCard: viewModel.isDebugMode=\(viewModel.isDebugMode), localDebugMode=\(localDebugMode)")
            forceUpdate.toggle()
        }
        .onAppear {
            // Explicitly set the local debug mode from the view model
            self.localDebugMode = viewModel.isDebugMode
            print("DinerCard appeared: viewModel.isDebugMode=\(viewModel.isDebugMode), localDebugMode=\(localDebugMode)")
        }
    }
}

struct EmptyDinerCard: View {
    var body: some View {
        VStack {
            Spacer()
            Text("No restaurant available")
                .foregroundColor(.gray)
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 250)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Supporting Views
struct MapViewContainer: UIViewRepresentable {
    @ObservedObject var viewModel: RecommendationViewModel
    @ObservedObject var locationManager: LocationManager
    var parent: RecommendationView
    
    func makeUIView(context: Context) -> NMFNaverMapView {
        let mapView = NMFNaverMapView(frame: UIScreen.main.bounds)
        
        mapView.showZoomControls = false
        mapView.showCompass = false
        mapView.showScaleBar = false
        mapView.showLocationButton = true
        
        mapView.mapView.positionMode = .disabled
        
        mapView.mapView.minZoomLevel = 7
        mapView.mapView.maxZoomLevel = 18
        mapView.mapView.zoomLevel = 15
        
        mapView.mapView.mapType = .basic
        mapView.mapView.backgroundColor = UIColor.white
        mapView.mapView.layer.isHidden = false
        mapView.mapView.isHidden = false
        
        mapView.mapView.liteModeEnabled = true
        mapView.mapView.isIndoorMapEnabled = false
        mapView.mapView.contentInset = UIEdgeInsets.zero
        
        let southWest = NMGLatLng(lat: 33.0, lng: 124.0)
        let northEast = NMGLatLng(lat: 38.0, lng: 132.0)
        let bounds = NMGLatLngBounds(southWest: southWest, northEast: northEast)
        mapView.mapView.extent = bounds
        
        mapView.mapView.touchDelegate = context.coordinator
        mapView.mapView.addOptionDelegate(delegate: context.coordinator)
        
        let locationOverlay = mapView.mapView.locationOverlay
        locationOverlay.hidden = true
        
        let gangnamStation = NMGLatLng(lat: 37.498095, lng: 127.027610)
        let immediateUpdate = NMFCameraUpdate(scrollTo: gangnamStation)
        immediateUpdate.animation = .none
        mapView.mapView.moveCamera(immediateUpdate)
        
        print("Setting initial camera position to Gangnam Station")
        
        updateRestaurantMarkers(on: mapView.mapView, with: viewModel.restaurants)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            mapView.showZoomControls = true
            mapView.showCompass = true
            mapView.showScaleBar = true
            mapView.mapView.isIndoorMapEnabled = false
            mapView.mapView.liteModeEnabled = false
            
            let finalUpdate = NMFCameraUpdate(scrollTo: gangnamStation, zoomTo: 15)
            finalUpdate.animation = .none
            mapView.mapView.moveCamera(finalUpdate)
            print("Final camera position force to Gangnam Station")
            
            context.coordinator.gangnamStation = gangnamStation
        }
        
        return mapView
    }
    
    func updateUIView(_ uiView: NMFNaverMapView, context: Context) {
        updateRestaurantMarkers(on: uiView.mapView, with: viewModel.restaurants)
        
        DispatchQueue.main.async {
            uiView.setNeedsLayout()
            uiView.layoutIfNeeded()
        }
    }
    
    func updateRestaurantMarkers(on mapView: NMFMapView, with restaurants: [Restaurant]) {
        for restaurant in restaurants {
            let marker = NMFMarker()
            marker.position = NMGLatLng(lat: restaurant.location.latitude, lng: restaurant.location.longitude)
            marker.captionText = restaurant.name
            marker.mapView = mapView
            
            marker.iconImage = NMF_MARKER_IMAGE_RED
            marker.width = 30
            marker.height = 40
            
            marker.touchHandler = { overlay in
                print("Restaurant marker tapped: \(restaurant.name)")
                return true
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NMFMapViewTouchDelegate, NMFMapViewOptionDelegate {
        var parent: MapViewContainer
        var gangnamStation: NMGLatLng?
        
        init(_ parent: MapViewContainer) {
            self.parent = parent
            super.init()
            print("Map coordinator initialized")
        }
        
        func mapView(_ mapView: NMFMapView, didTapMap latlng: NMGLatLng, point: CGPoint) {
            print("Map tapped at \(latlng.lat), \(latlng.lng)")
        }
        
        func mapViewOptionChanged(_ mapView: NMFMapView) {
            print("Map options changed")
            
            DispatchQueue.main.async {
                mapView.setNeedsDisplay()
                
                print("Map is hidden: \(mapView.isHidden)")
                print("Map layer is hidden: \(mapView.layer.isHidden)")
                print("Map type: \(mapView.mapType.rawValue)")
                print("Map frame: \(mapView.frame)")
            }
        }
        
        func mapView(_ mapView: NMFMapView, didTapLocationButton: Bool) -> Bool {
            if mapView.positionMode == .disabled {
                mapView.positionMode = .normal
                
                if let location = parent.locationManager.location {
                    let coord = NMGLatLng(lat: location.coordinate.latitude, lng: location.coordinate.longitude)
                    let cameraUpdate = NMFCameraUpdate(scrollTo: coord)
                    cameraUpdate.animation = .linear
                    mapView.moveCamera(cameraUpdate)
                }
            } else {
                mapView.positionMode = .disabled
                
                if let gangnamStation = gangnamStation {
                    let returnUpdate = NMFCameraUpdate(scrollTo: gangnamStation)
                    returnUpdate.animation = .linear
                    mapView.moveCamera(returnUpdate)
                }
            }
            return true
        }
    }
}

struct RecommendationCard: View {
    let restaurant: Restaurant
    @ObservedObject var viewModel: RecommendationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(restaurant.name)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(restaurant.address)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            HStack {
                Text(restaurant.category)
                    .font(.caption)
                    .padding(4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", restaurant.rating))
                    Text("(\(restaurant.reviewCount))")
                        .foregroundColor(.gray)
                }
            }
            
            // Price Range tag with localized text
            Text(restaurant.priceRange.rawValue == "Budget" ? "저렴함" :
                (restaurant.priceRange.rawValue == "Medium" ? "보통" : "고급"))
                .font(.caption)
                .padding(4)
                .background(Color.green.opacity(0.2))
                .cornerRadius(4)
            
            // Recommendation reason section
            VStack(alignment: .leading, spacing: 4) {
                if let similarFavorites = getSimilarFavorites(to: restaurant) {
                    Text("추천 이유:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("\(similarFavorites)와(과) 비슷한 \(restaurant.category) 음식점")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(.top, 4)
            
            HStack {
                Spacer()
                
                Button(action: {
                    viewModel.downvoteRestaurant(restaurant)
                    viewModel.recommendRestaurant() // Also get a new recommendation when downvoting
                }) {
                    Image(systemName: viewModel.isDownvoted(restaurant) ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                        .foregroundColor(.red)
                        .font(.title2)
                }
                .padding(.horizontal)
                
                Button(action: {
                    viewModel.recommendRestaurant()
                }) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .foregroundColor(.red)
                        .font(.title2)
                }
                .padding(.horizontal)
                
                Button(action: {
                    viewModel.favoriteRestaurant(restaurant)
                }) {
                    Image(systemName: viewModel.isFavorited(restaurant) ? "heart.fill" : "heart")
                        .foregroundColor(.red)
                        .font(.title2)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 5)
    }
    
    // Helper function to find similar favorites for personalized recommendation explanation
    private func getSimilarFavorites(to restaurant: Restaurant) -> String? {
        let similarFavorites = viewModel.favoriteRestaurants
            .filter { $0.category == restaurant.category }
            .prefix(2)  // Get at most 2 similar restaurants for display
            .map { $0.name }
        
        if !similarFavorites.isEmpty {
            return similarFavorites.joined(separator: ", ")
        }
        
        return nil
    }
}

// Missing views for favorites and downvotes
struct FavoriteListView: View {
    @ObservedObject var viewModel: RecommendationViewModel
    
    var body: some View {
        List {
            if viewModel.favoriteRestaurants.isEmpty {
                Text("즐겨찾는 음식점이 없습니다")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ForEach(viewModel.favoriteRestaurants) { restaurant in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(restaurant.name)
                            .font(.headline)
                        Text(restaurant.category)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text(restaurant.address)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let restaurant = viewModel.favoriteRestaurants[index]
                        viewModel.favoriteRestaurant(restaurant)
                    }
                }
            }
        }
        .navigationTitle("즐겨찾는 음식점")
    }
}

struct DownvotedListView: View {
    @ObservedObject var viewModel: RecommendationViewModel
    
    var body: some View {
        List {
            if viewModel.downvotedRestaurants.isEmpty {
                Text("싫어하는 음식점이 없습니다")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ForEach(viewModel.downvotedRestaurants) { restaurant in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(restaurant.name)
                            .font(.headline)
                        Text(restaurant.category)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text(restaurant.address)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let restaurant = viewModel.downvotedRestaurants[index]
                        viewModel.downvoteRestaurant(restaurant)
                    }
                }
            }
        }
        .navigationTitle("싫어하는 음식점")
    }
}

#Preview {
    let locationManager = LocationManager()
    let viewModel = RecommendationViewModel(locationManager: locationManager)
    
    let recommendationView = RecommendationView(
        viewModel: viewModel,
        locationManager: locationManager
    )
    
    return recommendationView
} 
