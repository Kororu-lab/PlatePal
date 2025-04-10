import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus?
    @Published var error: Error?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update when user moves 10 meters
        
        // Request location authorization immediately
        requestLocation()
        
        // Set default location in case permission is denied
        if location == nil {
            // Default to Seoul City Hall coordinates
            self.location = CLLocation(latitude: 37.5666791, longitude: 126.9782914)
        }
    }
    
    func requestLocation() {
        let status = locationManager.authorizationStatus
        
        print("LocationManager: Current authorization status: \(status.rawValue)")
        
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            print("LocationManager: Location access restricted or denied")
            // Use default location set in init
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        @unknown default:
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        print("LocationManager: Location updated to \(location.coordinate.latitude), \(location.coordinate.longitude)")
        self.location = location
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("LocationManager: Authorization status changed to \(status.rawValue)")
        self.authorizationStatus = status
        
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager: Failed with error: \(error.localizedDescription)")
        self.error = error
        
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                // Use default location
                print("LocationManager: Location updates denied by user")
            default:
                break
            }
        }
    }
} 