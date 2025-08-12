import Flutter
import UIKit

// import GoogleMaps - Commented out as app uses Mapbox

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // GMSServices.provideAPIKey("AIzaSyDm4pEtg6FcmxZf3HIjaL9e5Jevvlc3nCk") - Commented out as app uses Mapbox
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
