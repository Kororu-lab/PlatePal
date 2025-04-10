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

class RecommendationViewModel: ObservableObject {
    @Published var restaurants: [Restaurant] = []
    @Published var currentRecommendation: Restaurant?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var favoriteRestaurants: [Restaurant] = []
    @Published var downvotedRestaurants: [Restaurant] = []
    
    private let locationManager: LocationManager
    private var cancellables = Set<AnyCancellable>()
    private let naverMapService = NaverMapService()
    
    init(locationManager: LocationManager) {
        self.locationManager = locationManager
        
        // Load sample data immediately
        loadSampleData()
        
        // Subscribe to location updates
        locationManager.$location
            .compactMap { $0 }
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.fetchRestaurants()
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
                        self.restaurants = restaurants
                    }
                    self.isLoading = false
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
                        imageURL: nil as URL?,
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
                    imageURL: nil as URL?,
                    phoneNumber: nil as String?,
                    operatingHours: nil as String?,
                    description: nil as String?
                )
            ]
            self.isLoading = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: workItem)
    }
    
    func likeRestaurant(_ restaurant: Restaurant? = nil) {
        guard let restaurant = restaurant ?? currentRecommendation else { return }
        
        // Remove from downvoted if it exists
        downvotedRestaurants.removeAll { $0.id == restaurant.id }
        
        // Add to favorites if not already there
        if !favoriteRestaurants.contains(where: { $0.id == restaurant.id }) {
            favoriteRestaurants.append(restaurant)
            savePreferences()
        }
        
        print("즐겨찾기 추가: \(restaurant.name)")
    }
    
    func dislikeRestaurant(_ restaurant: Restaurant? = nil) {
        guard let restaurant = restaurant ?? currentRecommendation else { return }
        
        // Remove from favorites if it exists
        favoriteRestaurants.removeAll { $0.id == restaurant.id }
        
        // Add to downvoted if not already there
        if !downvotedRestaurants.contains(where: { $0.id == restaurant.id }) {
            downvotedRestaurants.append(restaurant)
            savePreferences()
        }
        
        print("비추천 추가: \(restaurant.name)")
    }
    
    func isRestaurantFavorite(_ restaurant: Restaurant) -> Bool {
        return favoriteRestaurants.contains(where: { $0.id == restaurant.id })
    }
    
    func isRestaurantDownvoted(_ restaurant: Restaurant) -> Bool {
        return downvotedRestaurants.contains(where: { $0.id == restaurant.id })
    }
} 