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
                    self.restaurants = restaurants
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
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