import SwiftUI
import CoreLocation

struct RestaurantListView: View {
    var body: some View {
        NavigationView {
            List {
                Text("Restaurant List")
            }
            .navigationTitle("Restaurants")
        }
    }
}

struct RestaurantRow: View {
    let restaurant: Restaurant
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(restaurant.name)
                .font(.headline)
            Text(restaurant.address)
                .font(.subheadline)
                .foregroundColor(.gray)
            HStack {
                Text(restaurant.category)
                    .font(.caption)
                Spacer()
                Text(String(format: "%.1f", restaurant.rating))
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    RestaurantListView()
} 