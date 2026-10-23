import Flutter
import UIKit
import UserNotifications

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
    // Lets flutter_local_notifications show the daily review reminder while
    // the app is open and route taps on it back to Dart.
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
