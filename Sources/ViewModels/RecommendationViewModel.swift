import Foundation
import Combine
import CoreLocation
import NMapsMap

// Import the Services module explicitly if needed
// import Services

// Use forward declaration for RecommendationEngine in case the import is causing issues
// This allows the compiler to understand that RecommendationEngine is a type
// even if it can't find the actual definition at this point
// @_implementationOnly import PlatePal

// Add this near the top of the file with other model definitions
struct SelectionRecord {
    let selectedRestaurant: Restaurant
    let rejectedRestaurant: Restaurant
    let date: Date
}

class RecommendationViewModel: ObservableObject {
    @Published var restaurants: [Restaurant] = []
    @Published var currentRecommendation: Restaurant?
    @Published var dinerRecommendations: [Restaurant] = []
    @Published var dinerSelections: [Bool] = [false, false]
    @Published var isLoading = false
    @Published var error: Error?
    @Published var favoriteRestaurants: [Restaurant] = []
    @Published var downvotedRestaurants: [Restaurant] = []
    @Published var randomnessFactor: Double = 0.5
    @Published var isDebugMode: Bool = false
    @Published var selectedRestaurant: Restaurant?
    @Published var selectionHistory: [SelectionRecord] = []
    
    private let locationManager: LocationManager
    private var cancellables = Set<AnyCancellable>()
    private let naverMapService = NaverMapService()
    
    // Store the most recent scores for debug display
    private var restaurantScores: [String: Double] = [:]
    private var categorySimilarities: [String: Double] = [:]
    
    init(locationManager: LocationManager) {
        self.locationManager = locationManager
        
        // Load sample data immediately
        loadSampleData()
        
        // Subscribe to location updates
        locationManager.$location
            .compactMap { $0 }
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateRestaurantDistances()
            }
            .store(in: &cancellables)
            
        // Load saved preferences
        loadSavedPreferences()
    }
    
    private func loadSampleData() {
        // Sample data - diverse restaurants located in Gangnam, Seoul
        let sampleRestaurants = [
            Restaurant(
                id: UUID().uuidString,
                name: "국수나무 강남점",
                address: "서울 강남구 강남대로 340",
                category: "한식",
                rating: 4.5,
                reviewCount: 120,
                priceRange: .medium,
                location: CLLocationCoordinate2D(latitude: 37.498095, longitude: 127.027610), // Gangnam Station
                imageURL: nil,
                phoneNumber: "02-1234-5678",
                operatingHours: "10:00 - 22:00",
                description: "맛있는 국수와 만두를 즐길 수 있는 곳입니다."
            ),
            Restaurant(
                id: UUID().uuidString,
                name: "봉피양 강남점",
                address: "서울 강남구 테헤란로 152",
                category: "한식",
                rating: 4.8,
                reviewCount: 250,
                priceRange: .premium,
                location: CLLocationCoordinate2D(latitude: 37.500582, longitude: 127.036203), // Near Gangnam Station
                imageURL: nil,
                phoneNumber: "02-987-6543",
                operatingHours: "11:30 - 21:30",
                description: "전통 한식을 현대적으로 재해석한 맛집입니다."
            ),
            Restaurant(
                id: UUID().uuidString,
                name: "버거킹 강남역점",
                address: "서울 강남구 강남대로 396",
                category: "패스트푸드",
                rating: 4.2,
                reviewCount: 180,
                priceRange: .budget,
                location: CLLocationCoordinate2D(latitude: 37.496323, longitude: 127.028981), // Another location near Gangnam
                imageURL: nil,
                phoneNumber: "02-555-7890",
                operatingHours: "24시간",
                description: "맛있는 햄버거와 사이드 메뉴를 제공합니다."
            ),
            Restaurant(
                id: UUID().uuidString,
                name: "스시미야 강남점",
                address: "서울 강남구 역삼로 123",
                category: "일식",
                rating: 4.7,
                reviewCount: 150,
                priceRange: .premium,
                location: CLLocationCoordinate2D(latitude: 37.499540, longitude: 127.030231),
                imageURL: nil,
                phoneNumber: "02-555-1234",
                operatingHours: "11:30 - 22:00",
                description: "신선한 생선으로 만든 일본 전통 스시."
            ),
            Restaurant(
                id: UUID().uuidString,
                name: "진미 양꼬치",
                address: "서울 강남구 강남대로 432",
                category: "중식",
                rating: 4.6,
                reviewCount: 220,
                priceRange: .medium,
                location: CLLocationCoordinate2D(latitude: 37.495683, longitude: 127.029654),
                imageURL: nil,
                phoneNumber: "02-555-7777",
                operatingHours: "16:00 - 02:00",
                description: "양꼬치와 중국 전통 요리를 즐길 수 있는 곳."
            ),
            Restaurant(
                id: UUID().uuidString,
                name: "맥도날드 강남직영점",
                address: "서울 강남구 테헤란로 4길 15",
                category: "패스트푸드",
                rating: 4.0,
                reviewCount: 300,
                priceRange: .budget,
                location: CLLocationCoordinate2D(latitude: 37.497102, longitude: 127.027355),
                imageURL: nil,
                phoneNumber: "02-555-3333",
                operatingHours: "24시간",
                description: "클래식 버거와 함께 다양한 메뉴를 제공합니다."
            ),
            Restaurant(
                id: UUID().uuidString,
                name: "본가 서울갈비",
                address: "서울 강남구 테헤란로 152",
                category: "한식",
                rating: 4.9,
                reviewCount: 450,
                priceRange: .premium,
                location: CLLocationCoordinate2D(latitude: 37.504502, longitude: 127.049383),
                imageURL: nil,
                phoneNumber: "02-555-8888",
                operatingHours: "11:00 - 22:00",
                description: "프리미엄 한우 갈비를 맛볼 수 있는 정통 한식당."
            ),
            Restaurant(
                id: UUID().uuidString,
                name: "스타벅스 강남역점",
                address: "서울 강남구 강남대로 396",
                category: "카페",
                rating: 4.3,
                reviewCount: 280,
                priceRange: .medium,
                location: CLLocationCoordinate2D(latitude: 37.497524, longitude: 127.028546),
                imageURL: nil,
                phoneNumber: "02-555-2222",
                operatingHours: "07:00 - 23:00",
                description: "다양한 커피와 음료를 즐길 수 있는 카페."
            ),
            Restaurant(
                id: UUID().uuidString,
                name: "베트남이랑",
                address: "서울 강남구 역삼로 234",
                category: "베트남음식",
                rating: 4.4,
                reviewCount: 130,
                priceRange: .budget,
                location: CLLocationCoordinate2D(latitude: 37.500933, longitude: 127.036227),
                imageURL: nil,
                phoneNumber: "02-555-4444",
                operatingHours: "10:00 - 22:00",
                description: "정통 베트남 쌀국수와 월남쌈을 맛볼 수 있는 곳."
            ),
            Restaurant(
                id: UUID().uuidString,
                name: "치즈룸",
                address: "서울 강남구 논현로 428",
                category: "이탈리안",
                rating: 4.6,
                reviewCount: 190,
                priceRange: .premium,
                location: CLLocationCoordinate2D(latitude: 37.495230, longitude: 127.036854),
                imageURL: nil,
                phoneNumber: "02-555-5555",
                operatingHours: "11:30 - 23:00",
                description: "다양한 치즈 요리와 와인을 즐길 수 있는 이탈리안 레스토랑."
            )
        ]
        
        self.restaurants = sampleRestaurants
        
        // Set initial recommendation if none exists
        if currentRecommendation == nil && !restaurants.isEmpty {
            recommendRestaurant()
        }
    }
    
    private func loadSavedPreferences() {
        if let favoritesData = UserDefaults.standard.data(forKey: "favoriteRestaurants"),
           let favorites = try? JSONDecoder().decode([Restaurant].self, from: favoritesData) {
            self.favoriteRestaurants = favorites
        }
        
        if let downvotedData = UserDefaults.standard.data(forKey: "downvotedRestaurants"),
           let downvoted = try? JSONDecoder().decode([Restaurant].self, from: downvotedData) {
            self.downvotedRestaurants = downvoted
        }
    }
    
    private func savePreferences() {
        if let favoritesData = try? JSONEncoder().encode(favoriteRestaurants) {
            UserDefaults.standard.set(favoritesData, forKey: "favoriteRestaurants")
        }
        
        if let downvotedData = try? JSONEncoder().encode(downvotedRestaurants) {
            UserDefaults.standard.set(downvotedData, forKey: "downvotedRestaurants")
        }
    }
    
    func fetchRestaurants() {
        guard let location = locationManager.location?.coordinate else {
            // If no location is available, use Gangnam Station
            let gangnamLocation = CLLocationCoordinate2D(latitude: 37.498095, longitude: 127.027610)
            fetchRestaurantsNear(gangnamLocation)
            return
        }
        
        fetchRestaurantsNear(location)
    }
    
    private func fetchRestaurantsNear(_ location: CLLocationCoordinate2D) {
        isLoading = true
        error = nil
        
        Task {
            do {
                // Use "맛집" (restaurant) as default search term
                let restaurants = try await naverMapService.searchRestaurants(
                    query: "맛집",
                    location: location
                )
                
                await MainActor.run {
                    if !restaurants.isEmpty {
                        // Update restaurants with calculated distances
                        self.restaurants = restaurants.map { restaurant in
                            var updatedRestaurant = restaurant
                            updatedRestaurant.distance = self.calculateDistance(
                                from: location,
                                to: restaurant.location
                            )
                            return updatedRestaurant
                        }
                    }
                    self.isLoading = false
                    
                    // If we have restaurants but no recommendations yet, generate them
                    if !self.restaurants.isEmpty && self.dinerRecommendations.isEmpty {
                        self.recommendDiners()
                    }
                }
            } catch {
                await MainActor.run {
                    if let networkError = error as? NetworkError {
                        switch networkError {
                        case .decodingError(let message):
                            print("Decoding error: \(message)")
                        case .apiError(let message):
                            print("API error: \(message)")
                        case .other(let error):
                            print("Other error: \(error.localizedDescription)")
                        }
                    } else {
                        print("Error fetching restaurants: \(error)")
                    }
                    
                    // Don't clear restaurants on error - keep existing data
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
    
    // Update distances for all restaurants when location changes
    private func updateRestaurantDistances() {
        guard let location = locationManager.location?.coordinate else { return }
        
        // Update distances for all restaurants
        self.restaurants = restaurants.map { restaurant in
            var updatedRestaurant = restaurant
            updatedRestaurant.distance = calculateDistance(
                from: location,
                to: restaurant.location
            )
            return updatedRestaurant
        }
        
        // Also update distances for recommendations
        self.dinerRecommendations = dinerRecommendations.map { restaurant in
            var updatedRestaurant = restaurant
            updatedRestaurant.distance = calculateDistance(
                from: location,
                to: restaurant.location
            )
            return updatedRestaurant
        }
    }
    
    func recommendRestaurant() {
        // Get the user's price range preference
        let preferredPriceRange: Restaurant.PriceRange?
        if let priceRangeRawValue = UserDefaults.standard.string(forKey: "priceRange"),
           let priceRangeFallback = PriceRangeFallback(rawValue: priceRangeRawValue) {
            // Convert from PriceRangeFallback to Restaurant.PriceRange
            switch priceRangeFallback {
            case .budget:
                preferredPriceRange = .budget
            case .medium:
                preferredPriceRange = .medium
            case .premium:
                preferredPriceRange = .premium
            }
        } else {
            // Default to no preference
            preferredPriceRange = nil
        }
        
        // Get the user's maximum distance preference
        let maxDistance = UserDefaults.standard.double(forKey: "maxDistance")
        
        // Get the user's location
        let userLocation = locationManager.location?.coordinate
        
        // Get show downvoted preference
        let showDownvoted = UserDefaults.standard.bool(forKey: "showDownvoted")
        
        // Inline recommendation logic instead of using the RecommendationEngine
        let eligibleRestaurants = restaurants.filter { restaurant in
            // Skip downvoted unless explicitly included
            if !showDownvoted && downvotedRestaurants.contains(where: { $0.id == restaurant.id }) {
                return false
            }
            
            // Filter by price range if specified
            if let priceRange = preferredPriceRange, restaurant.priceRange != priceRange {
                return false
            }
            
            // Filter by distance if location and max distance available
            if let userLoc = userLocation, maxDistance > 0 {
                let distance = calculateDistance(from: userLoc, to: restaurant.location)
                if distance > maxDistance {
                    return false
                }
            }
            
            return true
        }
        
        if eligibleRestaurants.isEmpty {
            // No restaurants match the filters, use a random one
            currentRecommendation = restaurants.randomElement()
            return
        }
        
        // Score and recommend
        let scoredRestaurants = eligibleRestaurants.map { restaurant -> (Restaurant, Double) in
            let score = calculateScore(
                for: restaurant,
                favoriteRestaurants: favoriteRestaurants,
                userLocation: userLocation
            )
            return (restaurant, score)
        }
        
        // Sort by score and pick the highest
        let sortedRestaurants = scoredRestaurants.sorted(by: { $0.1 > $1.1 })
        
        if let topRestaurant = sortedRestaurants.first?.0 {
            currentRecommendation = topRestaurant
        } else {
            // Fallback to random
            currentRecommendation = restaurants.randomElement()
        }
    }
    
    // Helper methods for recommendation
    
    private func calculateScore(
        for restaurant: Restaurant,
        favoriteRestaurants: [Restaurant],
        userLocation: CLLocationCoordinate2D?
    ) -> Double {
        var score: Double = 1.0 // Base score
        
        // Collaborative filtering component - Category similarity
        score += calculateCategorySimilarity(
            restaurant: restaurant,
            favoriteRestaurants: favoriteRestaurants
        ) * 3.0 // Category is highly important
        
        // Collaborative filtering component - Price range similarity
        score += calculatePriceRangeSimilarity(
            restaurant: restaurant,
            favoriteRestaurants: favoriteRestaurants
        ) * 2.0 // Price range is important
        
        // Rating factor (higher rating = higher score)
        score += (restaurant.rating / 5.0) * 1.5
        
        // Distance factor (closer = higher score) - only if location available
        if let userLoc = userLocation {
            let distance = calculateDistance(from: userLoc, to: restaurant.location)
            // Inverse relationship - closer means higher score
            // Start penalizing after 1000m, maximum penalty at 5000m
            if distance > 1000 {
                let distancePenalty = min(1.0, (distance - 1000) / 4000)
                score -= distancePenalty * 1.0
            }
        }
        
        // Popularity factor (more reviews = higher score, with diminishing returns)
        let reviewCountFactor = min(1.0, Double(restaurant.reviewCount) / 200.0)
        score += reviewCountFactor * 0.5
        
        return score
    }
    
    private func calculateCategorySimilarity(
        restaurant: Restaurant,
        favoriteRestaurants: [Restaurant]
    ) -> Double {
        guard !favoriteRestaurants.isEmpty else { return 0.0 }
        
        // Count how many favorites share the same category
        let sameCategory = favoriteRestaurants.filter { $0.category == restaurant.category }.count
        return Double(sameCategory) / Double(favoriteRestaurants.count)
    }
    
    private func calculatePriceRangeSimilarity(
        restaurant: Restaurant,
        favoriteRestaurants: [Restaurant]
    ) -> Double {
        guard !favoriteRestaurants.isEmpty else { return 0.0 }
        
        // Count how many favorites share the same price range
        let samePriceRange = favoriteRestaurants.filter { $0.priceRange == restaurant.priceRange }.count
        return Double(samePriceRange) / Double(favoriteRestaurants.count)
    }
    
    private func calculateDistance(from userLocation: CLLocationCoordinate2D, to restaurantLocation: CLLocationCoordinate2D) -> Double {
        let userCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let restaurantCLLocation = CLLocation(latitude: restaurantLocation.latitude, longitude: restaurantLocation.longitude)
        return userCLLocation.distance(from: restaurantCLLocation)
    }
    
    func getRecommendation() {
        isLoading = true
        
        guard let location = locationManager.location else {
            // If location is not available, use temporary data
            let workItem = DispatchWorkItem {
                self.restaurants = [
                    Restaurant(
                        id: "1",
                        name: "맛있는 돈까스",
                        address: "서울시 강남구 테헤란로 123",
                        category: "일식",
                        rating: 4.5,
                        reviewCount: 120,
                        priceRange: .medium,
                        location: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
                        imageURL: nil,
                        phoneNumber: nil as String?,
                        operatingHours: nil as String?,
                        description: nil as String?
                    )
                ]
                self.isLoading = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: workItem)
            return
        }
        
        // Simulated API call - replace with actual API call
        let workItem = DispatchWorkItem {
            self.restaurants = [
                Restaurant(
                    id: "2",
                    name: "맛있는 돈까스",
                    address: "서울시 강남구 테헤란로 123",
                    category: "일식",
                    rating: 4.5,
                    reviewCount: 120,
                    priceRange: .medium,
                    location: CLLocationCoordinate2D(
                        latitude: location.coordinate.latitude + 0.001,
                        longitude: location.coordinate.longitude + 0.001
                    ),
                    imageURL: nil,
                    phoneNumber: nil as String?,
                    operatingHours: nil as String?,
                    description: nil as String?
                )
            ]
            self.isLoading = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: workItem)
    }
    
    func favoriteRestaurant(_ restaurant: Restaurant) {
        // Notify observers before changes
        objectWillChange.send()
        
        var wasAdded = false
        
        if let index = favoriteRestaurants.firstIndex(where: { $0.id == restaurant.id }) {
            print("Removing \(restaurant.name) from favorites")
            favoriteRestaurants.remove(at: index)
        } else {
            print("Adding \(restaurant.name) to favorites")
            favoriteRestaurants.append(restaurant)
            wasAdded = true
            
            // If the restaurant was previously downvoted, remove it from downvoted list
            if let downvoteIndex = downvotedRestaurants.firstIndex(where: { $0.id == restaurant.id }) {
                downvotedRestaurants.remove(at: downvoteIndex)
            }
        }
        
        // Force UI update by sending multiple notifications
        DispatchQueue.main.async {
            self.objectWillChange.send()
            
            // If we added to favorites, refresh recommendations to show the impact
            if wasAdded {
                // Wait a moment to ensure the UI shows the favorite animation first
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.refreshBothDiners()
                }
            }
            
            // Send another notification after a short delay to ensure UI updates
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.objectWillChange.send()
            }
        }
        
        // Save changes to UserDefaults
        savePreferences()
    }
    
    func downvoteRestaurant(_ restaurant: Restaurant) {
        // Notify observers before changes
        objectWillChange.send()
        
        var wasAdded = false
        
        if let index = downvotedRestaurants.firstIndex(where: { $0.id == restaurant.id }) {
            print("Removing \(restaurant.name) from downvoted")
            downvotedRestaurants.remove(at: index)
        } else {
            print("Adding \(restaurant.name) to downvoted")
            downvotedRestaurants.append(restaurant)
            wasAdded = true
            
            // If the restaurant was previously favorited, remove it from favorites list
            if let favoriteIndex = favoriteRestaurants.firstIndex(where: { $0.id == restaurant.id }) {
                favoriteRestaurants.remove(at: favoriteIndex)
            }
        }
        
        // Force UI update by sending multiple notifications
        DispatchQueue.main.async {
            self.objectWillChange.send()
            
            // If we added to downvoted, refresh recommendations to show the impact
            if wasAdded {
                // Wait a moment to ensure the UI shows the downvote animation first
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.refreshBothDiners()
                }
            }
            
            // Send another notification after a short delay to ensure UI updates
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.objectWillChange.send()
            }
        }
        
        // Save changes to UserDefaults
        savePreferences()
    }
    
    // Check if a restaurant is favorited
    func isFavorited(_ restaurant: Restaurant) -> Bool {
        return favoriteRestaurants.contains(where: { $0.id == restaurant.id })
    }
    
    // Check if a restaurant is downvoted
    func isDownvoted(_ restaurant: Restaurant) -> Bool {
        return downvotedRestaurants.contains(where: { $0.id == restaurant.id })
    }
    
    func toggleSelection(at index: Int) {
        // Make sure we have valid diner recommendations and selections
        guard !dinerRecommendations.isEmpty,
              index < dinerRecommendations.count,
              index < dinerSelections.count else {
            print("Error: Invalid index \(index) or empty recommendations")
            return
        }
        
        print("Toggling selection at index \(index)")
        
        // Toggle selection for this diner
        dinerSelections[index].toggle()
        
        // If selected, deselect others and record the selection
        if dinerSelections[index] {
            let selectedDiner = dinerRecommendations[index]
            print("Selected restaurant: \(selectedDiner.name)")
            
            // Only record selection if we have at least 2 recommendations to compare
            if dinerRecommendations.count >= 2 {
                // Find the other restaurant that was not selected
                let otherIndex = index == 0 ? 1 : 0
                
                // Additional bounds check
                guard otherIndex < dinerRecommendations.count else {
                    print("Error: Other index \(otherIndex) out of bounds")
                    return
                }
                
                let rejectedRestaurant = dinerRecommendations[otherIndex]
                
                // Add to selection history
                let record = SelectionRecord(
                    selectedRestaurant: selectedDiner,
                    rejectedRestaurant: rejectedRestaurant,
                    date: Date()
                )
                selectionHistory.append(record)
                print("Added to selection history. Count now: \(selectionHistory.count)")
                
                // Debug info
                for (i, record) in selectionHistory.enumerated() {
                    print("Record \(i): Selected \(record.selectedRestaurant.name) over \(record.rejectedRestaurant.name)")
                }
            }
            
            // Deselect other diners
            for i in 0..<dinerSelections.count {
                if i != index {
                    dinerSelections[i] = false
                }
            }
            
            // Store the selected restaurant BEFORE refreshing recommendations
            self.selectedRestaurant = selectedDiner
            
            // Refresh recommendations to reflect the selection
            refreshBothDiners()
        }
        
        // Always notify UI to update after toggling selection
        objectWillChange.send()
    }
    
    // Refresh a single diner
    private func refreshDiner(at index: Int) {
        guard index < dinerRecommendations.count else { return }
        print("Refreshing diner at index: \(index)")
        
        // Keep track of the restaurant being replaced
        let oldRestaurant = dinerRecommendations[index]
        print("Replacing restaurant: \(oldRestaurant.name)")
        
        // Generate a new recommendation for this slot
        if let newRestaurant = getNextBestRestaurant(ignoring: [oldRestaurant]) {
            print("Found new restaurant: \(newRestaurant.name)")
            dinerRecommendations[index] = newRestaurant
            
            // Force UI refresh
            DispatchQueue.main.async {
                self.objectWillChange.send()
                
                // Send again after a short delay to ensure UI refreshes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.objectWillChange.send()
                }
            }
        } else {
            print("Could not find a new restaurant to replace \(oldRestaurant.name)")
        }
    }
    
    // Refresh both diners but stack selected restaurant for future recommendations
    private func refreshBothDiners() {
        // Generate recommendations while keeping the user selection in mind
        recommendDiners()
    }
    
    // MARK: - Diner Recommendation Functions
    
    func recommendDiners() {
        // Notify observers about upcoming changes
        objectWillChange.send()
        
        // Reset selections
        dinerSelections = [false, false]
        
        // Start by clearing any existing recommendations
        dinerRecommendations = []
        
        // Only recommend if we have restaurants to choose from
        guard !restaurants.isEmpty else {
            print("No restaurants available for recommendation")
            return
        }
        
        // Implementation of the dual diner recommendation system
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Get eligible restaurants based on user preferences
            let eligibleRestaurants = self.getEligibleRestaurants()
            
            // Auto-selection feature (to avoid forcing user selection)
            let autoSelectEnabled = UserDefaults.standard.bool(forKey: "autoSelectEnabled")
            
            // Used for random selection with the randomness slider
            let randomnessFactor = self.randomnessFactor
            print("Randomness factor: \(randomnessFactor)")
            
            // Simple case: If we don't have enough restaurants, just pick random ones
            if eligibleRestaurants.count <= 1 {
                var randomSelections = [Restaurant]()
                
                // Add the one eligible restaurant if there is one
                if let singleRestaurant = eligibleRestaurants.first {
                    randomSelections.append(singleRestaurant)
                }
                
                // If we need a second one, pick a random one from the full set
                if randomSelections.count < 2 {
                    let allRestaurants = self.restaurants
                    
                    for _ in 0..<(2 - randomSelections.count) {
                        if let randomRestaurant = allRestaurants.randomElement() {
                            if !randomSelections.contains(where: { $0.id == randomRestaurant.id }) {
                                randomSelections.append(randomRestaurant)
                            }
                        }
                    }
                    
                    // If we couldn't get 2 restaurants, duplicate the one we have
                    if randomSelections.count == 1 && self.restaurants.count == 1 {
                        randomSelections.append(randomSelections[0])
                    }
                }
                
                // Update the UI on the main thread
                DispatchQueue.main.async {
                    self.dinerRecommendations = randomSelections
                    self.isLoading = false
                    self.objectWillChange.send() // Force UI refresh
                }
                return
            }
            
            // Main implementation: Score restaurants and select two
            let scoredRestaurants = eligibleRestaurants.map { restaurant -> (Restaurant, Double) in
                let score = self.calculateScore(
                    for: restaurant,
                    favoriteRestaurants: self.favoriteRestaurants,
                    userLocation: self.locationManager.location?.coordinate
                )
                
                // Store the scores for debug display
                DispatchQueue.main.async {
                    self.restaurantScores[restaurant.id] = score
                    self.categorySimilarities[restaurant.id] = self.calculateCategorySimilarity(
                        restaurant: restaurant,
                        favoriteRestaurants: self.favoriteRestaurants
                    )
                }
                
                return (restaurant, score)
            }
            
            // Sort by score (highest first)
            let sortedRestaurants = scoredRestaurants.sorted(by: { $0.1 > $1.1 })
            
            // Select recommendations using our randomness factor
            var recommendations = [Restaurant]()
            
            // Always pick the first restaurant with some probability based on randomness
            if !sortedRestaurants.isEmpty && (randomnessFactor < 0.8 || Double.random(in: 0...1) < 0.7) {
                recommendations.append(sortedRestaurants[0].0)
            } else if !sortedRestaurants.isEmpty {
                // Otherwise pick a random restaurant from the top half
                let topHalfCount = max(1, sortedRestaurants.count / 2)
                let randomIndex = Int.random(in: 0..<topHalfCount)
                recommendations.append(sortedRestaurants[randomIndex].0)
            }
            
            // For the second pick, either use the next best, or pick based on randomness
            if recommendations.count == 1 {
                // Use _ instead of excludeFirstPick since it's not used
                _ = recommendations[0]
                let remainingOptions = sortedRestaurants.filter { pair in
                    !recommendations.contains(where: { $0.id == pair.0.id })
                }
                
                if !remainingOptions.isEmpty {
                    if randomnessFactor < 0.5 || Double.random(in: 0...1) < 0.8 {
                        // Pick the highest scored remaining restaurant
                        recommendations.append(remainingOptions[0].0)
                    } else {
                        // Pick a random restaurant from the top half of remaining ones
                        let topHalfCount = max(1, remainingOptions.count / 2)
                        let randomIndex = Int.random(in: 0..<topHalfCount)
                        recommendations.append(remainingOptions[randomIndex].0)
                    }
                }
            }
            
            // Update the UI on the main thread
            DispatchQueue.main.async {
                self.dinerRecommendations = recommendations
                self.isLoading = false
                
                // Auto-select if enabled
                if autoSelectEnabled {
                    self.autoSelectRestaurant()
                }
                
                // Notify observers about changes
                self.objectWillChange.send() // Force UI refresh
                print("Updated diner recommendations: \(recommendations.map { $0.name }.joined(separator: ", "))")
            }
        }
    }
    
    // MARK: - Selection State Functions
    
    func markAsSelected(at index: Int) {
        guard index < dinerSelections.count else { return }
        print("Toggling selection at index \(index)")
        
        // Toggle selection for this diner
        dinerSelections[index].toggle()
        
        // If selected, deselect others and record the selection
        if dinerSelections[index] {
            let selectedDiner = dinerRecommendations[index]
            print("Selected restaurant: \(selectedDiner.name)")
            
            // Find the other restaurant that was not selected
            if dinerRecommendations.count >= 2 {
                let otherIndex = index == 0 ? 1 : 0
                let rejectedRestaurant = dinerRecommendations[otherIndex]
                
                // Add to selection history
                let record = SelectionRecord(
                    selectedRestaurant: selectedDiner,
                    rejectedRestaurant: rejectedRestaurant,
                    date: Date()
                )
                selectionHistory.append(record)
                print("Added to selection history. Count now: \(selectionHistory.count)")
                
                // Debug info
                for (i, record) in selectionHistory.enumerated() {
                    print("Record \(i): Selected \(record.selectedRestaurant.name) over \(record.rejectedRestaurant.name)")
                }
            }
            
            // Deselect other diners
            for i in 0..<dinerSelections.count {
                if i != index {
                    dinerSelections[i] = false
                }
            }
            
            // Refresh both diners when selection is made
            refreshBothDiners()
            
            // Store the selected restaurant for future recommendations
            self.selectedRestaurant = dinerRecommendations[index]
        }
        
        // Always notify UI to update after toggling selection
        objectWillChange.send()
    }
    
    func markAsNotSelected(at index: Int) {
        guard index < dinerSelections.count else { return }
        dinerSelections[index] = false
    }
    
    func isSelected(at index: Int) -> Bool {
        guard index < dinerSelections.count else { return false }
        return dinerSelections[index]
    }
    
    // MARK: - Randomness Control
    
    func setRandomnessFactor(_ factor: Double) {
        randomnessFactor = max(0, min(1, factor))
    }
    
    // MARK: - Map Control Functions
    
    func zoomInMap() {
        // This will be implemented in the MapView as a passthrough
        NotificationCenter.default.post(name: Notification.Name("MapZoomIn"), object: nil)
    }
    
    func zoomOutMap() {
        // This will be implemented in the MapView as a passthrough
        NotificationCenter.default.post(name: Notification.Name("MapZoomOut"), object: nil)
    }
    
    // MARK: - Debug Information
    
    func getRestaurantScore(_ restaurant: Restaurant) -> Double {
        return restaurantScores[restaurant.id] ?? 0.0
    }
    
    func getCategorySimilarity(_ restaurant: Restaurant) -> Double {
        return categorySimilarities[restaurant.id] ?? 0.0
    }
    
    // Additional debug scoring information for component visualization
    func getDistanceScore(_ restaurant: Restaurant) -> Double {
        // Calculate a distance score from 0-1 (higher is better, closer)
        // Maximum distance is 5000m, so invert the normalized value
        let normalizedDistance = min(1.0, restaurant.distance / 5000.0)
        return 1.0 - normalizedDistance
    }
    
    func getPriceScore(_ restaurant: Restaurant) -> Double {
        // Match price preference (higher is better match)
        // In a real app, this would be based on user-specified price preference
        switch restaurant.priceRange {
        case .budget:
            return 0.8
        case .medium:
            return 1.0
        case .premium:
            return 0.7
        }
    }
    
    func getFavoriteScore(_ restaurant: Restaurant) -> Double {
        // If this restaurant or category is favorited, high score
        if favoriteRestaurants.contains(where: { $0.id == restaurant.id }) {
            return 1.0
        }
        
        // If any favorited restaurants in this category, moderate score
        if favoriteRestaurants.contains(where: { $0.category == restaurant.category }) {
            return 0.7
        }
        
        return 0.0
    }
    
    func getRandomnessScore() -> Double {
        // Use the randomness factor directly
        // This is simplified as the actual randomness is more complex in the selection algorithm
        return Double.random(in: 0.0...randomnessFactor)
    }
    
    // Auto-select restaurant based on highest score
    func autoSelectRestaurant() {
        // Reset selections
        dinerSelections = [false, false]
        
        // If we have recommendations, find the highest scored one
        if !dinerRecommendations.isEmpty {
            var highestScore = 0.0
            var highestIndex = 0
            
            for (index, restaurant) in dinerRecommendations.enumerated() {
                let score = getRestaurantScore(restaurant)
                if score > highestScore {
                    highestScore = score
                    highestIndex = index
                }
            }
            
            // Select the highest scored restaurant
            if highestIndex < dinerSelections.count {
                dinerSelections[highestIndex] = true
            }
        }
    }
    
    // MARK: - Restaurant Filtering and Scoring
    
    private func getEligibleRestaurants() -> [Restaurant] {
        // Get user preferences from UserDefaults
        let preferredPriceRange: Restaurant.PriceRange?
        if let priceRangeRawValue = UserDefaults.standard.string(forKey: "priceRange"),
           let priceRangeFallback = PriceRangeFallback(rawValue: priceRangeRawValue) {
            // Convert from PriceRangeFallback to Restaurant.PriceRange
            switch priceRangeFallback {
            case .budget:
                preferredPriceRange = .budget
            case .medium:
                preferredPriceRange = .medium
            case .premium:
                preferredPriceRange = .premium
            }
        } else {
            preferredPriceRange = nil
        }
        
        let maxDistance = UserDefaults.standard.double(forKey: "maxDistance")
        let showDownvoted = UserDefaults.standard.bool(forKey: "showDownvoted")
        let userLocation = locationManager.location?.coordinate
        
        return restaurants.filter { restaurant in
            // Skip downvoted unless explicitly included
            if !showDownvoted && downvotedRestaurants.contains(where: { $0.id == restaurant.id }) {
                return false
            }
            
            // Filter by price range if specified
            if let priceRange = preferredPriceRange, restaurant.priceRange != priceRange {
                return false
            }
            
            // Filter by distance if location and max distance available
            if let userLoc = userLocation, maxDistance > 0 {
                let distance = calculateDistance(from: userLoc, to: restaurant.location)
                if distance > maxDistance {
                    return false
                }
            }
            
            return true
        }
    }
    
    // Get the next best restaurant based on scores, ignoring specified restaurants
    private func getNextBestRestaurant(ignoring excludedRestaurants: [Restaurant]) -> Restaurant? {
        // Get eligible restaurants but exclude the ones we're ignoring
        let eligibleRestaurants = getEligibleRestaurants().filter { restaurant in
            !excludedRestaurants.contains(where: { $0.id == restaurant.id })
        }
        
        guard !eligibleRestaurants.isEmpty else { return nil }
        
        // Score the restaurants
        let scoredRestaurants = eligibleRestaurants.map { restaurant -> (Restaurant, Double) in
            let score = calculateScore(
                for: restaurant,
                favoriteRestaurants: favoriteRestaurants,
                userLocation: locationManager.location?.coordinate
            )
            return (restaurant, score)
        }
        
        // Sort by score
        let sortedRestaurants = scoredRestaurants.sorted(by: { $0.1 > $1.1 })
        
        // Select with randomness
        return selectWithRandomness(from: sortedRestaurants)
    }
    
    // Add the missing selectWithRandomness function to fix the reference at line 1054
    private func selectWithRandomness(from scoredRestaurants: [(Restaurant, Double)]) -> Restaurant? {
        guard !scoredRestaurants.isEmpty else { return nil }
        
        // With 0% randomness, always choose the first (highest scored)
        // With 100% randomness, choose completely randomly
        // With 50% randomness, prefer higher scored but with substantial randomness
        
        if randomnessFactor >= 1.0 || scoredRestaurants.count == 1 {
            return scoredRestaurants.randomElement()?.0
        }
        
        // Create a bias toward higher-ranked items
        var weights = [Double]()
        let count = Double(scoredRestaurants.count)
        
        for i in 0..<scoredRestaurants.count {
            // Linear bias factor: restaurants at the beginning get higher weight
            let position = Double(i) / max(1, count - 1) 
            let weight = 1.0 - (position * (1.0 - randomnessFactor))
            weights.append(weight)
        }
        
        // Normalize weights
        let totalWeight = weights.reduce(0, +)
        let normalizedWeights = weights.map { $0 / totalWeight }
        
        // Random selection based on weights
        let random = Double.random(in: 0..<1)
        var cumulativeWeight = 0.0
        
        for i in 0..<normalizedWeights.count {
            cumulativeWeight += normalizedWeights[i]
            if random < cumulativeWeight {
                return scoredRestaurants[i].0
            }
        }
        
        // Fallback to the first item
        return scoredRestaurants.first?.0
    }
}

extension Notification.Name {
    static let refreshDownvotedStatus = Notification.Name("refreshDownvotedStatus")
    static let refreshFavoritedStatus = Notification.Name("refreshFavoritedStatus")
    static let refreshSelectionStatus = Notification.Name("refreshSelectionStatus")
} 
