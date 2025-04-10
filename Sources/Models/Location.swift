import Foundation
import CoreLocation

struct Location {
    let latitude: Double
    let longitude: Double
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

extension CLLocationCoordinate2D {
    var location: Location {
        Location(latitude: latitude, longitude: longitude)
    }
} 