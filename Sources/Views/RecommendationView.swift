import SwiftUI
import NMapsMap
import CoreLocation

struct RecommendationView: View {
    @ObservedObject var viewModel: RecommendationViewModel
    let locationManager: LocationManager
    
    var body: some View {
        NavigationView {
            ZStack {
                MapView(viewModel: viewModel, locationManager: locationManager)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Spacer()
                    
                    if let recommendation = viewModel.currentRecommendation {
                        RecommendationCard(restaurant: recommendation)
                            .padding()
                            .transition(.move(edge: .bottom))
                    }
                    
                    Button(action: {
                        viewModel.recommendRestaurant()
                    }) {
                        Text("Recommend Restaurant")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.bottom)
                }
            }
            .navigationTitle("Restaurant Recommendations")
        }
    }
}

// MARK: - Supporting Views
struct MapView: UIViewRepresentable {
    @ObservedObject var viewModel: RecommendationViewModel
    let locationManager: LocationManager
    
    func makeUIView(context: Context) -> NMFNaverMapView {
        let mapView = NMFNaverMapView()
        mapView.showZoomControls = true
        mapView.showCompass = true
        mapView.showScaleBar = true
        mapView.showLocationButton = true
        
        // Configure map
        mapView.mapView.positionMode = .direction
        mapView.mapView.zoomLevel = 15
        
        // Set auth failure handler for debugging
        #if DEBUG
        mapView.mapView.touchDelegate = context.coordinator
        mapView.mapView.addOptionDelegate(context.coordinator)
        // Handle auth failure
        mapView.mapView.authFailureHandler = { error in
            print("Naver Map auth failed: \(error.localizedDescription)")
        }
        #endif
        
        // Set initial camera position to user's location if available
        if let location = locationManager.location {
            let coord = NMGLatLng(lat: location.coordinate.latitude, lng: location.coordinate.longitude)
            let cameraUpdate = NMFCameraUpdate(scrollTo: coord)
            mapView.mapView.moveCamera(cameraUpdate)
            
            // Add marker for current location
            let marker = NMFMarker()
            marker.position = coord
            marker.mapView = mapView.mapView
            marker.iconImage = NMFOverlayImage(name: "marker") // Use a custom marker or built-in one
            marker.width = 40
            marker.height = 40
        }
        
        // Force render map and layout
        mapView.setNeedsLayout()
        mapView.layoutIfNeeded()
        
        return mapView
    }
    
    func updateUIView(_ uiView: NMFNaverMapView, context: Context) {
        // Update map when location changes
        if let location = locationManager.location {
            let coord = NMGLatLng(lat: location.coordinate.latitude, lng: location.coordinate.longitude)
            
            // Only move camera if location has changed significantly
            let cameraUpdate = NMFCameraUpdate(scrollTo: coord)
            cameraUpdate.animation = .easeIn
            uiView.mapView.moveCamera(cameraUpdate)
            
            // Update restaurants on map
            updateRestaurantMarkers(on: uiView.mapView, with: viewModel.restaurants)
        }
    }
    
    private func updateRestaurantMarkers(on mapView: NMFMapView, with restaurants: [Restaurant]) {
        // Remove existing markers
        mapView.subviews.forEach { view in
            if let marker = view as? NMFMarker {
                marker.mapView = nil
            }
        }
        
        // Add new markers
        for restaurant in restaurants {
            let marker = NMFMarker()
            marker.position = NMGLatLng(lat: restaurant.location.latitude, lng: restaurant.location.longitude)
            marker.captionText = restaurant.name
            marker.mapView = mapView
            
            // Add touch handler
            marker.touchHandler = { overlay in
                print("Restaurant marker tapped: \(restaurant.name)")
                return true
            }
        }
    }
    
    // Coordinator for map delegates
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NMFMapViewTouchDelegate, NMFMapViewOptionDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        // Map touch delegate
        func mapView(_ mapView: NMFMapView, didTapMap latlng: NMGLatLng, point: CGPoint) {
            print("Map tapped at \(latlng.lat), \(latlng.lng)")
        }
        
        // Map option delegate for additional configuration
        func mapViewOptionChanged(_ mapView: NMFMapView) {
            print("Map options changed")
        }
    }
}

struct RecommendationCard: View {
    let restaurant: Restaurant
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(restaurant.name)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(restaurant.address)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            HStack {
                Text(restaurant.category)
                    .font(.caption)
                    .padding(4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", restaurant.rating))
                    Text("(\(restaurant.reviewCount))")
                        .foregroundColor(.gray)
                }
            }
            
            Text(restaurant.priceRange.rawValue)
                .font(.caption)
                .padding(4)
                .background(Color.green.opacity(0.2))
                .cornerRadius(4)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

#Preview {
    let locationManager = LocationManager()
    return RecommendationView(
        viewModel: RecommendationViewModel(locationManager: locationManager),
        locationManager: locationManager
    )
} 
