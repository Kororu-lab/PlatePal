import SwiftUI

struct RecommendationView: View {
    @StateObject private var viewModel: RecommendationViewModel
    @State private var isShaking = false
    
    init(locationManager: LocationManager) {
        _viewModel = StateObject(wrappedValue: RecommendationViewModel(locationManager: locationManager))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    ProgressView("추천 중...")
                } else if let restaurant = viewModel.currentRestaurant {
                    VStack(spacing: 20) {
                        // 음식점 정보 카드
                        RestaurantCard(restaurant: restaurant)
                            .padding()
                        
                        // 액션 버튼
                        HStack(spacing: 30) {
                            ActionButton(title: "싫어요", icon: "xmark.circle.fill", color: .red) {
                                viewModel.dislikeRestaurant()
                                viewModel.getRecommendation()
                            }
                            
                            ActionButton(title: "먹을게요", icon: "heart.circle.fill", color: .green) {
                                viewModel.likeRestaurant()
                                viewModel.getRecommendation()
                            }
                        }
                        .padding(.bottom, 30)
                    }
                } else {
                    VStack {
                        Text("흔들어서 추천받기")
                            .font(.title2)
                            .foregroundColor(.gray)
                        
                        Image(systemName: "iphone.radiowaves.left.and.right")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                            .rotationEffect(.degrees(isShaking ? 15 : -15))
                            .animation(
                                Animation.easeInOut(duration: 0.5)
                                    .repeatForever(autoreverses: true),
                                value: isShaking
                            )
                            .onAppear {
                                isShaking = true
                            }
                    }
                }
            }
            .navigationTitle("오늘의 추천")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.getRecommendation()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .onAppear {
            viewModel.getRecommendation()
        }
    }
}

// MARK: - Supporting Views
struct RestaurantCard: View {
    let restaurant: Restaurant
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(restaurant.name)
                .font(.title)
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
            VStack {
                Image(systemName: icon)
                    .font(.system(size: 40))
                Text(title)
                    .font(.headline)
            }
            .foregroundColor(color)
        }
    }
} 