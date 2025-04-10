import Foundation
import CoreLocation

struct Restaurant: Identifiable, Codable {
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
    
    enum PriceRange: String, CaseIterable, Codable {
        case budget = "Budget"
        case medium = "Medium"
        case premium = "Premium"
    }
    
    // MARK: - Regular Initializer
    
    init(id: String, 
         name: String, 
         address: String, 
         category: String, 
         rating: Double, 
         reviewCount: Int, 
         priceRange: PriceRange, 
         location: CLLocationCoordinate2D, 
         imageURL: URL? = nil, 
         phoneNumber: String? = nil, 
         operatingHours: String? = nil, 
         description: String? = nil) {
        self.id = id
        self.name = name
        self.address = address
        self.category = category
        self.rating = rating
        self.reviewCount = reviewCount
        self.priceRange = priceRange
        self.location = location
        self.imageURL = imageURL
        self.phoneNumber = phoneNumber
        self.operatingHours = operatingHours
        self.description = description
    }
    
    // MARK: - Codable Implementation
    
    enum CodingKeys: String, CodingKey {
        case id, name, address, category, rating, reviewCount, priceRange
        case latitude, longitude // For location
        case imageURL, phoneNumber, operatingHours, description
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        address = try container.decode(String.self, forKey: .address)
        category = try container.decode(String.self, forKey: .category)
        rating = try container.decode(Double.self, forKey: .rating)
        reviewCount = try container.decode(Int.self, forKey: .reviewCount)
        priceRange = try container.decode(PriceRange.self, forKey: .priceRange)
        
        // Decode location coordinates
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        imageURL = try container.decodeIfPresent(URL.self, forKey: .imageURL)
        phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
        operatingHours = try container.decodeIfPresent(String.self, forKey: .operatingHours)
        description = try container.decodeIfPresent(String.self, forKey: .description)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(address, forKey: .address)
        try container.encode(category, forKey: .category)
        try container.encode(rating, forKey: .rating)
        try container.encode(reviewCount, forKey: .reviewCount)
        try container.encode(priceRange, forKey: .priceRange)
        
        // Encode location coordinates separately
        try container.encode(location.latitude, forKey: .latitude)
        try container.encode(location.longitude, forKey: .longitude)
        
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encodeIfPresent(phoneNumber, forKey: .phoneNumber)
        try container.encodeIfPresent(operatingHours, forKey: .operatingHours)
        try container.encodeIfPresent(description, forKey: .description)
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