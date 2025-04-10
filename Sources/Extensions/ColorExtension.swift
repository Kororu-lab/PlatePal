import SwiftUI

extension Color {
    static let platepalAccent = Color(red: 0, green: 0.478, blue: 1.0)
    static let platepalBackground = Color.white
    static let platepalCard = Color(white: 0.97)
    
    static var dynamicBackground: Color {
        #if os(iOS)
        return Color(.systemBackground)
        #else
        return Color.white
        #endif
    }
} 