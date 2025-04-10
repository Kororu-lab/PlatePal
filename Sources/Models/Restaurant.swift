import Foundation
import CoreLocation

struct Restaurant: Identifiable {
    let id: String
    let name: String
    let address: String
    let category: String
    let rating: Double
    let reviewCount: Int
    let priceRange: PriceRange
    let location: CLLocationCoordinate2D
    let imageURL: URL?
    let phoneNumber: String?
    let operatingHours: String?
    let description: String?
    
    enum PriceRange: String, CaseIterable {
        case budget = "Budget"
        case medium = "Medium"
        case premium = "Premium"
    }
}

// MARK: - Sample Data
extension Restaurant {
    static let sampleRestaurants: [Restaurant] = [
        Restaurant(
            id: "1",
            name: "Sample Restaurant 1",
            address: "123 Main St",
            category: "Korean",
            rating: 4.5,
            reviewCount: 100,
            priceRange: .medium,
            location: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
            imageURL: nil,
            phoneNumber: "02-123-4567",
            operatingHours: "10:00 - 22:00",
            description: "A sample restaurant"
        )
    ]
}

// MARK: - User Preference
extension Restaurant {
    struct UserPreference: Codable {
        let restaurantId: String
        let isLiked: Bool
        let timestamp: Date
    }
} 