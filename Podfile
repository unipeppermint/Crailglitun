source 'https://cdn.cocoapods.org/'

platform :ios, '15.0'

target 'Crailglitun' do
  use_frameworks! :linkage => :static

  pod 'AppsFlyerFramework', '~> 7.0.4'
  pod 'FirebaseCore', '~> 12.19.3'
  pod 'FirebaseAuth', '~> 12.19.0'
  pod 'FirebaseMessaging', '~> 12.19.0'
  pod 'FirebaseStorage', '~> 12.19.0'
  pod 'GoogleSignIn', '~> 10.1.0'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |configuration|
      configuration.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    end
  end
end
