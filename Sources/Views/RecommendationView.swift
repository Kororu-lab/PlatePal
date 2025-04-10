import SwiftUI
import NMapsMap
import CoreLocation

struct RecommendationView: View {
    @ObservedObject var viewModel: RecommendationViewModel
    let locationManager: LocationManager
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                // Explicitly set frame to full size
                MapView(viewModel: viewModel, locationManager: locationManager)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.all)
                    .background(Color.white) // Solid background color
                    .overlay( // Add border at bottom
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color.gray)
                            .offset(y: 0),
                        alignment: .bottom
                    )
                
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
                        Text("식당 추천")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.bottom)
                }
            }
            .navigationTitle("맛집 추천")
            .background(Color.white) // Add background to whole view
        }
    }
}

// MARK: - Supporting Views
struct MapView: UIViewRepresentable {
    @ObservedObject var viewModel: RecommendationViewModel
    let locationManager: LocationManager
    
    // Store markers in a class wrapper to avoid mutating struct issues
    class MarkerStore {
        var markers: [NMFMarker] = []
        
        func clearMarkers() {
            for marker in markers {
                marker.mapView = nil
            }
            markers.removeAll()
        }
        
        func addMarker(_ marker: NMFMarker) {
            markers.append(marker)
        }
    }
    
    // Use a reference type to store markers
    let markerStore = MarkerStore()
    
    func makeUIView(context: Context) -> NMFNaverMapView {
        // Pre-initialize map view for faster loading
        let mapView = NMFNaverMapView(frame: UIScreen.main.bounds)
        
        // Enable only essential features to speed up loading
        mapView.showZoomControls = false  // Disable initially
        mapView.showCompass = false       // Disable initially
        mapView.showScaleBar = false      // Disable initially
        mapView.showLocationButton = true // Re-enable location button
        
        // Configure map with minimal settings first
        mapView.mapView.positionMode = .normal // Allow positioning
        mapView.mapView.zoomLevel = 15
        mapView.mapView.mapType = .basic
        mapView.mapView.backgroundColor = UIColor.white
        mapView.mapView.layer.isHidden = false
        mapView.mapView.isHidden = false
        
        // Optimize for performance
        mapView.mapView.liteModeEnabled = true  // Enable lite mode for faster loading
        mapView.mapView.isIndoorMapEnabled = false // Disable indoor map initially
        mapView.mapView.contentInset = UIEdgeInsets.zero
        
        // Set delegates
        mapView.mapView.touchDelegate = context.coordinator
        mapView.mapView.addOptionDelegate(delegate: context.coordinator)
        
        // Force immediate position to Gangnam Station
        let gangnamStation = NMGLatLng(lat: 37.498095, lng: 127.027610)
        let immediateUpdate = NMFCameraUpdate(scrollTo: gangnamStation)
        immediateUpdate.animation = .none
        mapView.mapView.moveCamera(immediateUpdate)
        
        print("Setting initial camera position to Gangnam Station")
        
        // Update restaurant markers immediately
        updateRestaurantMarkers(on: mapView.mapView, with: viewModel.restaurants)
        
        // Enable additional features after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            mapView.showZoomControls = true
            mapView.showCompass = true
            mapView.showScaleBar = true
            mapView.mapView.isIndoorMapEnabled = true
            mapView.mapView.liteModeEnabled = false
            
            // Final camera update
            let finalUpdate = NMFCameraUpdate(scrollTo: gangnamStation, zoomTo: 15)
            finalUpdate.animation = .none
            mapView.mapView.moveCamera(finalUpdate)
            print("Final camera position force to Gangnam Station")
        }
        
        return mapView
    }
    
    func updateUIView(_ uiView: NMFNaverMapView, context: Context) {
        // IMPORTANT: Don't move camera to user location here
        // Only update markers
        updateRestaurantMarkers(on: uiView.mapView, with: viewModel.restaurants)
        
        // Force layout and redraw to ensure map is visible
        DispatchQueue.main.async {
            uiView.setNeedsLayout()
            uiView.layoutIfNeeded()
        }
    }
    
    func updateRestaurantMarkers(on mapView: NMFMapView, with restaurants: [Restaurant]) {
        // Remove existing markers
        markerStore.clearMarkers()
        
        print("Updating map with \(restaurants.count) restaurants")
        
        // Add new markers
        for restaurant in restaurants {
            let marker = NMFMarker()
            marker.position = NMGLatLng(lat: restaurant.location.latitude, lng: restaurant.location.longitude)
            marker.captionText = restaurant.name
            marker.mapView = mapView
            
            // Set marker properties
            marker.iconImage = NMF_MARKER_IMAGE_RED // Use built-in marker image
            marker.width = 30
            marker.height = 40
            
            // Add touch handler
            marker.touchHandler = { overlay in
                print("Restaurant marker tapped: \(restaurant.name)")
                return true
            }
            
            // Store the marker
            markerStore.addMarker(marker)
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
            super.init()
            print("Map coordinator initialized")
        }
        
        // Map touch delegate
        func mapView(_ mapView: NMFMapView, didTapMap latlng: NMGLatLng, point: CGPoint) {
            print("Map tapped at \(latlng.lat), \(latlng.lng)")
        }
        
        // Map option delegate for additional configuration
        func mapViewOptionChanged(_ mapView: NMFMapView) {
            print("Map options changed")
            
            // Force a refresh of the map view
            DispatchQueue.main.async {
                mapView.setNeedsDisplay()
                
                // Log current map state to debug
                print("Map is hidden: \(mapView.isHidden)")
                print("Map layer is hidden: \(mapView.layer.isHidden)")
                print("Map type: \(mapView.mapType.rawValue)")
                print("Map frame: \(mapView.frame)")
            }
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
