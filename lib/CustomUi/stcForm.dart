import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

/// A Flutter screen to handle STC Pay payment using native integration.
class StcPaymentForm extends StatefulWidget {
  const StcPaymentForm({Key? key}) : super(key: key);

  @override
  State<StcPaymentForm> createState() => _STCFormState();
}

class _STCFormState extends State<StcPaymentForm> {
  static const platform = MethodChannel('com.example.nativeflutterdemo1/hyperpay');

  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  String? _paymentStatus;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  /// Main submit method triggered by UI
  Future<void> _submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final phoneNumber = _phoneController.text.trim();

    setState(() {
      _isLoading = true;
      _paymentStatus = null;
    });

    try {
      // Step 1: Fetch checkout ID from backend
      final checkoutId = await _fetchCheckoutId(phoneNumber);

      // Step 2: Call native platform method to start STC Pay flow
      final Map<dynamic, dynamic>? resultMap = await platform.invokeMethod('startStcPay', {
        'paymentData': {
          'checkoutId': checkoutId,
          'brand': 'STC_PAY',
        },
      }).then((result) {
        if (result is Map) return result;
        return null;
      });

      if (resultMap == null) throw Exception("No result from native STC Pay process");

      final status = resultMap['status'] as String? ?? 'error';
      final errorMessage = resultMap['message'] as String? ?? '';
      final returnedCheckoutId = resultMap['checkoutId'] as String? ?? '';

      if (status == 'error') throw Exception("Payment failed: $errorMessage");
      if (returnedCheckoutId.isEmpty) throw Exception("Empty checkout ID received");

      // Step 3: Check payment status using checkout ID
      final paymentStatus = await fetchPaymentStatus(returnedCheckoutId);

      setState(() {
        _paymentStatus = paymentStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment Status: $paymentStatus')),
      );
    } on PlatformException catch (e) {
      // Catch Flutter <-> Native communication errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment Error (Platform): ${e.message}')),
      );
    } catch (e) {
      // Catch any other errors (network, logic, data, etc.)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Fetches the checkout ID from your backend (you can adjust the URL).
  Future<String> _fetchCheckoutId(String phoneNumber) async {
    try {
      final response = await http.post(
        Uri.parse("https://integration.hyperpay.com/hyperpay-demo/getcheckoutid.php?phonenumber=$phoneNumber"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is String && data.isNotEmpty) {
          return data;
        } else {
          throw Exception("Invalid response format: $data");
        }
      } else {
        throw Exception("Failed to fetch checkout ID: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching checkout ID: $e");
      rethrow;
    }
  }

  /// Fetches payment status after transaction is complete.
  Future<String> fetchPaymentStatus(String id) async {
    try {
      final url = Uri.parse('https://integration.hyperpay.com/hyperpay-demo/getpaymentstatus.php?id=$id');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception('Failed to fetch payment status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("Error fetching payment status: $e");
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("STC Pay")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '05XXXXXXXX',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Phone number is required';
                  }
                  if (!RegExp(r'^05\d{8}$').hasMatch(value)) {
                    return 'Enter a valid 10-digit number starting with 05';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit STC Pay"),
              ),
              if (_paymentStatus != null) ...[
                const SizedBox(height: 8),
                Text('Payment Status: $_paymentStatus'),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
