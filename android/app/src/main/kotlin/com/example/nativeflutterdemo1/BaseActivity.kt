package com.example.nativeflutterdemo1

import android.os.Bundle
import android.view.View
import android.widget.ProgressBar
import androidx.activity.result.ActivityResultLauncher
import androidx.appcompat.app.AppCompatActivity
import com.oppwa.mobile.connect.checkout.meta.CheckoutActivityResult
import com.oppwa.mobile.connect.checkout.meta.CheckoutActivityResultContract
import com.oppwa.mobile.connect.checkout.meta.CheckoutSettings
import com.oppwa.mobile.connect.provider.Transaction
import com.oppwa.mobile.connect.provider.TransactionType
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterFragmentActivity
import android.util.Log
import com.oppwa.mobile.connect.exception.PaymentError


open class BaseActivity : FlutterFragmentActivity() {
    private lateinit var checkoutLauncher: ActivityResultLauncher<CheckoutSettings>

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

//        checkoutLauncher = registerForActivityResult(CheckoutActivityResultContract()) { result ->
//            handleCheckoutActivityResult(result)
//        }
    }



//    public open fun handleCheckoutActivityResult(result: CheckoutActivityResult) {
//        try {
//            // Check if the result is canceled by the user
//            if (result.isCanceled) {
//                // Handle canceled payment result (e.g., notify the user)
//                Log.d("Payment", "Payment was canceled by the user.")
//                return
//            }
//
//            // Check if the result contains an error
//            if (result.isErrored) {
//                val error: PaymentError? = result.paymentError
//                // Handle error case (e.g., log the error or notify the user)
//                error?.let {
//                    Log.e("Payment Error", "Error: ${it.errorMessage}")
//                }
//                return
//            }
//
//            // If the result is successful, retrieve the transaction
//            val transaction: Transaction? = result.transaction
//
//            if (transaction != null) {
//                // Handle successful transaction based on transaction type
//                when (transaction.transactionType) {
//                    TransactionType.SYNC -> {
//                        // Handle SYNC transaction (e.g., finalizing the payment)
//                        Log.d("Payment", "SYNC Payment Successful")
//                    }
//                    else -> {
//                        // Handle other types of transactions (e.g., async)
//                        Log.d("Payment", "ASYNC Payment Started")
//                    }
//                }
//            }
//
//        } catch (e: Exception) {
//            // Catch and log any exception that occurs during result processing
//            Log.e("Payment Error", "Exception: ${e.message}")
//        }
//    }


}

