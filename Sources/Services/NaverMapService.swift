import Foundation
import CoreLocation
import Combine

class NaverMapService {
    private let clientId = Config.NaverMap.clientId
    private let clientSecret = Config.NaverMap.clientSecret
    
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
            .map { response in
                response.items.map { item in
                    Restaurant(
                        id: item.id,
                        name: item.title.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression),
                        address: item.address,
                        category: item.category,
                        priceRange: .medium, // 기본값 설정
                        rating: Double.random(in: 3.5...4.8), // 임시 랜덤 평점
                        latitude: Double(item.mapx) ?? 0,
                        longitude: Double(item.mapy) ?? 0
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
    let id: String
    let title: String
    let link: String
    let category: String
    let description: String
    let address: String
    let roadAddress: String
    let mapx: String
    let mapy: String
    
    enum CodingKeys: String, CodingKey {
        case id = "lastBuildDate"  // 임시로 사용
        case title, link, category, description
        case address, roadAddress, mapx, mapy
    }
} 