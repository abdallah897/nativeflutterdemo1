import Foundation
import UIKit
import Flutter
import PassKit
import OPPWAMobile

class ApplePayHandler: NSObject {
    
    static let shared = ApplePayHandler()
    
    private var checkoutID: String = ""
    private let shopperResultURL = "com.example.nativeflutterdemo1://result"
    
    /// Starts the Apple Pay Ready UI flow
    /// - Parameters:
    ///   - checkoutId: Checkout ID from backend
    ///   - result: Callback to Flutter with status and message
    func startApplePay(checkoutId: String, result: @escaping FlutterResult) {
        print("🍏 ApplePayHandler: startApplePay() called with checkoutId: \(checkoutId)")
        self.checkoutID = checkoutId
        
        // Save Flutter result to AppDelegate for later use (if needed)
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.pendingFlutterResult = result
            print("✅ pendingFlutterResult set in AppDelegate")
        }

        // MARK: - Step 1: Configure Apple Pay request
        let paymentRequest = OPPPaymentProvider.paymentRequest(
            withMerchantIdentifier: "merchant.hamzeh.test", // Replace with your own Apple Merchant ID
            countryCode: "SA"
        )
        paymentRequest.currencyCode = "SAR"
        paymentRequest.supportedNetworks = [.visa, .masterCard]

        // MARK: - Step 2: Configure Checkout Settings
        let settings = OPPCheckoutSettings()
        settings.shopperResultURL = shopperResultURL
        settings.applePayPaymentRequest = paymentRequest
        settings.applePayType = .buy
        settings.paymentBrands = ["APPLEPAY"]

        // MARK: - Step 3: Create Provider & Checkout
        let provider = OPPPaymentProvider(mode: .test)
        let checkoutProvider = OPPCheckoutProvider(paymentProvider: provider, checkoutID: checkoutId, settings: settings)

        // MARK: - Step 4: Present Apple Pay UI
        print("🚀 Presenting Apple Pay Checkout UI...")
        checkoutProvider?.presentCheckout(
            withPaymentBrand: "APPLEPAY",
            loadingHandler: { inProgress in
                print(inProgress ? "🔄 Apple Pay Loading..." : "✅ Apple Pay Loaded")
            },
            completionHandler: { transaction, error in
                // MARK: - Handle transaction completion or error
                if let error = error {
                    print("❌ Apple Pay Error: \(error.localizedDescription)")
                    result(["status": "error", "message": error.localizedDescription])
                    return
                }

                guard let transaction = transaction else {
                    print("⚠️ Apple Pay: Transaction is nil")
                    result(["status": "error", "message": "Transaction is nil"])
                    return
                }

                print("✅ Apple Pay Success - Synchronous transaction")

                // MARK: - Step 5: Check payment status from backend
                self.fetchPaymentStatus(checkoutId: checkoutId, result: result)

                // MARK: - Optional: Dismiss Apple Pay UI
                DispatchQueue.main.async {
                    if let topVC = UIApplication.shared.keyWindow?.rootViewController?.presentedViewController {
                        topVC.dismiss(animated: true) {
                            print("✅ Apple Pay UI dismissed")
                        }
                    }
                }
            },
            cancelHandler: {
                // MARK: - Handle user cancellation
                print("❌ Apple Pay Cancelled by User")
                result(["status": "cancelled", "message": "User cancelled"])
            }
        )
    }

    /// Calls backend to check the payment result using checkout ID
    private func fetchPaymentStatus(checkoutId: String, result: @escaping FlutterResult) {
        guard let url = URL(string: "https://integration.hyperpay.com/hyperpay-demo/getpaymentstatus.php?id=\(checkoutId)") else {
            print("❌ Invalid status URL")
            result(["status": "error", "message": "Invalid status URL"])
            return
        }

        print("🌐 Fetching payment status from: \(url.absoluteString)")

        // MARK: - Call backend to get status
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                result(["status": "error", "message": "Network error: \(error.localizedDescription)"])
                return
            }

            guard let data = data else {
                print("❌ No data received from status request")
                result(["status": "error", "message": "No response data"])
                return
            }

            do {
                // Try to decode JSON
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                print("📥 Status JSON: \(String(describing: json))")

                // Extract status
                if let resultObj = json?["result"] as? [String: Any] {
                    let code = resultObj["code"] as? String ?? "no_code"
                    let desc = resultObj["description"] as? String ?? "no_description"
                    print("✅ Payment Status: \(code) — \(desc)")
                    result(["status": code, "message": desc, "checkoutId": checkoutId])
                } else if let description = json?["description"] as? String {
                    print("✅ Payment Description: \(description)")
                    result(["status": "no_code", "message": description, "checkoutId": checkoutId])
                } else {
                    print("⚠️ Unknown structure. Full JSON: \(String(describing: json))")
                    result(["status": "unknown", "message": "No status description", "checkoutId": checkoutId])
                }
            } catch {
                // MARK: - Handle JSON parse error
                print("❌ JSON parse error: \(error.localizedDescription)")
                result(["status": "error", "message": "Failed to parse JSON", "checkoutId": checkoutId])
            }
        }

        task.resume()
    }
}



//import Foundation
//import UIKit
//import Flutter
//import PassKit
//import OPPWAMobile
//
//class ApplePayHandler: NSObject {
//    static let shared = ApplePayHandler()
//
//    private var checkoutID: String = ""
//    private let shopperResultURL = "com.example.firstapp://result"
//
//    func startApplePay(checkoutId: String, result: @escaping FlutterResult) {
//        print("🍏 ApplePayHandler: startApplePay() called with checkoutId: \(checkoutId)")
//        self.checkoutID = checkoutId
//
//        // Save Flutter result to AppDelegate
//        if let delegate = UIApplication.shared.delegate as? AppDelegate {
//            delegate.pendingFlutterResult = result
//            print("✅ pendingFlutterResult set in AppDelegate")
//        }
//
//        // Step 1: Configure Apple Pay request
//        let paymentRequest = OPPPaymentProvider.paymentRequest(
//            withMerchantIdentifier: "merchant.hamzeh.test", // Replace with your Merchant ID
//            countryCode: "SA"
//        )
//        paymentRequest.currencyCode = "SAR"
//        paymentRequest.supportedNetworks = [.visa, .masterCard]
//
//        // Step 2: Configure Checkout Settings
//        let settings = OPPCheckoutSettings()
//        settings.shopperResultURL = shopperResultURL
//        settings.applePayPaymentRequest = paymentRequest
//        settings.applePayType = .buy
//        settings.paymentBrands = ["APPLEPAY"]
//
//        // Step 3: Create Provider & Checkout
//        let provider = OPPPaymentProvider(mode: .test)
//        let checkoutProvider = OPPCheckoutProvider(paymentProvider: provider, checkoutID: checkoutId, settings: settings)
//
//        // Step 4: Present Apple Pay
//        print("🚀 Presenting Apple Pay Checkout UI...")
//        checkoutProvider?.presentCheckout(
//            withPaymentBrand: "APPLEPAY",
//            loadingHandler: { inProgress in
//                print(inProgress ? "🔄 Apple Pay Loading..." : "✅ Apple Pay Loaded")
//            },
//            completionHandler: { transaction, error in
//                if let error = error {
//                    print("❌ Apple Pay Error: \(error.localizedDescription)")
//                    result(["status": "error", "message": error.localizedDescription])
//                    return
//                }
//
//                guard let transaction = transaction else {
//                    print("⚠️ Apple Pay: Transaction is nil")
//                    result(["status": "error", "message": "Transaction is nil"])
//                    return
//                }
//
//                // ✅ Synchronous expected for Apple Pay
//                print("✅ Apple Pay Success - Synchronous transaction")
//                self.fetchPaymentStatus(checkoutId: checkoutId, result: result)
//
//                // Optional: Dismiss Apple Pay UI
//                DispatchQueue.main.async {
//                    if let topVC = UIApplication.shared.keyWindow?.rootViewController?.presentedViewController {
//                        topVC.dismiss(animated: true) {
//                            print("✅ Apple Pay UI dismissed")
//                        }
//                    }
//                }
//            },
//            cancelHandler: {
//                print("❌ Apple Pay Cancelled by User")
//                result(["status": "cancelled", "message": "User cancelled"])
//            }
//        )
//    }
//
//    private func fetchPaymentStatus(checkoutId: String, result: @escaping FlutterResult) {
//        guard let url = URL(string: "https://integration.hyperpay.com/hyperpay-demo/getpaymentstatus.php?id=\(checkoutId)") else {
//            print("❌ Invalid status URL")
//            result(["status": "error", "message": "Invalid status URL"])
//            return
//        }
//
//        print("🌐 Fetching payment status from: \(url.absoluteString)")
//
//        let task = URLSession.shared.dataTask(with: url) { data, response, error in
//            if let error = error {
//                print("❌ Network error: \(error.localizedDescription)")
//                result(["status": "error", "message": "Network error: \(error.localizedDescription)"])
//                return
//            }
//
//            guard let data = data else {
//                print("❌ No data received from status request")
//                result(["status": "error", "message": "No response data"])
//                return
//            }
//
//            do {
//                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
//                print("📥 Status JSON: \(String(describing: json))")
//
//                if let resultObj = json?["result"] as? [String: Any] {
//                    let code = resultObj["code"] as? String ?? "no_code"
//                    let desc = resultObj["description"] as? String ?? "no_description"
//                    print("✅ Payment Status: \(code) — \(desc)")
//                    result(["status": code, "message": desc, "checkoutId": checkoutId])
//                } else if let description = json?["description"] as? String {
//                    print("✅ Payment Description: \(description)")
//                    result(["status": "no_code", "message": description, "checkoutId": checkoutId])
//                } else {
//                    print("⚠️ Unknown structure. Full JSON: \(String(describing: json))")
//                    result(["status": "unknown", "message": "No status description", "checkoutId": checkoutId])
//                }
//            } catch {
//                print("❌ JSON parse error: \(error.localizedDescription)")
//                result(["status": "error", "message": "Failed to parse JSON", "checkoutId": checkoutId])
//            }
//        }
//
//        task.resume()
//    }
//}
