import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Card Payment Form using Custom UI with HyperPay
class CardPaymentForm extends StatefulWidget {
  const CardPaymentForm({super.key});

  @override
  State<CardPaymentForm> createState() => _CardPaymentFormState();
}

class _CardPaymentFormState extends State<CardPaymentForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  final _cardHolderController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  // Selected brand and available options
  String? _selectedBrand;
  final List<String> _brands = ['VISA', 'MASTER', 'MADA', 'AMEX'];

  // Method channel to communicate with native Android code
  static const platform = MethodChannel('com.example.nativeflutterdemo1/hyperpay');

  @override
  void initState() {
    super.initState();
    // Listen to card number changes to auto-detect brand
    _cardNumberController.addListener(_detectCardBrand);
  }

  /// Auto-detects the card brand based on number prefix
  void _detectCardBrand() {
    final input = _cardNumberController.text.replaceAll(RegExp(r'\s+'), '');

    String? brand;
    if (input.startsWith(RegExp(r'^4'))) {
      brand = 'VISA';
    } else if (input.startsWith(RegExp(r'^(5[1-5]|222[1-9]|22[3-9]|2[3-7])'))) {
      brand = 'MASTER';
    } else if (input.startsWith(RegExp(r'^(4(086|187)|5(060|065|081)|6(059|002|005))'))) {
      brand = 'MADA';
    } else if (input.startsWith(RegExp(r'^3[47]'))) {
      brand = 'AMEX';
    }

    if (brand != null && brand != _selectedBrand) {
      setState(() {
        _selectedBrand = brand;
      });
    }
  }

  /// Fetches checkout ID from backend
  Future<String> fetchCheckoutId() async {
    final response = await http.post(
      Uri.parse("https://integration.hyperpay.com/hyperpay-demo/getcheckoutid.php"),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data;
    } else {
      throw Exception("Failed to fetch checkout ID");
    }
  }

  /// Fetches final payment status using checkout ID
  Future<String> fetchPaymentStatus(String id) async {
    final url = Uri.parse('https://integration.hyperpay.com/hyperpay-demo/getpaymentstatus.php?id=$id');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to fetch payment status');
    }
  }

  /// Submits the form and triggers native payment flow
  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      final expiryParts = _expiryController.text.split('/');
      final expiryMonth = expiryParts[0];
      final expiryYear = expiryParts[1];

      try {
        final checkoutId = await fetchCheckoutId();

        // Prepare data to send to Android via platform channel
        final paymentData = {
          "checkoutId": checkoutId,
          "brand": _selectedBrand,
          "cardHolder": _cardHolderController.text,
          "cardNumber": _cardNumberController.text.replaceAll(' ', ''),
          "expiryMonth": expiryMonth,
          "expiryYear": expiryYear,
          "cvv": _cvvController.text,
        };

        // Invoke native Android code
        final result = await platform.invokeMethod("startPaymentCustom", {'paymentData': paymentData});
        final returnedId = result is Map ? result['checkoutId'] : result;

        if (returnedId != null && returnedId is String) {
          final paymentStatus = await fetchPaymentStatus(returnedId);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Payment Status: $paymentStatus")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Invalid payment ID received")),
          );
        }
      } on PlatformException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Platform Error: ${e.message}")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("General Error: $e")),
        );
      }
    }
  }

  /// Luhn algorithm validation for card number
  bool _isValidLuhn(String number) {
    int sum = 0;
    bool alternate = false;

    for (int i = number.length - 1; i >= 0; i--) {
      int n = int.parse(number[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }

  @override
  void dispose() {
    // Dispose of all controllers to avoid memory leaks
    _cardHolderController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = _selectedBrand ?? '';
    final isAmex = brand == 'AMEX';
    final cvvLength = isAmex ? 4 : 3;

    return Scaffold(
      appBar: AppBar(title: const Text("Custom UI Payment")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Dropdown for payment brand
              DropdownButtonFormField<String>(
                value: _selectedBrand,
                decoration: const InputDecoration(
                  labelText: "Payment Brand",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || !_brands.contains(value)) {
                    return 'Please select a valid payment brand';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _selectedBrand = value;
                  });
                },
                items: _brands.map((brand) {
                  return DropdownMenuItem<String>(
                    value: brand,
                    child: Text(brand),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Card Number
              TextFormField(
                controller: _cardNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Card Number",
                  border: OutlineInputBorder(),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return "Card number is required";

                  final number = value.replaceAll(RegExp(r'\s+'), '');
                  if (_selectedBrand == 'AMEX' && number.length != 15) return "AMEX card must be 15 digits";
                  if (_selectedBrand != 'AMEX' && number.length != 16) return "Card number must be 16 digits";
                  if (!_isValidLuhn(number)) return "Invalid card number";
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Card Holder
              TextFormField(
                controller: _cardHolderController,
                keyboardType: TextInputType.name,
                decoration: const InputDecoration(
                  labelText: "Card Holder Name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return "Enter card holder name";
                  if (!RegExp(r"^[A-Za-z ]+$").hasMatch(value)) return "Name must contain letters only";
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Expiry and CVV Row
              Row(
                children: [
                  // Expiry Date MM/YY
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _expiryController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Expiry (MM/YY)",
                        hintText: "MM/YY",
                        border: OutlineInputBorder(),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                        _ExpiryDateTextInputFormatter(),
                      ],
                      validator: (value) {
                        if (value == null || !RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
                          return "Invalid MM/YY format";
                        }

                        final expiryParts = value.split('/');
                        final expiryMonth = int.parse(expiryParts[0]);
                        final expiryYear = int.parse(expiryParts[1]);

                        if (expiryMonth < 1 || expiryMonth > 12) {
                          return "Month must be between 01 and 12.";
                        }

                        final now = DateTime.now();
                        final currentYear = now.year % 100;
                        final currentMonth = now.month;

                        if (expiryYear < currentYear ||
                            (expiryYear == currentYear && expiryMonth < currentMonth)) {
                          return "Card expired";
                        }

                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),

                  // CVV
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _cvvController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "CVV",
                        border: OutlineInputBorder(),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(cvvLength),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) return "CVV is required";

                        if (_selectedBrand != null) {
                          if (isAmex && value.length != 4) {
                            return "AMEX CVV must be 4 digits";
                          } else if (!isAmex && value.length != 3) {
                            return "CVV must be 3 digits";
                          }
                        } else if (value.length < 3 || value.length > 4) {
                          return "CVV must be 3 or 4 digits";
                        }

                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Submit button
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text("Pay Now"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Formatter to auto-insert "/" in expiry field
class _ExpiryDateTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    var text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (text.length >= 3) {
      text = '${text.substring(0, 2)}/${text.substring(2, text.length.clamp(2, 4))}';
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
