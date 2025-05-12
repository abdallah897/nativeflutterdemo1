package com.example.nativeflutterdemo1

import android.content.ComponentName
import android.content.Intent
import android.os.Bundle
import androidx.activity.result.ActivityResultLauncher
import androidx.annotation.NonNull
import com.oppwa.mobile.connect.checkout.dialog.CheckoutActivity
import com.oppwa.mobile.connect.checkout.meta.CheckoutActivityResult
import com.oppwa.mobile.connect.checkout.meta.CheckoutActivityResultContract
import com.oppwa.mobile.connect.checkout.meta.CheckoutSettings
import com.oppwa.mobile.connect.checkout.meta.CheckoutSkipCVVMode
import com.oppwa.mobile.connect.demo.receiver.CheckoutBroadcastReceiver
import com.oppwa.mobile.connect.provider.Connect
import com.oppwa.mobile.connect.provider.TransactionType
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

open class MainActivity : BaseActivity() {

    private lateinit var checkoutResult: MethodChannel.Result
    private lateinit var checkoutLauncher: ActivityResultLauncher<CheckoutSettings>
    private lateinit var checkoutId: String
    private lateinit var connect: Connect

    companion object {
        const val CHANNEL = "com.example.nativeflutterdemo1/hyperpay"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        checkoutLauncher = registerForActivityResult(CheckoutActivityResultContract()) { result ->
            handleCheckoutActivityResult(result)
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "startPayment") {
                val id = call.argument<String>("checkoutId")
                if (id != null) {
                    this.checkoutResult = result
                    this.checkoutId = id
                    openCheckoutUI(id)
                } else {
                    result.error("INVALID_ID", "checkoutId is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
        ///////////////////////////////////////////////////////////////////////
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startPaymentCustum" -> {
                        val paymentData = call.argument<Map<String, Any>>("paymentData")
                        if (paymentData != null) {
                            val checkoutId = paymentData["checkoutId"]
                            val brand = paymentData["brand"]
                            val holder = paymentData["cardHolder"]
                            val number = paymentData["cardNumber"]
                            val expiryMonth = paymentData["expiryMonth"]
                            val expiryYear = paymentData["expiryYear"]
                            val cvv = paymentData["cvv"]

                            // Log to Logcat
                            println("📦 Checkout ID: $checkoutId")
                            println("💳 Card Info: $brand, $holder, $number, $expiryMonth/$expiryYear, CVV: $cvv")


                            result.success("Payment data received:$paymentData")
                        } else {
                            result.error("INVALID_DATA", "paymentData is null", null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }


    }



    private fun openCheckoutUI(checkoutId: String) {
        val checkoutSettings = createCheckoutSettings(checkoutId)
        val intent = Intent(this, CheckoutActivity::class.java)
        intent.putExtra(CheckoutActivity.CHECKOUT_SETTINGS, checkoutSettings)
        checkoutLauncher.launch(checkoutSettings)
    }

    private val paymentBrands = linkedSetOf("VISA", "MASTER", "PAYPAL")

    private fun createCheckoutSettings(checkoutId: String): CheckoutSettings {
        return CheckoutSettings(checkoutId, paymentBrands, Connect.ProviderMode.TEST)
            .setSkipCVVMode(CheckoutSkipCVVMode.FOR_STORED_CARDS)
            .setComponentName(ComponentName(packageName, CheckoutBroadcastReceiver::class.java.name))
    }

    private fun handleCheckoutActivityResult(result: CheckoutActivityResult) {
        if (!::checkoutResult.isInitialized) return

        // Always return the checkoutId back to Dart
        checkoutResult.success(checkoutId)
    }
}
