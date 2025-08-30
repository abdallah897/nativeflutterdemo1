import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;

/// A simple Flutter UI that demonstrates HyperPay Prebuilt UI payment
class ReadyPaymentScreen extends StatefulWidget {
  const ReadyPaymentScreen({super.key});

  @override
  State<ReadyPaymentScreen> createState() => _ReadyPaymentScreen();
}

class _ReadyPaymentScreen extends State<ReadyPaymentScreen> {
  static const platform = MethodChannel('com.example.nativeflutterdemo1/hyperpay');

  String status = "Ready to pay";

  /// Calls your backend to get a checkout ID
  Future<String> fetchCheckoutId() async {
    try {
      final response = await http.post(
        Uri.parse("https://integration.hyperpay.com/hyperpay-demo/getcheckoutid.php"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is String && data.isNotEmpty) {
          return data;
        } else {
          throw Exception("Invalid checkout ID response");
        }
      } else {
        throw Exception("Failed to fetch checkout ID (HTTP ${response.statusCode})");
      }
    } catch (e) {
      debugPrint("fetchCheckoutId error: $e");
      rethrow;
    }
  }

  /// Initiates the payment using the HyperPay native method channel
  Future<void> initiatePayment() async {
    setState(() => status = "Fetching checkout ID...");

    try {
      // Step 1: Get checkout ID from backend
      final checkoutId = await fetchCheckoutId();
      debugPrint("Checkout ID: $checkoutId");

      // Step 2: Start payment via native code (Prebuilt UI)
      final returnedId = await platform.invokeMethod<String>(
        'startPayment',
        {'checkoutId': checkoutId},
      );

      if (returnedId == null || returnedId.isEmpty) {
        setState(() => status = "No checkout ID returned from SDK");
        return;
      }

      debugPrint("Returned checkout ID from native: $returnedId");
      setState(() => status = "Checking payment status...");

      // Step 3: Call backend again to verify transaction result
      final statusResponse = await http.get(
        Uri.parse("https://integration.hyperpay.com/hyperpay-demo/getpaymentstatus.php?id=$returnedId"),
      );

      debugPrint("Payment status response: ${statusResponse.body}");

      if (statusResponse.statusCode == 200) {
        final statusJson = json.decode(statusResponse.body);
        String? description;

        // Handle multiple possible formats of the response
        if (statusJson['result'] != null && statusJson['result']['description'] != null) {
          description = statusJson['result']['description'];
        } else if (statusJson['description'] != null) {
          description = statusJson['description'];
        } else {
          description = "Unknown response format.";
        }

        setState(() => status = "Payment Status: $description");
      } else {
        setState(() => status = "Failed to get payment status (HTTP ${statusResponse.statusCode})");
      }
    } on PlatformException catch (e) {
      // Flutter <-> native communication failed
      debugPrint("PlatformException: ${e.message}");
      setState(() => status = "Platform error: ${e.message}");
    } catch (e) {
      // Any other error (network, logic, backend)
      debugPrint("Error: $e");
      setState(() => status = "Error: $e");
    }
  }

  /// Initiates the payment using Apple Pay via native code
  Future<void> initiateApplePay() async {
    setState(() => status = "Starting Apple Pay...");

    try {
      final checkoutId = await fetchCheckoutId();
      debugPrint("Apple Pay Checkout ID: $checkoutId");

      final result = await platform.invokeMethod<Map>(
        'startApplePay',
        {'checkoutId': checkoutId},
      );

      if (result != null && result['status'] != null) {
        setState(() => status = "Apple Pay: ${result['status']} - ${result['message']}");
      } else {
        setState(() => status = "Apple Pay failed or cancelled");
      }
    } on PlatformException catch (e) {
      debugPrint("Apple Pay PlatformException: ${e.message}");
      setState(() => status = "Apple Pay Platform Error: ${e.message}");
    } catch (e) {
      debugPrint("Apple Pay Error: $e");
      setState(() => status = "Apple Pay Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("HyperPay Demo")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(status, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: initiatePayment,
              child: const Text("Pay Now"),
            ),
            const SizedBox(height: 20),
            if (Platform.isIOS)
              ElevatedButton(
                onPressed: initiateApplePay,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                child: const Text("Pay with Apple Pay", style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }
}