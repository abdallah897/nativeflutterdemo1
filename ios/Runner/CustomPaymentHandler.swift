import Foundation
import OPPWAMobile
import UIKit

class CustomPaymentHandler {

    /// Starts the Custom UI card payment process
    /// - Parameters:
    ///   - paymentData: Dictionary containing card and checkout info
    ///   - delegate: AppDelegate instance to handle 3D Secure and transaction state
    ///   - flutterResult: Result callback for Flutter
    static func startCustomPayment(paymentData: [String: Any], delegate: AppDelegate, flutterResult: @escaping FlutterResult) {
        
        // MARK: - Validate and extract required fields
        guard let checkoutId = paymentData["checkoutId"] as? String,
              let brand = paymentData["brand"] as? String,
              let holder = paymentData["cardHolder"] as? String,
              let number = paymentData["cardNumber"] as? String,
              let expiryMonth = paymentData["expiryMonth"] as? String,
              let cvv = paymentData["cvv"] as? String else {
            flutterResult(FlutterError(code: "DATA_ERROR", message: "Missing required fields", details: nil))
            return
        }

        // MARK: - Handle expiry year (e.g., "30" → "2030")
        let expiryYear: String
        if let rawYear = paymentData["expiryYear"] {
            let yearString = String(describing: rawYear)
            expiryYear = yearString.count == 2 ? "20\(yearString)" : yearString
        } else {
            flutterResult(FlutterError(code: "DATA_ERROR", message: "Missing expiryYear", details: nil))
            return
        }

        // MARK: - Initialize payment provider and 3DS listener
        delegate.paymentProvider = OPPPaymentProvider(mode: .test)
        delegate.paymentProvider?.threeDSEventListener = delegate

        do {
            // MARK: - Prepare payment parameters
            let params = try OPPCardPaymentParams(
                checkoutID: checkoutId,
                paymentBrand: brand,
                holder: holder,
                number: number,
                expiryMonth: expiryMonth,
                expiryYear: expiryYear,
                cvv: cvv
            )
            params.shopperResultURL = "com.example.nativeflutterdemo1://result"

            // MARK: - Create and submit transaction
            let transaction = OPPTransaction(paymentParams: params)
            delegate.transaction = transaction
            delegate.pendingFlutterResult = flutterResult

            // Submit the transaction
            delegate.paymentProvider?.submitTransaction(transaction) { submittedTransaction, error in
                if let error = error {
                    // MARK: - Handle failure
                    print("❌ Custom UI: Submit error - \(error.localizedDescription)")
                    flutterResult([
                        "status": "error",
                        "message": error.localizedDescription,
                        "checkoutId": checkoutId
                    ])
                    delegate.pendingFlutterResult = nil
                } else {
                    // MARK: - Handle success
                    print("✅ Custom UI: Submitted successfully")
                    flutterResult([
                        "status": "success",
                        "message": "Payment completed successfully",
                        "checkoutId": checkoutId
                    ])
                    delegate.pendingFlutterResult = nil
                }
            }
        } catch {
            // MARK: - Handle parameter creation failure
            print("❌ Custom UI: Params error - \(error.localizedDescription)")
            flutterResult(FlutterError(code: "PARAM_ERROR", message: error.localizedDescription, details: nil))
        }
    }
}


//import Foundation
//import OPPWAMobile
//import UIKit
//
//class CustomPaymentHandler {
//    static func startCustomPayment(paymentData: [String: Any], delegate: AppDelegate, flutterResult: @escaping FlutterResult) {
//        guard let checkoutId = paymentData["checkoutId"] as? String,
//              let brand = paymentData["brand"] as? String,
//              let holder = paymentData["cardHolder"] as? String,
//              let number = paymentData["cardNumber"] as? String,
//              let expiryMonth = paymentData["expiryMonth"] as? String,
//              let cvv = paymentData["cvv"] as? String else {
//            flutterResult(FlutterError(code: "DATA_ERROR", message: "Missing required fields", details: nil))
//            return
//        }
//
//        let expiryYear: String
//        if let rawYear = paymentData["expiryYear"] {
//            let yearString = String(describing: rawYear)
//            expiryYear = yearString.count == 2 ? "20\(yearString)" : yearString
//        } else {
//            flutterResult(FlutterError(code: "DATA_ERROR", message: "Missing expiryYear", details: nil))
//            return
//        }
//
//        delegate.paymentProvider = OPPPaymentProvider(mode: .test)
//        delegate.paymentProvider?.threeDSEventListener = delegate
//
//        do {
//            let params = try OPPCardPaymentParams(
//                checkoutID: checkoutId,
//                paymentBrand: brand,
//                holder: holder,
//                number: number,
//                expiryMonth: expiryMonth,
//                expiryYear: expiryYear,
//                cvv: cvv
//            )
//            params.shopperResultURL = "com.example.firstapp://result"
//
//            let transaction = OPPTransaction(paymentParams: params)
//            delegate.transaction = transaction
//            delegate.pendingFlutterResult = flutterResult
//
//            delegate.paymentProvider?.submitTransaction(transaction) { submittedTransaction, error in
//                if let error = error {
//                    print("❌ Custom UI: Submit error - \(error.localizedDescription)")
//                    flutterResult([
//                        "status": "error",
//                        "message": error.localizedDescription,
//                        "checkoutId": checkoutId
//                    ])
//                    delegate.pendingFlutterResult = nil
//                } else {
//                    print("✅ Custom UI: Submitted successfully")
//                    flutterResult([
//                        "status": "success",
//                        "message": "Payment completed successfully",
//                        "checkoutId": checkoutId
//                    ])
//                    delegate.pendingFlutterResult = nil
//                }
//            }
//        } catch {
//            print("❌ Custom UI: Params error - \(error.localizedDescription)")
//            flutterResult(FlutterError(code: "PARAM_ERROR", message: error.localizedDescription, details: nil))
//        }
//    }
//}
