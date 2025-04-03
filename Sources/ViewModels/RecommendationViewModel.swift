import Foundation
import Combine
import CoreLocation

class RecommendationViewModel: ObservableObject {
    @Published var currentRestaurant: Restaurant?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let locationManager: LocationManager
    private let mapService: NaverMapService
    
    init(locationManager: LocationManager) {
        self.locationManager = locationManager
        self.mapService = NaverMapService()
    }
    
    func getRecommendation() {
        isLoading = true
        
        guard let location = locationManager.location else {
            // 위치 정보가 없는 경우 임시 데이터 사용
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.currentRestaurant = Restaurant(
                    id: "1",
                    name: "맛있는 돈까스",
                    address: "서울시 강남구 테헤란로 123",
                    category: "일식",
                    priceRange: .medium,
                    rating: 4.5,
                    latitude: 37.5665,
                    longitude: 126.9780
                )
                self.isLoading = false
            }
            return
        }
        
        mapService.searchRestaurants(near: location)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] restaurants in
                    guard let restaurant = restaurants.randomElement() else {
                        self?.errorMessage = "주변에 음식점이 없습니다."
                        return
                    }
                    self?.currentRestaurant = restaurant
                }
            )
            .store(in: &cancellables)
    }
    
    func likeRestaurant() {
        // TODO: 선호도 저장 구현
        print("좋아요: \(currentRestaurant?.name ?? "")")
    }
    
    func dislikeRestaurant() {
        // TODO: 선호도 저장 구현
        print("싫어요: \(currentRestaurant?.name ?? "")")
    }
} 