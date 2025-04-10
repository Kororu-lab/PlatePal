import SwiftUI
import CoreLocation

struct SettingsView: View {
    @AppStorage("priceRange") private var priceRange: PriceRange = .medium
    @AppStorage("maxDistance") private var maxDistance: Double = 2000
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Preferences")) {
                    Picker("Price Range", selection: $priceRange) {
                        ForEach(PriceRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Maximum Distance: \(Int(maxDistance))m")
                        Slider(value: $maxDistance, in: 500...5000, step: 100)
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
} 