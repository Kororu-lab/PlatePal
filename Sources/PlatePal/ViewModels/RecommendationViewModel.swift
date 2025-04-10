import Foundation
import Combine
import CoreLocation

class RecommendationViewModel: ObservableObject {
    @Published var restaurants: [Restaurant] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let locationManager: LocationManager
    private var cancellables = Set<AnyCancellable>()
    
    init(locationManager: LocationManager) {
        self.locationManager = locationManager
    }
    
    func fetchRecommendations() {
        guard let location = locationManager.location else { return }
        
        isLoading = true
        
        // Simulated API call - replace with actual API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.restaurants = [
                Restaurant(name: "Sample Restaurant 1",
                          address: "123 Main St",
                          latitude: location.coordinate.latitude + 0.001,
                          longitude: location.coordinate.longitude + 0.001,
                          category: "American",
                          priceRange: .medium,
                          rating: 4.5),
                Restaurant(name: "Sample Restaurant 2",
                          address: "456 Oak Ave",
                          latitude: location.coordinate.latitude - 0.001,
                          longitude: location.coordinate.longitude - 0.001,
                          category: "Italian",
                          priceRange: .high,
                          rating: 4.8)
            ]
            self.isLoading = false
        }
    }
    
    func getRecommendation() {
        isLoading = true
        
        guard let location = locationManager.location else {
            // If location is not available, use temporary data
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.restaurants = [
                    Restaurant(name: "맛있는 돈까스",
                              address: "서울시 강남구 테헤란로 123",
                              latitude: 37.5665,
                              longitude: 126.9780,
                              category: "일식",
                              priceRange: .medium,
                              rating: 4.5)
                ]
                self.isLoading = false
            }
            return
        }
        
        // Simulated API call - replace with actual API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.restaurants = [
                Restaurant(name: "맛있는 돈까스",
                          address: "서울시 강남구 테헤란로 123",
                          latitude: location.coordinate.latitude + 0.001,
                          longitude: location.coordinate.longitude + 0.001,
                          category: "일식",
                          priceRange: .medium,
                          rating: 4.5)
            ]
            self.isLoading = false
        }
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