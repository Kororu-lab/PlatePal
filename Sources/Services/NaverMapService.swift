import Foundation
import CoreLocation
import NMapsMap

// Config definition moved into this file since we're having module import issues
private enum Config {
    enum NaverMap {
        // NOTE: Make sure this clientId matches the app's Bundle Identifier in Naver Developer Console
        // Error: "Authorize failed: 잘못된 클라이언트 ID를 지정" means the Bundle Identifier doesn't match
        // Your app's Bundle Identifier is: com.platepal.app
        static let clientId = "dnljlxygz6"
        static let clientSecret = "liEUTZYxky7Rzsnl5GYmWPIcKzlt6nvDieSdFV96"
    }
}

class NaverMapService {
    static let shared = NaverMapService()
    
    public init() {
        // Initialize Naver Map with NCP key (updated from deprecated clientId)
        NMFAuthManager.shared().ncpKeyId = Config.NaverMap.clientId
        
        // For debugging auth issues
        print("Initializing NaverMapService with NCP Key ID: \(Config.NaverMap.clientId)")
        
        #if DEBUG
        // Note: isAuthenticationFailed no longer exists, cannot disable auth failures directly
        // For dev/testing, you can use NMFNaverMapView.authFailureHandler to handle auth failures
        #endif
    }
    
    private let clientId = Config.NaverMap.clientId
    private let clientSecret = Config.NaverMap.clientSecret
    
    func createMarker(at coordinate: CLLocationCoordinate2D, title: String) -> NMFMarker {
        let marker = NMFMarker()
        marker.position = NMGLatLng(lat: coordinate.latitude, lng: coordinate.longitude)
        marker.captionText = title
        return marker
    }
    
    func searchRestaurants(query: String, location: CLLocationCoordinate2D) async throws -> [Restaurant] {
        let latitude = location.latitude
        let longitude = location.longitude
        let urlString = "https://openapi.naver.com/v1/search/local.json?query=\(query)&display=20&start=1&sort=random&coords=\(longitude),\(latitude)&radius=2000"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.addValue(clientId, forHTTPHeaderField: "X-Naver-Client-Id")
        request.addValue(clientSecret, forHTTPHeaderField: "X-Naver-Client-Secret")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(NaverSearchResponse.self, from: data)
        
        return response.items.map { item in
            Restaurant(
                id: UUID().uuidString,
                name: item.title.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression),
                address: item.address,
                category: item.category,
                rating: Double.random(in: 3.5...4.8),
                reviewCount: Int.random(in: 10...200),
                priceRange: .medium,
                location: CLLocationCoordinate2D(
                    latitude: Double(item.mapy) ?? 0,
                    longitude: Double(item.mapx) ?? 0
                ),
                imageURL: nil,
                phoneNumber: nil,
                operatingHours: nil,
                description: nil
            )
        }
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