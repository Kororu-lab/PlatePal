import Foundation
import CoreLocation
import Combine
import NMapsMap

// Config definition moved into this file since we're having module import issues
private enum Config {
    enum NaverMap {
        static let clientId = "dnljlxygz6"
        static let clientSecret = "liEUTZYxky7Rzsnl5GYmWPIcKzlt6nvDieSdFV96"
    }
}

class NaverMapService {
    static let shared = NaverMapService()
    
    private init() {}
    
    private let clientId = Config.NaverMap.clientId
    private let clientSecret = Config.NaverMap.clientSecret
    
    func setupNaverMap() {
        // Initialize Naver Maps SDK
        NMFAuthManager.shared().clientId = clientId
    }
    
    func createMarker(at coordinate: CLLocationCoordinate2D, title: String) -> NMFMarker {
        let marker = NMFMarker()
        marker.position = NMGLatLng(lat: coordinate.latitude, lng: coordinate.longitude)
        marker.captionText = title
        return marker
    }
    
    func searchRestaurants(near location: CLLocation) -> AnyPublisher<[Restaurant], Error> {
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        let urlString = "https://openapi.naver.com/v1/search/local.json?query=음식점&display=20&start=1&sort=random&coords=\(longitude),\(latitude)&radius=2000"
        
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.addValue(clientId, forHTTPHeaderField: "X-Naver-Client-Id")
        request.addValue(clientSecret, forHTTPHeaderField: "X-Naver-Client-Secret")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: NaverSearchResponse.self, decoder: JSONDecoder())
            .map { response -> [Restaurant] in
                response.items.map { item in
                    Restaurant(
                        id: UUID(),
                        name: item.title.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression),
                        address: item.address,
                        latitude: Double(item.mapx) ?? 0,
                        longitude: Double(item.mapy) ?? 0,
                        category: item.category,
                        priceRange: .medium,  // Default to medium price range
                        rating: Double.random(in: 3.5...4.8)
                    )
                }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - API Response Models
struct NaverSearchResponse: Codable {
    let items: [NaverLocalItem]
}

struct NaverLocalItem: Codable {
    let title: String
    let link: String
    let category: String
    let description: String
    let address: String
    let roadAddress: String
    let mapx: String
    let mapy: String
    
    enum CodingKeys: String, CodingKey {
        case title, link, category, description
        case address, roadAddress, mapx, mapy
    }
} 