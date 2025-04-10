import Foundation
import Combine
import CoreLocation
import NMapsMap

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
            
        // Load saved favorites and downvoted restaurants
        loadSavedPreferences()
    }
    
    private func loadSampleData() {
        // Sample data - all restaurants located in Gangnam, Seoul
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
        currentRecommendation = restaurants.randomElement()
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
                        phoneNumber: nil,
                        operatingHours: nil,
                        description: nil
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
                    phoneNumber: nil,
                    operatingHours: nil,
                    description: nil
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