import Flutter
import UIKit
import Firebase
import ScreenProtectorKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var screenshotChannel: FlutterMethodChannel?
  private var screenProtectorKit: ScreenProtectorKit?
  private var secureTextField: UITextField?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Firebase
    FirebaseApp.configure()
    
    // Request notification permissions
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { _, _ in }
      )
    } else {
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }
    
    application.registerForRemoteNotifications()
    
    GeneratedPluginRegistrant.register(with: self)
    
    // Setup screenshot detection and protection after window is ready
    DispatchQueue.main.async { [weak self] in
      guard let self = self,
            let window = self.window,
            let controller = window.rootViewController as? FlutterViewController else {
        return
      }
      
      // Initialize ScreenProtectorKit and configure prevention
      self.screenProtectorKit = ScreenProtectorKit(window: window)
      self.screenProtectorKit?.configurePreventionScreenshot()
      print("🔒 [iOS] ScreenProtectorKit configured")
      
      // Enable protection immediately
      self.screenProtectorKit?.enabledPreventScreenshot()
      print("🔒 [iOS] Screenshot prevention enabled at launch")
      
      // Also set up our own secure text field overlay as backup
      self.setupSecureTextFieldOverlay(window: window)
      
      self.screenshotChannel = FlutterMethodChannel(
        name: "com.nookly.app/screenshot_detection",
        binaryMessenger: controller.binaryMessenger
      )
      
      // Listen for screenshot notifications
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(self.userDidTakeScreenshot),
        name: UIApplication.userDidTakeScreenshotNotification,
        object: nil
      )
      
      // Listen for screen recording notifications (iOS 11+)
      if #available(iOS 11.0, *) {
        NotificationCenter.default.addObserver(
          self,
          selector: #selector(self.screenRecordingChanged),
          name: UIScreen.capturedDidChangeNotification,
          object: nil
        )
        
        // Check initial state
        let isRecording = UIScreen.main.isCaptured
        if isRecording {
          self.handleScreenRecording(isRecording: true)
        }
      }
      
      print("📸 [iOS] Screenshot detection channel setup complete")
      print("🎥 [iOS] Screen recording detection enabled")
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  @objc private func userDidTakeScreenshot() {
    // This notification fires AFTER a screenshot is taken
    // If protection is working, this should NOT fire
    // If protection is NOT working, this WILL fire
    print("📸 [iOS] Screenshot detected! This means protection may not be working.")
    
    // Send to Flutter
    screenshotChannel?.invokeMethod("screenshotDetected", arguments: [
      "timestamp": Date().timeIntervalSince1970,
      "message": "Screenshot was taken - protection may have failed"
    ])
  }
  
  @available(iOS 11.0, *)
  @objc private func screenRecordingChanged() {
    let isRecording = UIScreen.main.isCaptured
    handleScreenRecording(isRecording: isRecording)
  }
  
  @available(iOS 11.0, *)
  private func handleScreenRecording(isRecording: Bool) {
    if isRecording {
      print("🎥 [iOS] Screen recording STARTED! Protection may not be working.")
      
      // Send to Flutter
      screenshotChannel?.invokeMethod("screenRecordingDetected", arguments: [
        "timestamp": Date().timeIntervalSince1970,
        "isRecording": true,
        "message": "Screen recording started - protection may have failed"
      ])
    } else {
      print("🎥 [iOS] Screen recording STOPPED")
      
      // Send to Flutter
      screenshotChannel?.invokeMethod("screenRecordingDetected", arguments: [
        "timestamp": Date().timeIntervalSince1970,
        "isRecording": false,
        "message": "Screen recording stopped"
      ])
    }
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  // Handle FCM token
  override func application(_ application: UIApplication, 
                            didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    // Pass device token to Firebase
    // This will be handled by the Firebase SDK automatically
  }
  
  override func application(_ application: UIApplication,
                            didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("Failed to register for remote notifications: \(error.localizedDescription)")
  }
  
  // Setup secure text field overlay for screenshot prevention
  private func setupSecureTextFieldOverlay(window: UIWindow) {
    // Remove existing overlay if any
    secureTextField?.removeFromSuperview()
    
    // Create a new secure text field
    let textField = UITextField()
    textField.isSecureTextEntry = true
    textField.isUserInteractionEnabled = false
    textField.translatesAutoresizingMaskIntoConstraints = false
    textField.alpha = 0.01 // Nearly invisible but still functional
    
    window.addSubview(textField)
    
    // Make it cover the entire window
    NSLayoutConstraint.activate([
      textField.topAnchor.constraint(equalTo: window.topAnchor),
      textField.leadingAnchor.constraint(equalTo: window.leadingAnchor),
      textField.trailingAnchor.constraint(equalTo: window.trailingAnchor),
      textField.bottomAnchor.constraint(equalTo: window.bottomAnchor)
    ])
    
    // Bring to front to ensure it's on top
    window.bringSubviewToFront(textField)
    
    secureTextField = textField
    print("🔒 [iOS] Secure text field overlay configured")
  }
  
  // Re-enable screenshot protection when app becomes active
  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    screenProtectorKit?.enabledPreventScreenshot()
    
    // Re-enable our secure text field
    secureTextField?.isSecureTextEntry = true
    if let window = window {
      setupSecureTextFieldOverlay(window: window)
    }
    
    print("🔒 [iOS] Screenshot prevention re-enabled (app became active)")
  }
  
  // Optionally disable when app goes to background (though we keep it enabled)
  // override func applicationWillResignActive(_ application: UIApplication) {
  //   super.applicationWillResignActive(application)
  //   screenProtectorKit?.disablePreventScreenshot()
  // }
}
