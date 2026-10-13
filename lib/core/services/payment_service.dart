import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentService {
  final Razorpay _razorpay = Razorpay();
  final _supabase = Supabase.instance.client;

  PaymentService() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Completer<bool>? _paymentCompleter;

  void dispose() {
    _razorpay.clear();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (_paymentCompleter != null && !_paymentCompleter!.isCompleted) {
      _paymentCompleter!.complete(true);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (_paymentCompleter != null && !_paymentCompleter!.isCompleted) {
      _paymentCompleter!.complete(false);
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Treat as error/unhandled for MVP
    if (_paymentCompleter != null && !_paymentCompleter!.isCompleted) {
      _paymentCompleter!.complete(false);
    }
  }

  /// Initiates a payment of ₹20. Returns true if successful, false otherwise.
  Future<bool> initiatePayment(String contact, String email) async {
    _paymentCompleter = Completer<bool>();

    try {
      // 1. Get Order ID from Edge Function
      final response = await _supabase.functions.invoke(
        'create-razorpay-order',
        body: {'amount': 2000}, // 2000 paise = ₹20
      );

      if (response.status != 200) {
        throw Exception("Failed to generate order: ${response.data}");
      }

      final data = response.data as Map<String, dynamic>;
      final orderId = data['id'] as String;

      // 2. Open Razorpay Checkout
      final keyId = dotenv.env['RAZORPAY_KEY_ID']?.trim() ?? '';
      
      final validContact = (contact.trim().isEmpty) ? '9999999999' : contact.trim();
      final validEmail = (email.trim().isEmpty) ? 'test@bazzargo.com' : email.trim();

      var options = {
        'key': keyId,
        'amount': 2000, 
        'currency': 'INR',
        'name': 'BazzarGo',
        'order_id': orderId,
        'description': 'Delivery Request Fee',
        'prefill': {
          'contact': validContact,
          'email': validEmail,
        }
      };

      _razorpay.open(options);

      return await _paymentCompleter!.future;
    } catch (e) {
      print("Payment Error: $e");
      return false;
    }
  }
}
