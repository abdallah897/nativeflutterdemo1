import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReadyPaymentScreen extends StatefulWidget {
  const ReadyPaymentScreen({super.key});

  @override
  State<ReadyPaymentScreen> createState() => _ReadyPaymentScreenState();
}

class _ReadyPaymentScreenState extends State<ReadyPaymentScreen> {
  final _formKey = GlobalKey<FormState>();

  final _cardHolderController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  String? _selectedBrand;
  final List<String> _brands = ['VISA', 'MASTER', 'MADA', 'AMEX'];

  static const platform = MethodChannel('com.example.nativeflutterdemo1/hyperpay');

  Future<String> fetchCheckoutId() async {
    final response = await http.post(
      Uri.parse("https://dev.hyperpay.com/hyperpay-demo/getcheckoutid.php"),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData.containsKey('id')) {
        return jsonData['id'];
      } else {
        throw Exception("Checkout ID not found in response");
      }
    } else {
      throw Exception("Failed to fetch checkout ID");
    }
  }

  @override
  void dispose() {
    _cardHolderController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      final expiryParts = _expiryController.text.split('/');
      final expiryMonth = expiryParts[0];
      final expiryYear = expiryParts[1];

      final checkoutId = await fetchCheckoutId();

      final paymentData = {
        "checkoutId": checkoutId,
        "brand": _selectedBrand,
        "cardHolder": _cardHolderController.text,
        "cardNumber": _cardNumberController.text.replaceAll(' ', ''),
        "expiryMonth": expiryMonth,
        "expiryYear": expiryYear,
        "cvv": _cvvController.text,
      };

      try {
        final result = await platform.invokeMethod("startPaymentCustum", {
          'paymentData': paymentData,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Payment Completed: $result")),
        );

        // Fetch final payment status
        final statusResponse = await http.get(
          Uri.parse("https://dev.hyperpay.com/hyperpay-demo/getpaymentstatus.php?id=$checkoutId"),
        );

        if (statusResponse.statusCode == 200) {
          final statusJson = json.decode(statusResponse.body);
          final status = statusJson['result']['description'] ?? "Unknown status";

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Payment Status: $status")),
          );
        } else {
          throw Exception("Failed to fetch payment status");
        }
      } on PlatformException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.message}")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Unexpected error: $e")),
        );
      }
    }
  }

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Custom UI Payment")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              FormField<String>(
                initialValue: _selectedBrand,
                validator: (value) {
                  if (value == null || !_brands.contains(value)) {
                    return 'Please select a valid payment brand';
                  }
                  return null;
                },
                builder: (FormFieldState<String> field) {
                  return InputDecorator(
                    decoration: InputDecoration(
                      labelText: "Payment Brand",
                      border: const OutlineInputBorder(),
                      errorText: field.errorText,
                    ),
                    isEmpty: field.value == null || field.value!.isEmpty,
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: field.value,
                        isDense: true,
                        onChanged: (value) {
                          setState(() {
                            _selectedBrand = value;
                            field.didChange(value);
                          });
                        },
                        items: _brands
                            .map((brand) => DropdownMenuItem(
                          value: brand,
                          child: Text(brand),
                        ))
                            .toList(),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cardNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Card Number",
                  border: OutlineInputBorder(),
                ),
                inputFormatters: [
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
              Row(
                children: [
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

                        final currentDate = DateTime.now();
                        final currentYear = currentDate.year % 100;
                        final currentMonth = currentDate.month;

                        if (expiryMonth < 1 || expiryMonth > 12) return "Invalid expiry month";
                        if (expiryYear < currentYear || (expiryYear == currentYear && expiryMonth < currentMonth)) {
                          return "Card is expired";
                        }

                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _cvvController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "CVV",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return "CVV is required";
                        if (!RegExp(r'^\d+$').hasMatch(value)) return "CVV must be digits only";

                        final length = value.length;
                        if (_selectedBrand == 'AMEX' && length != 4) return "AMEX CVV must be 4 digits";
                        if (_selectedBrand != 'AMEX' && length != 3) return "CVV must be 3 digits";
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text("Submit Payment"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpiryDateTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');

    String formatted = '';
    if (digitsOnly.length >= 2) {
      formatted = digitsOnly.substring(0, 2);
      if (digitsOnly.length > 2) {
        formatted += '/' +
            digitsOnly.substring(2, digitsOnly.length > 4 ? 4 : digitsOnly.length);
      }
    } else {
      formatted = digitsOnly;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
