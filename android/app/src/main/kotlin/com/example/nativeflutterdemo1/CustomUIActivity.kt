package com.example.nativeflutterdemo1

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.util.Log
import androidx.appcompat.app.AppCompatActivity
import com.oppwa.mobile.connect.exception.PaymentError
import com.oppwa.mobile.connect.payment.card.CardPaymentParams
import com.oppwa.mobile.connect.provider.*

class CustomUIActivity : AppCompatActivity(), ITransactionListener {

    private lateinit var checkoutId: String
    private lateinit var paymentProvider: OppPaymentProvider

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d("CustomUIActivity", "onCreate called")

        try {
            // Retrieve payment data from intent
            val paymentData = intent.getSerializableExtra("paymentData") as? HashMap<*, *>
            if (paymentData == null) {
                Log.e("CustomUIActivity", "paymentData is null or invalid")
                setResult(Activity.RESULT_CANCELED)
                finish()
                return
            }

            // Extract and validate required fields
            checkoutId = paymentData["checkoutId"] as String
            val brand = paymentData["brand"] as String
            val holder = paymentData["cardHolder"] as String
            val number = paymentData["cardNumber"] as String
            val expiryMonth = paymentData["expiryMonth"] as String
            val cardExpiryYear = paymentData["expiryYear"] as String
            val cvv = paymentData["cvv"] as String

            Log.d("CustomUIActivity", "Parsed checkoutId: $checkoutId")
            Log.d("CustomUIActivity", "Parsed paymentData successfully")

            // Format the expiry year (e.g. "25" → "2025")
            val expiryYear = "20$cardExpiryYear"

            // Create payment params for card transaction
            val paymentParams = CardPaymentParams(
                checkoutId,
                brand,
                number,
                holder,
                expiryMonth,
                expiryYear,
                cvv
            ).apply {
                shopperResultUrl = "com.example.nativeflutterdemo1://result"
            }

            // Create transaction and submit it to HyperPay provider
            val transaction = Transaction(paymentParams)
            paymentProvider = OppPaymentProvider(this, Connect.ProviderMode.TEST)
            paymentProvider.setThreeDSWorkflowListener { this }
            paymentProvider.submitTransaction(transaction, this)

        } catch (e: Exception) {
            // Catch any exception during payment initialization
            Log.e("CustomUIActivity", "Exception during payment init", e)
            setResult(Activity.RESULT_CANCELED)
            finish()
        }
    }

    /**
     * Called when the transaction completes successfully
     */
    override fun transactionCompleted(transaction: Transaction) {
        try {
            Log.d("Hyperpay", "Transaction Completed: type=${transaction.transactionType}")
            Log.d("CustomUIActivity", "Transaction completed")

            val intent = Intent().apply {
                putExtra("status", "success")
                putExtra("message", "Payment completed successfully")
                putExtra("checkoutId", checkoutId)
            }

            setResult(Activity.RESULT_OK, intent)
            finish()
        } catch (e: Exception) {
            Log.e("CustomUIActivity", "Exception in transactionCompleted", e)
            setResult(Activity.RESULT_CANCELED)
            finish()
        }
    }

    /**
     * Called when the transaction fails
     */
    override fun transactionFailed(transaction: Transaction, error: PaymentError) {
        try {
            Log.d("CustomUIActivity", "Transaction failed: ${error.errorMessage}")

            val intent = Intent().apply {
                putExtra("status", "error")
                putExtra("message", error.errorMessage)
                putExtra("checkoutId", checkoutId)
            }

            setResult(Activity.RESULT_OK, intent)
            finish()
        } catch (e: Exception) {
            Log.e("CustomUIActivity", "Exception in transactionFailed", e)
            setResult(Activity.RESULT_CANCELED)
            finish()
        }
    }
}
