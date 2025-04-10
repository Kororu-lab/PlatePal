import SwiftUI
import NMapsMap
import CoreLocation

// MARK: - Main View
struct RecommendationView: View {
    @StateObject private var viewModel: RecommendationViewModel
    @StateObject private var locationManager: LocationManager
    
    init(locationManager: LocationManager) {
        _locationManager = StateObject(wrappedValue: locationManager)
        _viewModel = StateObject(wrappedValue: RecommendationViewModel(locationManager: locationManager))
    }
    
    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.error {
                Text(error.localizedDescription)
                    .foregroundColor(.red)
            } else if let restaurant = viewModel.restaurants.first {
                VStack {
                    Spacer()
                    
                    // Restaurant Card
                    RestaurantCard(restaurant: restaurant)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    // Action Buttons
                    HStack(spacing: 60) {
                        ActionButton(
                            title: "Skip",
                            icon: "xmark.circle.fill",
                            color: .gray
                        ) {
                            viewModel.dislikeRestaurant()
                            viewModel.getRecommendation()
                        }
                        
                        ActionButton(
                            title: "Like",
                            icon: "heart.circle.fill",
                            color: .red
                        ) {
                            viewModel.likeRestaurant()
                            viewModel.getRecommendation()
                        }
                    }
                    .padding(.bottom, 30)
                }
            } else {
                VStack {
                    Text("No more restaurants")
                        .font(.title)
                    Button("Start Over") {
                        viewModel.fetchRecommendations()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
        .onAppear {
            locationManager.requestLocation()
            viewModel.fetchRecommendations()
        }
    }
}

// MARK: - Supporting Views

struct MapView: UIViewRepresentable {
    let coordinate: CLLocationCoordinate2D
    
    func makeUIView(context: Context) -> NMFNaverMapView {
        let mapView = NMFNaverMapView()
        mapView.showZoomControls = false
        return mapView
    }
    
    func updateUIView(_ uiView: NMFNaverMapView, context: Context) {
        // Set camera position to restaurant location
        let cameraUpdate = NMFCameraUpdate(scrollTo: NMGLatLng(lat: coordinate.latitude, lng: coordinate.longitude))
        cameraUpdate.animation = .easeIn
        uiView.mapView.moveCamera(cameraUpdate)
        
        // Add marker for restaurant location
        let marker = NMFMarker()
        marker.position = NMGLatLng(lat: coordinate.latitude, lng: coordinate.longitude)
        marker.mapView = uiView.mapView
    }
}

struct RestaurantCard: View {
    let restaurant: Restaurant
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Map View
            MapView(coordinate: restaurant.coordinate)
                .frame(height: 200)
                .cornerRadius(15)
            
            // Restaurant Info
            VStack(alignment: .leading, spacing: 8) {
                Text(restaurant.name)
                    .font(.title2)
                    .bold()
                
                HStack {
                    Label(restaurant.category, systemImage: "fork.knife")
                    Spacer()
                    Label(restaurant.priceRange.rawValue, systemImage: "dollarsign.circle")
                }
                .foregroundColor(.gray)
                
                Text(restaurant.address)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack {
                    Label(String(format: "%.1f", restaurant.rating), systemImage: "star.fill")
                        .foregroundColor(.yellow)
                    Spacer()
                    if let userRating = restaurant.userRating {
                        Label("\(userRating)점", systemImage: "person.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 44))
                Text(title)
                    .font(.callout)
                    .bold()
            }
            .foregroundColor(color)
        }
    }
} 