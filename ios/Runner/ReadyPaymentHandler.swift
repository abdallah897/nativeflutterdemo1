//
//  ReadyPaymentHandler.swift
//  Runner
//
//  Created by Hyper Pay on 22/06/2025.
//

import Foundation
import OPPWAMobile
import UIKit

class ReadyPaymentHandler {
    
    /// Starts the Ready UI payment process
    /// - Parameters:
    ///   - checkoutId: The checkout ID received from the backend
    ///   - delegate: The AppDelegate instance for handling SDK callbacks
    ///   - flutterResult: Callback to return result to Flutter side
    static func startReadyPayment(checkoutId: String, delegate: AppDelegate, flutterResult: @escaping FlutterResult) {
        do {
            // Initialize payment provider in test mode
            let provider = OPPPaymentProvider(mode: .test)
            
            // Setup checkout settings
            let settings = OPPCheckoutSettings()
            settings.paymentBrands = ["VISA", "MASTER", "MADA", "AMEX"] // Accepted payment brands
            settings.shopperResultURL = "com.example.nativeflutterdemo1://result" // Custom URL scheme for redirection
            settings.storePaymentDetails = .prompt // Ask user to store card
            settings.theme.navigationBarBackgroundColor = .systemBlue // Customize navigation bar color
            
            // Initialize the checkout provider with the payment provider, checkout ID and settings
            let checkoutProvider = OPPCheckoutProvider(paymentProvider: provider, checkoutID: checkoutId, settings: settings)
            checkoutProvider?.delegate = delegate
            delegate.checkoutProvider = checkoutProvider
            
            // Present the Ready UI screen
            checkoutProvider?.presentCheckout(
                forSubmittingTransactionCompletionHandler: { transaction, error in
                    // Handle transaction success or failure
                    guard let transaction = transaction else {
                        flutterResult(FlutterError(
                            code: "TRANSACTION_ERROR",
                            message: error?.localizedDescription ?? "Unknown error",
                            details: nil
                        ))
                        return
                    }
                    
                    print("✅ Ready UI: transaction submitted with ID: \(transaction.paymentParams.checkoutID)")
                    delegate.transaction = transaction
                    flutterResult(transaction.paymentParams.checkoutID)
                },
                cancelHandler: {
                    // Handle user cancellation
                    print("❌ Ready UI: Payment cancelled")
                    flutterResult(FlutterError(
                        code: "CANCELLED",
                        message: "Payment canceled by user.",
                        details: nil
                    ))
                }
            )
        } catch {
            // Catch and return any unexpected errors
            print("❌ ReadyPaymentHandler error: \(error.localizedDescription)")
            flutterResult(FlutterError(
                code: "READY_UI_ERROR",
                message: "Unexpected error occurred during payment setup.",
                details: error.localizedDescription
            ))
        }
    }
}



////
////  ReadyPaymentHandler.swift
////  Runner
////
////  Created by Hyper Pay on 22/06/2025.
////
//
//import Foundation
//import OPPWAMobile
//import UIKit
//
//class ReadyPaymentHandler {
//    static func startReadyPayment(checkoutId: String, delegate: AppDelegate, flutterResult: @escaping FlutterResult) {
//        let provider = OPPPaymentProvider(mode: .test)
//        let settings = OPPCheckoutSettings()
//        settings.paymentBrands = ["VISA", "MASTER", "MADA", "AMEX"]
//        settings.shopperResultURL = "com.example.firstapp://result"
//        settings.storePaymentDetails = .prompt
//        settings.theme.navigationBarBackgroundColor = .systemBlue
//
//        let checkoutProvider = OPPCheckoutProvider(paymentProvider: provider, checkoutID: checkoutId, settings: settings)
//        checkoutProvider?.delegate = delegate
//
//        delegate.checkoutProvider = checkoutProvider
//
//        checkoutProvider?.presentCheckout(forSubmittingTransactionCompletionHandler: { transaction, error in
//            guard let transaction = transaction else {
//                flutterResult(FlutterError(code: "TRANSACTION_ERROR", message: error?.localizedDescription ?? "Unknown error", details: nil))
//                return
//            }
//            print("✅ Ready UI: transaction submitted with ID: \(transaction.paymentParams.checkoutID)")
//            delegate.transaction = transaction
//            flutterResult(transaction.paymentParams.checkoutID)
//        }, cancelHandler: {
//            print("❌ Ready UI: Payment cancelled")
//            flutterResult(FlutterError(code: "CANCELLED", message: "Payment canceled by user.", details: nil))
//        })
//    }
//}
