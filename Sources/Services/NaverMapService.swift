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

enum NetworkError: Error {
    case decodingError(String)
    case apiError(String)
    case other(Error)
}

class NaverMapService {
    private let ncpClientId: String
    private var isInitialized = false
    
    // Static initializer to ensure SDK is ready before any map views are created
    static let shared = NaverMapService()
    
    init() {
        self.ncpClientId = "dnljlxygz6"
        
        // Force SDK initialization immediately with both keys for backup
        NMFAuthManager.shared().ncpKeyId = self.ncpClientId
        
        // Log initialization status
        print("Initializing NaverMapService with NCP Key ID: \(ncpClientId)")
        
        // Force the SDK to perform an operation that will trigger initialization
        DispatchQueue.main.async {
            // Add authorization check
            let authManager = NMFAuthManager.shared()
            print("Starting Naver Maps SDK initialization")
            
            // Trigger a dummy operation to ensure the SDK is fully initialized
            let dummyMap = NMFMapView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
            dummyMap.mapType = .basic
            
            print("Naver Maps SDK initialization complete")
        }
    }
    
    private let clientId = Config.NaverMap.clientId
    private let clientSecret = Config.NaverMap.clientSecret
    
    func createMarker(at coordinate: CLLocationCoordinate2D, title: String) -> NMFMarker {
        let marker = NMFMarker()
        marker.position = NMGLatLng(lat: coordinate.latitude, lng: coordinate.longitude)
        marker.captionText = title
        return marker
    }
    
    func searchRestaurants(query: String = "맛집", location: CLLocationCoordinate2D, radius: Int = 500) async throws -> [Restaurant] {
        // Build Naver Maps Search API URL
        let baseURL = "https://map.naver.com/v5/api/search"
        
        // Default to Gangnam Station if location is outside Korea
        let searchLocation: CLLocationCoordinate2D
        if location.latitude > 33.0 && location.latitude < 38.0 && 
           location.longitude > 124.0 && location.longitude < 132.0 {
            searchLocation = location
        } else {
            // Use Gangnam Station as default
            searchLocation = CLLocationCoordinate2D(latitude: 37.498095, longitude: 127.027610)
            print("Location outside Korea, using Gangnam Station instead")
        }
        
        // Configure the search query
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "type", value: "place"),
            URLQueryItem(name: "searchCoord", value: "\(searchLocation.longitude);\(searchLocation.latitude)"),
            URLQueryItem(name: "displayCount", value: "20"),
            URLQueryItem(name: "isPlaceRecommendation", value: "true"),
            URLQueryItem(name: "lang", value: "ko")
        ]
        
        guard let url = components?.url else {
            throw NetworkError.other(NSError(domain: "URL creation error", code: -1))
        }
        
        // Mock data for testing since we won't actually call the API
        // In a real app, you would make the network request here
        return try await mockSearchResults(for: searchLocation)
    }
    
    private func mockSearchResults(for location: CLLocationCoordinate2D) async throws -> [Restaurant] {
        // Create realistic restaurant data around the given location
        return [
            Restaurant(
                id: UUID().uuidString,
                name: "국수나무 강남점",
                address: "서울 강남구 강남대로 340",
                category: "한식",
                rating: 4.5,
                reviewCount: 120,
                priceRange: .medium,
                location: CLLocationCoordinate2D(latitude: location.latitude + 0.002, longitude: location.longitude - 0.001),
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
                location: CLLocationCoordinate2D(latitude: location.latitude - 0.001, longitude: location.longitude + 0.002),
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
                location: CLLocationCoordinate2D(latitude: location.latitude - 0.002, longitude: location.longitude - 0.002),
                imageURL: nil,
                phoneNumber: "02-555-7890",
                operatingHours: "24시간",
                description: "맛있는 햄버거와 사이드 메뉴를 제공합니다."
            ),
            Restaurant(
                id: UUID().uuidString,
                name: "스타벅스 강남대로점",
                address: "서울 강남구 강남대로 390",
                category: "카페",
                rating: 4.3,
                reviewCount: 310,
                priceRange: .medium,
                location: CLLocationCoordinate2D(latitude: location.latitude + 0.001, longitude: location.longitude + 0.001),
                imageURL: nil,
                phoneNumber: "02-222-3333",
                operatingHours: "07:00 - 22:00",
                description: "편안한 분위기에서 커피를 즐길 수 있는 공간입니다."
            ),
            Restaurant(
                id: UUID().uuidString,
                name: "백소정 강남점",
                address: "서울 강남구 테헤란로 129",
                category: "한식",
                rating: 4.7,
                reviewCount: 420,
                priceRange: .medium,
                location: CLLocationCoordinate2D(latitude: location.latitude + 0.003, longitude: location.longitude - 0.002),
                imageURL: nil,
                phoneNumber: "02-444-5555",
                operatingHours: "11:00 - 22:00",
                description: "한식 퓨전 요리를 맛볼 수 있는 맛집입니다."
            )
        ]
    }
    
    private func fetchRestaurantsFromAPI(query: String, location: CLLocationCoordinate2D) async throws -> [Restaurant] {
        let latitude = location.latitude
        let longitude = location.longitude
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "음식점"
        let urlString = "https://openapi.naver.com/v1/search/local.json?query=\(encodedQuery)&display=20&start=1&sort=random&coords=\(longitude),\(latitude)&radius=2000"
        
        guard let url = URL(string: urlString) else {
            throw NetworkError.apiError("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.addValue(clientId, forHTTPHeaderField: "X-Naver-Client-Id")
        request.addValue(clientSecret, forHTTPHeaderField: "X-Naver-Client-Secret")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Print response for debugging
            if let httpResponse = response as? HTTPURLResponse {
                print("API Response Status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("API Error Response: \(responseString)")
                    }
                    throw NetworkError.apiError("API returned status code: \(httpResponse.statusCode)")
                }
            }
            
            // Print the JSON response for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("API Response: \(jsonString)")
            }
            
            do {
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
            } catch let decodingError as DecodingError {
                let errorDetails = handleDecodingError(decodingError)
                print("JSON Decoding Error: \(errorDetails)")
                throw NetworkError.decodingError(errorDetails)
            }
        } catch {
            if let networkError = error as? NetworkError {
                throw networkError
            } else {
                print("General Error: \(error)")
                throw NetworkError.other(error)
            }
        }
    }
    
    private func handleDecodingError(_ error: DecodingError) -> String {
        switch error {
        case .keyNotFound(let key, let context):
            let path = context.codingPath.map { $0.stringValue }.joined(separator: " -> ")
            return "Missing key '\(key.stringValue)' at path \(path)"
            
        case .typeMismatch(let type, let context):
            let path = context.codingPath.map { $0.stringValue }.joined(separator: " -> ")
            return "Type '\(type)' mismatch at path \(path)"
            
        case .valueNotFound(let type, let context):
            let path = context.codingPath.map { $0.stringValue }.joined(separator: " -> ")
            return "Value of type '\(type)' not found at path \(path)"
            
        case .dataCorrupted(let context):
            let path = context.codingPath.map { $0.stringValue }.joined(separator: " -> ")
            return "Data corrupted at path \(path)"
            
        @unknown default:
            return "Unknown decoding error: \(error.localizedDescription)"
        }
    }
    
    private func createMockRestaurants(near location: CLLocationCoordinate2D) -> [Restaurant] {
        // Create mock restaurants near the provided location
        return [
            Restaurant(
                id: "1",
                name: "맛있는 돈까스",
                address: "서울시 강남구 테헤란로 123",
                category: "일식",
                rating: 4.5,
                reviewCount: 120,
                priceRange: .medium,
                location: CLLocationCoordinate2D(
                    latitude: location.latitude + 0.001,
                    longitude: location.longitude + 0.001
                ),
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
                priceRange: .budget,
                location: CLLocationCoordinate2D(
                    latitude: location.latitude - 0.001,
                    longitude: location.longitude + 0.002
                ),
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
                location: CLLocationCoordinate2D(
                    latitude: location.latitude + 0.002,
                    longitude: location.longitude - 0.001
                ),
                imageURL: nil,
                phoneNumber: "02-567-8901",
                operatingHours: "12:00 - 22:00",
                description: "신선한 초밥과 사시미"
            )
        ]
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