import Foundation
import CoreLocation

struct Restaurant: Identifiable, Codable {
    let id: String
    let name: String
    let address: String
    let category: String
    let priceRange: PriceRange
    let rating: Double
    let latitude: Double
    let longitude: Double
    var userRating: Int?
    var userReview: String?
    var lastVisited: Date?
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    enum PriceRange: String, Codable {
        case low = "저렴"
        case medium = "보통"
        case high = "고급"
    }
}

// MARK: - User Preference
extension Restaurant {
    struct UserPreference: Codable {
        let restaurantId: String
        let isLiked: Bool
        let timestamp: Date
    }
} 