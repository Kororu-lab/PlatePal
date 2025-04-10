import Foundation
import CoreLocation

enum PriceRange: String {
    case low = "$"
    case medium = "$$"
    case high = "$$$"
    case veryHigh = "$$$$"
}

struct Restaurant: Identifiable {
    let id: UUID
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let category: String
    let priceRange: PriceRange
    let rating: Double
    var userRating: Double?
    
    init(id: UUID = UUID(), 
         name: String, 
         address: String, 
         latitude: Double, 
         longitude: Double, 
         category: String = "음식점",
         priceRange: PriceRange, 
         rating: Double,
         userRating: Double? = nil) {
        self.id = id
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.category = category
        self.priceRange = priceRange
        self.rating = rating
        self.userRating = userRating
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
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