package com.example.nativeflutterdemo1

import android.app.Activity
import android.content.ComponentName
import android.content.Intent
import android.os.Bundle
import android.util.Log
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import androidx.annotation.NonNull
import com.oppwa.mobile.connect.checkout.dialog.CheckoutActivity
import com.oppwa.mobile.connect.checkout.meta.*
import com.oppwa.mobile.connect.demo.receiver.CheckoutBroadcastReceiver
import com.oppwa.mobile.connect.provider.Connect
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    private lateinit var checkoutResult: MethodChannel.Result
    private lateinit var checkoutLauncher: ActivityResultLauncher<CheckoutSettings>
    private lateinit var customUIResultLauncher: ActivityResultLauncher<Intent>
    private lateinit var checkoutId: String

    companion object {
        const val CHANNEL = "com.example.nativeflutterdemo1/hyperpay"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Register launcher for Ready UI results
        checkoutLauncher = registerForActivityResult(CheckoutActivityResultContract()) { result ->
            handleCheckoutActivityResult(result)
        }

        // Register launcher for Custom UI / STC Pay results
        customUIResultLauncher = registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
            handleCustomUIResult(result.resultCode, result.data)
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Set up Flutter method channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    // Start Ready UI
                    "startPayment" -> {
                        val id = call.argument<String>("checkoutId")
                        if (id != null) {
                            checkoutResult = result
                            checkoutId = id
                            openCheckoutUI(id)
                        } else {
                            result.error("INVALID_ID", "checkoutId is null", null)
                        }
                    }

                    // Start Custom UI activity
                    "startPaymentCustom" -> {
                        val paymentData = call.argument<Map<String, Any>>("paymentData")
                        if (paymentData != null) {
                            checkoutResult = result
                            val intent = Intent(this, CustomUIActivity::class.java)
                            intent.putExtra("paymentData", HashMap(paymentData))
                            customUIResultLauncher.launch(intent)
                        } else {
                            result.error("INVALID_DATA", "paymentData is null", null)
                        }
                    }

                    // Start STC Pay activity
                    "startStcPay" -> {
                        val paymentData = call.argument<Map<String, Any>>("paymentData")
                        if (paymentData != null) {
                            checkoutResult = result
                            val intent = Intent(this, StcPayActivity::class.java)
                            intent.putExtra("paymentData", HashMap(paymentData))
                            customUIResultLauncher.launch(intent)
                        } else {
                            result.error("INVALID_DATA", "paymentData is null", null)
                        }
                    }

                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                Log.e("MainActivity", "Exception in method call: ${call.method}", e)
                result.error("EXCEPTION", "Exception: ${e.localizedMessage}", null)
            }
        }
    }

    // Launch the Ready UI checkout screen
    private fun openCheckoutUI(checkoutId: String) {
        try {
            val checkoutSettings = createCheckoutSettings(checkoutId)
            val intent = Intent(this, CheckoutActivity::class.java)
            intent.putExtra(CheckoutActivity.CHECKOUT_SETTINGS, checkoutSettings)
            checkoutLauncher.launch(checkoutSettings)
        } catch (e: Exception) {
            Log.e("MainActivity", "Error launching CheckoutActivity", e)
            if (::checkoutResult.isInitialized) {
                checkoutResult.error("EXCEPTION", "Failed to launch Checkout UI: ${e.localizedMessage}", null)
            }
        }
    }

    // Supported brands for Ready UI
    private val paymentBrands = linkedSetOf("VISA", "MASTER", "PAYPAL")

    // Build settings for Ready UI
    private fun createCheckoutSettings(checkoutId: String): CheckoutSettings {
        return CheckoutSettings(checkoutId, paymentBrands, Connect.ProviderMode.TEST)
            .setSkipCVVMode(CheckoutSkipCVVMode.FOR_STORED_CARDS)
            .setComponentName(ComponentName(packageName, CheckoutBroadcastReceiver::class.java.name))
    }

    // Handle the result of Ready UI
    private fun handleCheckoutActivityResult(result: CheckoutActivityResult) {
        if (!::checkoutResult.isInitialized) return
        checkoutResult.success(checkoutId)
    }

    // Handle the result of custom UI or STC Pay
    private fun handleCustomUIResult(resultCode: Int, data: Intent?) {
        Log.d("MainActivity", "handleCustomUIResult called")
        if (!::checkoutResult.isInitialized) return

        try {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val resultMap = mapOf(
                    "status" to data.getStringExtra("status"),
                    "message" to data.getStringExtra("message"),
                    "checkoutId" to data.getStringExtra("checkoutId")
                )
                checkoutResult.success(resultMap)
            } else {
                checkoutResult.error("CANCELLED", "Custom UI activity was cancelled", null)
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Exception in handleCustomUIResult", e)
            checkoutResult.error("EXCEPTION", "Result handling error: ${e.localizedMessage}", null)
        }
    }
}
