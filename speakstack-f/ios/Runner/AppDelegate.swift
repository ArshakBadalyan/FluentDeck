import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    #if DEBUG
    // Scheme flags like -FIRAnalyticsDebugEnabled are not passed when the app is
    // started via `flutter run` (only when Run is started from Xcode). DebugView
    // needs measurement debug mode set before Firebase initializes from Dart.
    let defaults = UserDefaults.standard
    defaults.set(true, forKey: "/google/measurement/debug_mode")
    defaults.set(true, forKey: "/google/firebase/debug_mode")
    defaults.synchronize()
    #endif
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
