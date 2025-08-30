//
//  ApplePayCustom.swift
//  Runner
//
//  Created by Hyper Pay on 25/06/2025.
//

import Foundation
import Flutter
import UIKit
import PassKit
import OPPWAMobile

class ApplePayCustomHandler: NSObject, PKPaymentAuthorizationViewControllerDelegate {

    // Singleton instance
    static let shared = ApplePayCustomHandler()

    // MARK: - Properties
    private var resultHandler: FlutterResult?
    private var checkoutID: String = ""
    private var paymentProvider: OPPPaymentProvider?

    private let merchantID = "merchant.hamzeh.test" // ✅ Replace with your Apple Merchant ID
    private let shopperResultURL = "com.example.nativeflutterdemo1://result"

    /// Starts the Apple Pay flow using Custom UI
    /// - Parameters:
    ///   - checkoutId: Backend-generated checkout ID
    ///   - result: Callback to Flutter
    func startApplePayCustom(checkoutId: String, result: @escaping FlutterResult) {
        print("🍏 ApplePayCustomHandler: Starting with checkoutId: \(checkoutId)")
        self.checkoutID = checkoutId
        self.resultHandler = result

        // MARK: - Configure Apple Pay request
        let paymentRequest = OPPPaymentProvider.paymentRequest(
            withMerchantIdentifier: merchantID,
            countryCode: "SA"
        )
        paymentRequest.currencyCode = "SAR"
        paymentRequest.supportedNetworks = [.visa, .masterCard]
        paymentRequest.merchantCapabilities = .capability3DS
        paymentRequest.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "HyperPay Order", amount: NSDecimalNumber(string: "1.00"))
        ]

        // MARK: - Create and present Apple Pay authorization sheet
        guard let paymentVC = PKPaymentAuthorizationViewController(paymentRequest: paymentRequest) else {
            print("❌ Failed to create Apple Pay VC")
            result(["status": "error", "message": "Unable to present Apple Pay sheet"])
            return
        }

        paymentVC.delegate = self

        DispatchQueue.main.async {
            if let topVC = UIApplication.shared.keyWindow?.rootViewController {
                topVC.present(paymentVC, animated: true) {
                    print("🚀 Presented Apple Pay sheet")
                }
            } else {
                print("❌ Failed to get root view controller")
                result(["status": "error", "message": "No UI to present Apple Pay"])
            }
        }
    }

    // MARK: - Apple Pay Delegate Methods

    /// Called when the user authorizes payment
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController,
                                            didAuthorizePayment payment: PKPayment,
                                            handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        print("✅ Apple Pay authorized. Preparing to submit transaction...")

        do {
            // MARK: - Prepare and submit Apple Pay transaction
            let params = try OPPApplePayPaymentParams(checkoutID: checkoutID, tokenData: payment.token.paymentData)
            params.shopperResultURL = self.shopperResultURL

            let transaction = OPPTransaction(paymentParams: params)
            let provider = OPPPaymentProvider(mode: .test)
            self.paymentProvider = provider

            provider.submitTransaction(transaction) { [weak self] submittedTransaction, error in
                guard let self = self else { return }

                if let error = error {
                    // MARK: - Handle failure
                    print("❌ Apple Pay Transaction Failed: \(error.localizedDescription)")
                    completion(PKPaymentAuthorizationResult(status: .failure, errors: nil))
                    self.resultHandler?(["status": "error", "message": error.localizedDescription])
                    return
                }

                // MARK: - Handle success
                print("✅ Apple Pay Transaction Submitted Successfully")
                completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
                self.resultHandler?(["status": "success", "checkoutId": self.checkoutID, "message": "Payment successful"])
            }

        } catch {
            // MARK: - Handle exception while creating payment params
            print("❌ Failed to create Apple Pay params: \(error.localizedDescription)")
            completion(PKPaymentAuthorizationResult(status: .failure, errors: nil))
            resultHandler?(["status": "error", "message": "Invalid or missing Apple Pay parameters: \(error.localizedDescription)"])
        }
    }

    /// Called when the Apple Pay sheet is dismissed
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        controller.dismiss(animated: true) {
            print("✅ Apple Pay Sheet Dismissed")
        }
    }
}


////
////  ApplePayCustom.swift
////  Runner
////
////  Created by Hyper Pay on 25/06/2025.
////
//import Foundation
//import Flutter
//import UIKit
//import PassKit
//import OPPWAMobile
//
//class ApplePayCustomHandler: NSObject, PKPaymentAuthorizationViewControllerDelegate {
//    static let shared = ApplePayCustomHandler()
//
//    private var resultHandler: FlutterResult?
//    private var checkoutID: String = ""
//    private var paymentProvider: OPPPaymentProvider?
//
//    private let merchantID = "merchant.hamzeh.test" // Replace with your actual merchant ID
//    private let shopperResultURL = "com.example.firstapp://result"
//
//    func startApplePayCustom(checkoutId: String, result: @escaping FlutterResult) {
//        print("🍏 ApplePayCustomHandler: Starting with checkoutId: \(checkoutId)")
//        self.checkoutID = checkoutId
//        self.resultHandler = result
//
//        let paymentRequest = OPPPaymentProvider.paymentRequest(
//            withMerchantIdentifier: merchantID,
//            countryCode: "SA"
//        )
//        paymentRequest.currencyCode = "SAR"
//        paymentRequest.supportedNetworks = [.visa, .masterCard]
//        paymentRequest.merchantCapabilities = .capability3DS
//        paymentRequest.paymentSummaryItems = [
//            PKPaymentSummaryItem(label: "HyperPay Order", amount: NSDecimalNumber(string: "1.00"))
//        ]
//
//        guard let paymentVC = PKPaymentAuthorizationViewController(paymentRequest: paymentRequest) else {
//            print("❌ Failed to create Apple Pay VC")
//            result(["status": "error", "message": "Unable to present Apple Pay sheet"])
//            return
//        }
//
//        paymentVC.delegate = self
//
//        DispatchQueue.main.async {
//            if let topVC = UIApplication.shared.keyWindow?.rootViewController {
//                topVC.present(paymentVC, animated: true) {
//                    print("🚀 Presented Apple Pay sheet")
//                }
//            } else {
//                print("❌ Failed to get root view controller")
//                result(["status": "error", "message": "No UI to present Apple Pay"])
//            }
//        }
//    }
//
//    // MARK: - Apple Pay Delegate
//
//    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController,
//                                            didAuthorizePayment payment: PKPayment,
//                                            handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
//
//        print("✅ Apple Pay authorized. Preparing to submit transaction...")
//
//        do {
//            let params = try OPPApplePayPaymentParams(checkoutID: checkoutID, tokenData: payment.token.paymentData)
//            params.shopperResultURL=self.shopperResultURL
//            let transaction = OPPTransaction(paymentParams: params)
//            let provider = OPPPaymentProvider(mode: .test)
//            self.paymentProvider = provider
//
//            provider.submitTransaction(transaction) { [weak self] submittedTransaction, error in
//                guard let self = self else { return }
//
//                if let error = error {
//                    print("❌ Apple Pay Transaction Failed: \(error.localizedDescription)")
//                    completion(PKPaymentAuthorizationResult(status: .failure, errors: nil))
//                    self.resultHandler?(["status": "error", "message": error.localizedDescription])
//                    return
//                }
//
//                print("✅ Apple Pay Transaction Submitted Successfully")
//                completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
//                self.resultHandler?(["status": "success", "checkoutId": self.checkoutID, "message": "Payment successful"])
//            }
//
//        } catch {
//            print("❌ Failed to create Apple Pay params: \(error.localizedDescription)")
//            completion(PKPaymentAuthorizationResult(status: .failure, errors: nil))
//            resultHandler?(["status": "error", "message": "Invalid or missing Apple Pay parameters: \(error.localizedDescription)"])
//        }
//    }
//
//    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
//        controller.dismiss(animated: true) {
//            print("✅ Apple Pay Sheet Dismissed")
//        }
//    }
//}
