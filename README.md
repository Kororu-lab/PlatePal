# PlatePal - Your Evening Dining Companion

[![Swift](https://img.shields.io/badge/Swift-5.5+-orange.svg)](https://swift.org)
[![Xcode](https://img.shields.io/badge/Xcode-13.0+-blue.svg)](https://developer.apple.com/xcode/)
[![iOS](https://img.shields.io/badge/iOS-15.0+-lightgrey.svg)](https://www.apple.com/ios/)
[![Version](https://img.shields.io/badge/Version-0.1.0-brightgreen.svg)](https://github.com/Kororu-lab/PlatePal)
[![License](https://img.shields.io/badge/license-CC%20BY--NC%204.0-green.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Toy%20Project-success.svg)](https://github.com/Kororu-lab/PlatePal)

PlatePal is an iOS app that recommends restaurants based on your location, making dinner decisions effortless and enjoyable. This is a toy project developed for learning and experimenting with iOS development and location-based services.

## Key Features

- Location-based restaurant recommendations
- Personalized suggestions based on user preferences
- Restaurant upvote/downvote system
- Favorites and blacklist management
- Price range filtering and detailed information
- Korean language support
 
## Tech Stack

- SwiftUI
- Core Location
- Naver Maps API
- UserDefaults for preference storage
- Combine

## App Screens

- **지도 (Map)**: Interactive map showing restaurant locations with recommendation card
- **목록 (List)**: Comprehensive list of nearby restaurants
- **설정 (Settings)**: User preferences, favorites, and downvoted restaurants

## Recent Updates

- Added upvote/downvote functionality for restaurants
- Implemented favorites and downvote lists
- Added Korean language support throughout the app
- Improved recommendation algorithm
- Enhanced UI with consistent button styling

## Requirements

- iOS 15.0 or later
- Xcode 13.0 or later
- Swift 5.5 or later

## Installation

1. Clone the repository
2. Open `PlatePal.xcodeproj` in Xcode
3. Configure the required API keys in `Config.swift`
   - Create a new file named `Config.swift` in the Sources directory
   - Add the following template:
   ```swift
   import Foundation
   
   enum Config {
       enum NaverMap {
           static let clientId = "YOUR_CLIENT_ID_HERE"
           static let clientSecret = "YOUR_CLIENT_SECRET_HERE"
       }
   }
   ```
   - Replace with your actual Naver Maps API credentials
   - This file is in `.gitignore` and will not be committed to Git
4. Build and run

## License

This project is licensed under the Creative Commons Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0).

### Key License Terms:
- Currently restricted to non-commercial use only
- The copyright holder (Kororu-lab) reserves the right to modify the license terms in the future
- Usage of the Naver Maps API is subject to Naver Cloud Platform's terms and conditions

For more details, see the [LICENSE](LICENSE) file.

## Recent Modifications

### Code Organization Updates (April 2024)

1. **Recommendation Engine Integration:**
   - The separate RecommendationEngine class has been integrated directly into RecommendationViewModel
   - This resolves module scope issues and simplifies the codebase

2. **Repository Structure:**
   - Modified .gitignore to include the Pods directory and Xcode workspace
   - These files are now included in the repository to make it easier to run the project on different machines

3. **Build System:**
   - Package.swift has been updated to be compatible with CocoaPods
   - Added clear documentation throughout the code for easier setup

4. **Known Issues:**
   - If you encounter `nil requires a contextual type` errors, make sure to use explicit type annotations (e.g., `nil as URL?`)
   - Some Xcode warnings may appear due to the mix of SwiftUI and UIKit components

## Project Structure

- `Sources/Models/`: Data models
- `Sources/Views/`: SwiftUI views
- `Sources/ViewModels/`: View models for business logic
- `Sources/Services/`: Service classes for APIs and utilities
- `Sources/Resources/`: Assets and resources

## Dependencies

- NMapsMap: For displaying maps and locations
- CoreLocation: For handling location services
- SwiftUI: For the UI framework

## Development Setup Issues

If you encounter any issues during setup:

1. Make sure you're opening the `.xcworkspace` file, not the `.xcodeproj` file
2. Try cleaning the build folder (Shift + Cmd + K in Xcode) and rebuilding
3. If CocoaPods-related issues persist, try removing the Pods directory and running `pod install` again
```bash
rm -rf Pods
pod install
```

4. If you see "Missing file" errors for RecommendationEngine, the functionality has been integrated directly into the RecommendationViewModel. 