import Foundation
import Combine
import CoreLocation
import NMapsMap

class RecommendationViewModel: ObservableObject {
    @Published var restaurants: [Restaurant] = []
    @Published var currentRecommendation: Restaurant?
    @Published var isLoading = false
    @Published var error: Error?
    
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
    }
    
    private func loadSampleData() {
        // Load sample data immediately so map has something to display
        restaurants = [
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
                phoneNumber: "02-123-4567",
                operatingHours: "10:00 - 22:00",
                description: "맛있는 돈까스 전문점"
            ),
            Restaurant(
                id: "2",
                name: "서울 냉면",
                address: "서울시 강남구 강남대로 456",
                category: "한식",
                rating: 4.7,
                reviewCount: 85,
                priceRange: .medium,
                location: CLLocationCoordinate2D(latitude: 37.5645, longitude: 126.9810),
                imageURL: nil,
                phoneNumber: "02-345-6789",
                operatingHours: "11:00 - 21:00",
                description: "시원한 냉면 전문점"
            ),
            Restaurant(
                id: "3",
                name: "스시 하우스",
                address: "서울시 강남구 선릉로 789",
                category: "일식",
                rating: 4.8,
                reviewCount: 200,
                priceRange: .premium,
                location: CLLocationCoordinate2D(latitude: 37.5685, longitude: 126.9760),
                imageURL: nil,
                phoneNumber: "02-567-8901",
                operatingHours: "12:00 - 22:00",
                description: "신선한 초밥과 사시미"
            )
        ]
    }
    
    func fetchRestaurants() {
        guard let location = locationManager.location?.coordinate else { return }
        
        isLoading = true
        error = nil
        
        Task {
            do {
                let restaurants = try await naverMapService.searchRestaurants(
                    query: "음식점",
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
    
    func likeRestaurant() {
        // TODO: Implement preference saving
        print("좋아요: \(restaurants.first?.name ?? "")")
    }
    
    func dislikeRestaurant() {
        // TODO: Implement preference saving
        print("싫어요: \(restaurants.first?.name ?? "")")
    }
} 