import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:nativeflutterdemo1/CustomUi/paymentForm.dart';
import 'package:nativeflutterdemo1/CustomUi/stcForm.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

import 'dart:io';

class CustomPaymentScreen extends StatefulWidget {

  const CustomPaymentScreen({super.key});

  @override

  State<CustomPaymentScreen> createState() => _CustomPaymentScreenState();

}

class _CustomPaymentScreenState extends State<CustomPaymentScreen> {

  static const platform = MethodChannel('com.example.first_app/hyperpay');

  String status = "Select a payment method";

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

  Future<void> initiateApplePayCustom() async {

    setState(() => status = "Starting Apple Pay (Custom UI)...");

    try {

      final checkoutId = await fetchCheckoutId();

      print("Apple Pay Custom Checkout ID: $checkoutId");

      final result = await platform.invokeMethod<Map>(

        'startAppleCustom',

        {'checkoutId': checkoutId},

      );

      if (result != null && result['status'] != null) {

        setState(() => status = "Apple Pay (Custom): ${result['status']} - ${result['message']}");

      } else {

        setState(() => status = "Apple Pay (Custom) failed or cancelled");

      }

    } catch (e) {

      print("Apple Pay (Custom) Error: $e");

      setState(() => status = "Apple Pay (Custom) Error: $e");

    }

  }

  @override

  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(title: const Text('HyperPay Custom UI')),

      body: Center(

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            Text(status),

            const SizedBox(height: 30),

            ElevatedButton(

              onPressed: () {

                Navigator.push(

                  context,

                  MaterialPageRoute(builder: (context) => const CardPaymentForm()),

                );

              },

              child: const Text("Pay with Card"),

            ),

            const SizedBox(height: 20),

            ElevatedButton(

              onPressed: () {

                Navigator.push(

                  context,

                  MaterialPageRoute(builder: (context) => const StcPaymentForm()),

                );

              },

              child: const Text("Pay with STC Pay"),

            ),

            const SizedBox(height: 20),

            Platform.isIOS

                ? ElevatedButton(

              onPressed: initiateApplePayCustom,

              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),

              child: const Text(

                "Pay with Apple Pay (Custom)",

                style: TextStyle(color: Colors.white),

              ),

            )

                : const SizedBox.shrink(),

          ],

        ),

      ),

    );

  }

}
