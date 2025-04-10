platform :ios, '15.0'

target 'PlatePal' do
  use_frameworks!

  # Pods for PlatePal
  pod 'NMapsMap'
  pod 'naveridlogin-sdk-ios'
end

# Fix deployment target warnings in Pods
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # Set minimum deployment target to iOS 12.0 for all pods
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end 