import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  var pulseService: MultipeerPulse?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      
    if #available(iOS 14.0, *) {
        pulseService = MultipeerPulse()
    }

    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let pulseChannel = FlutterMethodChannel(name: "com.aether.pulse/nan",
                                              binaryMessenger: controller.binaryMessenger)
    
    pulseChannel.setMethodCallHandler({ [weak self]
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        
      if call.method == "startPulse" {
          if let args = call.arguments as? [String: Any],
             let payloadData = args["payload"] as? FlutterStandardTypedData {
              
              if #available(iOS 14.0, *) {
                  self?.pulseService?.startPulse(encryptedPayload: payloadData.data)
                  result(nil)
              } else {
                  result(FlutterError(code: "UNSUPPORTED", message: "Requires iOS 14.0+", details: nil))
              }
          } else {
              result(FlutterError(code: "INVALID_PAYLOAD", message: "Missing payload", details: nil))
          }
      } else if call.method == "stopPulse" {
          if #available(iOS 14.0, *) {
              self?.pulseService?.stopPulse()
          }
          result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
