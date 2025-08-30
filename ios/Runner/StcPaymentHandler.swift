//
//  StcPaymentHandler.swift
//  Runner
//
//  Created by Hyper Pay on 23/06/2025.
// 

import UIKit
import OPPWAMobile

class StcPaymentHandler {
    
    /// Starts the STC Pay transaction flow
    /// - Parameters:
    ///   - paymentData: Dictionary containing `checkoutId` and `brand`
    ///   - delegate: AppDelegate instance for transaction and 3DS handling
    ///   - flutterResult: Result callback to return to Flutter
    static func startStcPay(paymentData: [String: Any], delegate: AppDelegate, flutterResult: @escaping FlutterResult) {
        
        // MARK: - Extract required fields from the input dictionary
        guard let checkoutId = paymentData["checkoutId"] as? String,
              let brand = paymentData["brand"] as? String else {
            flutterResult(FlutterError(
                code: "DATA_ERROR",
                message: "Missing checkoutId or brand",
                details: nil
            ))
            return
        }

        // MARK: - Create STC Pay payment parameters
        guard let paymentParams = try? OPPPaymentParams(checkoutID: checkoutId, paymentBrand: brand) else {
            flutterResult(FlutterError(
                code: "PARAM_ERROR",
                message: "Failed to create STC payment params",
                details: nil
            ))
            return
        }
        
        // Configure shopper redirect URL (custom URL scheme must be registered)
        paymentParams.shopperResultURL = "com.example.nativeflutterdemo1://result"

        // MARK: - Create transaction and configure provider
        let transaction = OPPTransaction(paymentParams: paymentParams)
        delegate.paymentProvider = OPPPaymentProvider(mode: .test)
        delegate.paymentProvider?.threeDSEventListener = delegate
        delegate.transaction = transaction
        delegate.pendingFlutterResult = flutterResult

        // MARK: - Submit the transaction to HyperPay backend
        delegate.paymentProvider?.submitTransaction(transaction) { submittedTransaction, error in
            if let error = error {
                // Payment submission failed
                flutterResult([
                    "status": "error",
                    "message": error.localizedDescription,
                    "checkoutId": checkoutId
                ])
                delegate.pendingFlutterResult = nil
            } else {
                // MARK: - Handle redirect for STC Pay
                guard let redirectURL = submittedTransaction.redirectURL else {
                    // Missing redirect URL means STC Pay app cannot be opened
                    flutterResult([
                        "status": "error",
                        "message": "Missing redirect URL",
                        "checkoutId": checkoutId
                    ])
                    delegate.pendingFlutterResult = nil
                    return
                }

                // Attempt to open the STC Pay app or browser
                if let url = URL(string: redirectURL.absoluteString) {
                    DispatchQueue.main.async {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }
                // The result will be handled later through URL redirect to AppDelegate
            }
        }
    }
}


////
////  StcPaymentHandler.swift
////  Runner
////
////  Created by Hyper Pay on 23/06/2025.
////
//
//import UIKit
//import OPPWAMobile
//
//class StcPaymentHandler {
//    static func startStcPay(paymentData: [String: Any], delegate: AppDelegate, flutterResult: @escaping FlutterResult) {
//        guard let checkoutId = paymentData["checkoutId"] as? String,
//              let brand = paymentData["brand"] as? String else {
//            flutterResult(FlutterError(code: "DATA_ERROR", message: "Missing checkoutId or brand", details: nil))
//            return
//        }
//
//        guard let paymentParams = try? OPPPaymentParams(checkoutID: checkoutId, paymentBrand: brand) else {
//            flutterResult(FlutterError(code: "PARAM_ERROR", message: "Failed to create STC payment params", details: nil))
//            return
//        }
//        paymentParams.shopperResultURL = "com.example.firstapp://result"
//
//        let transaction = OPPTransaction(paymentParams: paymentParams)
//
//        delegate.paymentProvider = OPPPaymentProvider(mode: .test)
//        delegate.paymentProvider?.threeDSEventListener = delegate
//        delegate.transaction = transaction
//        delegate.pendingFlutterResult = flutterResult
//
//        delegate.paymentProvider?.submitTransaction(transaction) { submittedTransaction, error in
//            if let error = error {
//                flutterResult([
//                    "status": "error",
//                    "message": error.localizedDescription,
//                    "checkoutId": checkoutId
//                ])
//                delegate.pendingFlutterResult = nil
//            } else {
//                guard let redirectURL = submittedTransaction.redirectURL else {
//                    flutterResult([
//                        "status": "error",
//                        "message": "Missing redirect URL",
//                        "checkoutId": checkoutId
//                    ])
//                    delegate.pendingFlutterResult = nil
//                    return
//                }
//
//                // Open STC Pay App (or Safari fallback)
//                if let url = URL(string: redirectURL.absoluteString) {
//                    DispatchQueue.main.async {
//                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
//                    }
//                }
//            }
//        }
//    }
//}
