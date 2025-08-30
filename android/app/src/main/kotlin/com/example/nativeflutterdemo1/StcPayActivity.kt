package com.example.nativeflutterdemo1

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log
import androidx.appcompat.app.AppCompatActivity
import com.oppwa.mobile.connect.exception.PaymentError
import com.oppwa.mobile.connect.payment.PaymentParams
import com.oppwa.mobile.connect.provider.*

class StcPayActivity : AppCompatActivity(), ITransactionListener {

    private lateinit var checkoutId: String
    private lateinit var paymentProvider: OppPaymentProvider

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        try {
            // Get payment data from Intent extras
            val paymentData = intent.getSerializableExtra("paymentData") as? HashMap<*, *>
            if (paymentData == null) {
                Log.e("StcPayActivity", "paymentData is null or invalid")
                sendTransactionStatusEvent("error", "", "Missing paymentData")
                return
            }

            checkoutId = paymentData["checkoutId"] as? String ?: ""
            val brand = paymentData["brand"] as? String ?: ""

            if (checkoutId.isEmpty() || brand.isEmpty()) {
                sendTransactionStatusEvent("error", checkoutId, "Missing checkoutId or brand")
                return
            }

            // Set up the transaction with shopper result URL
            val paymentParams = PaymentParams(checkoutId, brand).apply {
                shopperResultUrl = "com.example.nativeflutterdemo1://result"
            }

            val transaction = Transaction(paymentParams)

            // Initialize HyperPay SDK
            paymentProvider = OppPaymentProvider(this, Connect.ProviderMode.TEST)
            paymentProvider.setThreeDSWorkflowListener { this }
            paymentProvider.submitTransaction(transaction, this)

        } catch (e: Exception) {
            Log.e("StcPayActivity", "Exception in onCreate: ${e.localizedMessage}", e)
            sendTransactionStatusEvent("error", "", "Exception: ${e.localizedMessage}")
        }
    }

    // Called when transaction completes successfully
    override fun transactionCompleted(transaction: Transaction) {
        try {
            val checkoutId = transaction.paymentParams?.checkoutId ?: ""
            if (transaction.transactionType == TransactionType.SYNC) {
                sendTransactionStatusEvent("success", checkoutId)
            } else {
                transaction.redirectUrl?.let { url ->
                    val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                    startActivity(intent)
                } ?: sendTransactionStatusEvent("error", checkoutId, "Missing redirect URL")
            }
        } catch (e: Exception) {
            Log.e("StcPayActivity", "Exception in transactionCompleted: ${e.localizedMessage}", e)
            sendTransactionStatusEvent("error", checkoutId, "Error handling transaction result")
        }
    }

    // Called when transaction fails
    override fun transactionFailed(transaction: Transaction, error: PaymentError) {
        try {
            sendTransactionStatusEvent("error", checkoutId, error.errorMessage ?: "Unknown error")
        } catch (e: Exception) {
            Log.e("StcPayActivity", "Exception in transactionFailed: ${e.localizedMessage}", e)
            sendTransactionStatusEvent("error", checkoutId, "Failure + Exception: ${e.localizedMessage}")
        }
    }

    // Called when redirected back to app (e.g., STC Pay deep link)
    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        try {
            intent?.data?.let { uri ->
                if (uri.toString().startsWith("com.example.nativeflutterdemo1://result")) {
                    sendTransactionStatusEvent("success", checkoutId)
                }
            }
        } catch (e: Exception) {
            Log.e("StcPayActivity", "Exception in onNewIntent: ${e.localizedMessage}", e)
            sendTransactionStatusEvent("error", checkoutId, "Redirect error: ${e.localizedMessage}")
        }
    }

    // Sends result (status, id, message) back to Flutter
    private fun sendTransactionStatusEvent(status: String, checkoutId: String, message: String = "") {
        val resultIntent = Intent().apply {
            putExtra("status", status)
            putExtra("checkoutId", checkoutId)
            putExtra("message", message)
        }
        setResult(Activity.RESULT_OK, resultIntent)
        finish()
    }
}
