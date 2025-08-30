import UIKit
import Flutter
import OPPWAMobile

@main
@objc class AppDelegate: FlutterAppDelegate, OPPCheckoutProviderDelegate, OPPThreeDSEventListener {

    // MARK: - Properties
    var flutterChannel: FlutterMethodChannel?
    var transaction: OPPTransaction?
    var paymentProvider: OPPPaymentProvider?
    var checkoutProvider: OPPCheckoutProvider?
    var pendingFlutterResult: FlutterResult?

    // MARK: - Application Launch
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        do {
            // Setup Flutter View Controller and UINavigationController
            let flutterViewController = FlutterViewController()
            let navigationController = UINavigationController(rootViewController: flutterViewController)
            navigationController.setNavigationBarHidden(true, animated: false)

            self.window = UIWindow(frame: UIScreen.main.bounds)
            self.window?.rootViewController = navigationController
            self.window?.makeKeyAndVisible()

            // Setup Method Channel between Flutter and iOS
            flutterChannel = FlutterMethodChannel(
                name: "com.example.nativeflutterdemo1/hyperpay",
                binaryMessenger: flutterViewController.binaryMessenger
            )

            flutterChannel?.setMethodCallHandler { [weak self] call, result in
                guard let self = self else { return }

                do {
                    switch call.method {
                    case "startPayment":
                        // Handle Ready UI Payment
                        guard let args = call.arguments as? [String: Any],
                              let checkoutId = args["checkoutId"] as? String else {
                            result(FlutterError(code: "INVALID", message: "checkoutId missing", details: nil))
                            return
                        }
                        ReadyPaymentHandler.startReadyPayment(checkoutId: checkoutId, delegate: self, flutterResult: result)

                    case "startPaymentCustom":
                        // Handle Custom UI Card Payment
                        guard let args = call.arguments as? [String: Any],
                              let paymentData = args["paymentData"] as? [String: Any] else {
                            result(FlutterError(code: "INVALID", message: "Missing paymentData", details: nil))
                            return
                        }
                        CustomPaymentHandler.startCustomPayment(paymentData: paymentData, delegate: self, flutterResult: result)

                    case "startStcPay":
                        // Handle STC Pay Payment
                        guard let args = call.arguments as? [String: Any],
                              let paymentData = args["paymentData"] as? [String: Any] else {
                            result(FlutterError(code: "INVALID", message: "Missing paymentData", details: nil))
                            return
                        }
                        StcPaymentHandler.startStcPay(paymentData: paymentData, delegate: self, flutterResult: result)

                    case "startApplePay":
                        // Handle Apple Pay Ready UI
                        guard let args = call.arguments as? [String: Any],
                              let checkoutId = args["checkoutId"] as? String else {
                            result(FlutterError(code: "INVALID", message: "Missing checkoutId", details: nil))
                            return
                        }
                        ApplePayHandler.shared.startApplePay(checkoutId: checkoutId, result: result)

                    case "startAppleCustom":
                        // Handle Apple Pay Custom UI
                        guard let args = call.arguments as? [String: Any],
                              let checkoutId = args["checkoutId"] as? String else {
                            result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing checkoutId", details: nil))
                            return
                        }
                        ApplePayCustomHandler.shared.startApplePayCustom(checkoutId: checkoutId, result: result)

                    default:
                        result(FlutterMethodNotImplemented)
                    }
                } catch {
                    // Catch any unexpected errors in method call handling
                    result(FlutterError(code: "METHOD_CALL_FAILED", message: "Unexpected error: \(error.localizedDescription)", details: nil))
                }
            }

            // Register plugins
            GeneratedPluginRegistrant.register(with: self)
        } catch {
            print("❌ Error during application launch: \(error.localizedDescription)")
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // MARK: - 3D Secure Challenge Screen Handling
    func onThreeDSChallengeRequired(completion: @escaping (UINavigationController) -> Void) {
        DispatchQueue.main.async {
            if let nav = self.window?.rootViewController as? UINavigationController {
                print("📲 Presenting 3DS challenge screen...")
                completion(nav)
            } else {
                print("❌ No suitable UINavigationController found for 3DS challenge.")
            }
        }
    }

    // MARK: - 3D Secure Config Handling
    func onThreeDSConfigRequired(completion: @escaping (OPPThreeDSConfig) -> Void) {
        // Return default 3DS config
        completion(OPPThreeDSConfig())
    }

    // MARK: - URL Handling (Apple Pay, STC Pay, etc.)
    override func application(_ app: UIApplication, open url: URL,
                              options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        print("📡 App opened via URL: \(url.absoluteString)")

        if url.scheme == "com.example.nativeflutterdemo1" {
            do {
                // Handle Apple Pay / STC Pay redirect
                if url.absoluteString.contains("id="),
                   let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let queryItems = components.queryItems,
                   let checkoutId = queryItems.first(where: { $0.name == "id" })?.value {

                    let resultMap: [String: Any] = [
                        "status": "success",
                        "checkoutId": checkoutId,
                        "message": "Payment completed"
                    ]

                    pendingFlutterResult?(resultMap)
                    pendingFlutterResult = nil
                }
            } catch {
                print("❌ Error while handling redirect URL: \(error.localizedDescription)")
            }

            return true
        }

        return super.application(app, open: url, options: options)
    }
}


//
//import UIKit
//import Flutter
//import OPPWAMobile
//
//@UIApplicationMain
//@objc class AppDelegate: FlutterAppDelegate, OPPCheckoutProviderDelegate, OPPThreeDSEventListener {
//
//    var flutterChannel: FlutterMethodChannel?
//    var transaction: OPPTransaction?
//    var paymentProvider: OPPPaymentProvider?
//    var checkoutProvider: OPPCheckoutProvider?
//    var pendingFlutterResult: FlutterResult?
//
//    override func application(
//        _ application: UIApplication,
//        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//    ) -> Bool {
//
//        let flutterViewController = FlutterViewController()
//        let navigationController = UINavigationController(rootViewController: flutterViewController)
//        navigationController.setNavigationBarHidden(true, animated: false)
//
//        self.window = UIWindow(frame: UIScreen.main.bounds)
//        self.window?.rootViewController = navigationController
//        self.window?.makeKeyAndVisible()
//
//        flutterChannel = FlutterMethodChannel(
//            name: "com.example.first_app/hyperpay",
//            binaryMessenger: flutterViewController.binaryMessenger
//        )
//
//        flutterChannel?.setMethodCallHandler { [weak self] call, result in
//            guard let self = self else { return }
//
//            switch call.method {
//            case "startPayment":
//                guard let args = call.arguments as? [String: Any],
//                      let checkoutId = args["checkoutId"] as? String else {
//                    result(FlutterError(code: "INVALID", message: "checkoutId missing", details: nil))
//                    return
//                }
//                ReadyPaymentHandler.startReadyPayment(checkoutId: checkoutId, delegate: self, flutterResult: result)
//
//            case "startPaymentCustom":
//                guard let args = call.arguments as? [String: Any],
//                      let paymentData = args["paymentData"] as? [String: Any] else {
//                    result(FlutterError(code: "INVALID", message: "Missing paymentData", details: nil))
//                    return
//                }
//                CustomPaymentHandler.startCustomPayment(paymentData: paymentData, delegate: self, flutterResult: result)
//
//            case "startStcPay":
//                guard let args = call.arguments as? [String: Any],
//                      let paymentData = args["paymentData"] as? [String: Any] else {
//                    result(FlutterError(code: "INVALID", message: "Missing paymentData", details: nil))
//                    return
//                }
//                StcPaymentHandler.startStcPay(paymentData: paymentData, delegate: self, flutterResult: result)
//
//            case "startApplePay":
//                guard let args = call.arguments as? [String: Any],
//                      let checkoutId = args["checkoutId"] as? String else {
//                    result(FlutterError(code: "INVALID", message: "Missing checkoutId", details: nil))
//                    return
//                }
//                ApplePayHandler.shared.startApplePay(checkoutId: checkoutId, result: result)
//
//            case "startAppleCustom":
//                            guard
//                                let args = call.arguments as? [String: Any],
//                                let checkoutId = args["checkoutId"] as? String
//                            else {
//                                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing checkoutId", details: nil))
//                                return
//                            }
//                            ApplePayCustomHandler.shared.startApplePayCustom(checkoutId: checkoutId, result: result)
//                
//            default:
//                result(FlutterMethodNotImplemented)
//            }
//        }
//
//        GeneratedPluginRegistrant.register(with: self)
//        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//    }
//
//    func onThreeDSChallengeRequired(completion: @escaping (UINavigationController) -> Void) {
//        DispatchQueue.main.async {
//            if let nav = self.window?.rootViewController as? UINavigationController {
//                print("📲 Presenting 3DS challenge screen...")
//                completion(nav)
//            } else {
//                print("❌ No suitable UINavigationController found for 3DS challenge.")
//            }
//        }
//    }
//
//    func onThreeDSConfigRequired(completion: @escaping (OPPThreeDSConfig) -> Void) {
//        completion(OPPThreeDSConfig())
//    }
//
//    override func application(_ app: UIApplication, open url: URL,
//                              options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
//        print("📡 App opened via URL: \(url.absoluteString)")
//
//        if url.scheme == "com.example.firstapp" {
//            // Apple Pay and STC Pay redirection handling
//            if url.absoluteString.contains("id=") {
//                // Apple Pay, STC Pay, etc.
//                if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
//                   let queryItems = components.queryItems,
//                   let checkoutId = queryItems.first(where: { $0.name == "id" })?.value {
//
//                    let resultMap: [String: Any] = [
//                        "status": "success",
//                        "checkoutId": checkoutId,
//                        "message": "Payment completed"
//                    ]
//
//                    pendingFlutterResult?(resultMap)
//                    pendingFlutterResult = nil
//                }
//            } 
//
//            return true
//        }
//        return super.application(app, open: url, options: options)
//    }
//}
