import 'dart:async';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../constants/app_constants.dart';

/// Comprehensive payment gateway service supporting multiple providers
class PaymentGatewayService {
  final Dio _dio;
  late Razorpay _razorpay;

  // Callbacks
  Function(PaymentSuccessData)? _onSuccess;
  Function(PaymentErrorData)? _onError;

  PaymentGatewayService(this._dio) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorpaySuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorpayError);
  }

  /// Initialize Stripe
  Future<void> initializeStripe(String publishableKey) async {
    Stripe.publishableKey = publishableKey;
    await Stripe.instance.applySettings();
  }

  /// Get available payment methods from backend
  Future<List<PaymentMethodInfo>> getPaymentMethods() async {
    try {
      developer.log(
        'PaymentGatewayService: Fetching payment methods from ${ApiEndpoints.paymentMethods}',
      );
      final response = await _dio.get(ApiEndpoints.paymentMethods);
      developer.log(
        'PaymentGatewayService: Response status: ${response.statusCode}',
      );
      developer.log('PaymentGatewayService: Response data: ${response.data}');

      final data = response.data['data'] as List;
      developer.log(
        'PaymentGatewayService: Found ${data.length} payment methods',
      );

      final methods = data.map((e) => PaymentMethodInfo.fromJson(e)).toList();

      for (var method in methods) {
        developer.log(
          '  - ${method.name} (${method.id}/${method.type}) - Enabled: ${method.isEnabled}',
        );
      }

      return methods;
    } catch (e, stackTrace) {
      developer.log('Error loading payment methods: $e');
      developer.log('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Initialize payment with backend
  Future<PaymentInitData> initializePayment({
    required int orderId,
    required double amount,
    required String paymentMethod,
    required String currency,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.paymentInitialize,
        data: {
          'order_id': orderId,
          'payment_gateway': paymentMethod, // Backend expects 'payment_gateway'
          'currency': currency,
        },
      );

      return PaymentInitData.fromJson(response.data);
    } catch (e) {
      developer.log('Error initializing payment: $e');
      rethrow;
    }
  }

  /// Process Razorpay payment
  Future<void> processRazorpayPayment({
    required PaymentInitData initData,
    required String name,
    required String email,
    required String phone,
    required Function(PaymentSuccessData) onSuccess,
    required Function(PaymentErrorData) onError,
  }) async {
    _onSuccess = onSuccess;
    _onError = onError;

    final options = {
      'key': initData.gatewayData['key_id'],
      'amount': int.parse(
        initData.gatewayData['amount'].toString(),
      ), // Convert to int (paise)
      'currency': initData.gatewayData['currency'] ?? 'INR',
      'name': 'InAllCart',
      'description': 'Order Payment',
      'order_id': initData.gatewayData['order_id'], // Razorpay order ID
      'prefill': {'contact': phone, 'email': email, 'name': name},
      'theme': {'color': '#FF6B35'},
      // Explicitly enable all payment methods
      'method': {
        'netbanking': true,
        'card': true,
        'upi': true,
        'wallet': true,
        'emi': false,
        'paylater': false,
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      _onError?.call(
        PaymentErrorData(code: 'RAZORPAY_ERROR', message: e.toString()),
      );
    }
  }

  /// Process Stripe payment
  Future<PaymentSuccessData> processStripePayment({
    required PaymentInitData initData,
    required String email,
  }) async {
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: initData.gatewayData['client_secret'],
          merchantDisplayName: 'InAllCart',
          style: ThemeMode.system,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      return PaymentSuccessData(
        paymentId: initData.gatewayData['payment_intent_id'],
        orderId: initData.orderId.toString(),
        method: 'stripe',
      );
    } on StripeException catch (e) {
      throw PaymentErrorData(
        code: e.error.code.toString(),
        message: e.error.localizedMessage ?? 'Payment failed',
      );
    }
  }

  /// Process Paystack payment (WebView-based)
  Future<PaymentSuccessData> processPaystackPayment({
    required PaymentInitData initData,
    required BuildContext context,
  }) async {
    final completer = Completer<PaymentSuccessData>();

    // Navigate to WebView payment page
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PaymentWebView(
              url: initData.gatewayData['authorization_url'] as String,
              onSuccess: (reference) {
                completer.complete(
                  PaymentSuccessData(
                    paymentId: reference,
                    orderId: initData.orderId.toString(),
                    method: 'paystack',
                  ),
                );
              },
              onError: (error) {
                completer.completeError(
                  PaymentErrorData(code: 'PAYSTACK_ERROR', message: error),
                );
              },
            ),
      ),
    );

    return completer.future;
  }

  /// Process Flutterwave payment (WebView-based)
  Future<PaymentSuccessData> processFlutterwavePayment({
    required PaymentInitData initData,
    required BuildContext context,
  }) async {
    final completer = Completer<PaymentSuccessData>();

    // Navigate to WebView payment page
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PaymentWebView(
              url: initData.gatewayData['link'] as String,
              onSuccess: (reference) {
                completer.complete(
                  PaymentSuccessData(
                    paymentId: reference,
                    orderId: initData.orderId.toString(),
                    method: 'flutterwave',
                  ),
                );
              },
              onError: (error) {
                completer.completeError(
                  PaymentErrorData(code: 'FLUTTERWAVE_ERROR', message: error),
                );
              },
            ),
      ),
    );

    return completer.future;
  }

  /// Process PhonePe payment (WebView-based)
  Future<PaymentSuccessData> processPhonePePayment({
    required PaymentInitData initData,
    required BuildContext context,
  }) async {
    final completer = Completer<PaymentSuccessData>();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PaymentWebView(
              url: initData.gatewayData['payment_url'] as String,
              onSuccess: (reference) {
                completer.complete(
                  PaymentSuccessData(
                    paymentId: reference,
                    orderId: initData.orderId.toString(),
                    method: 'phonepe',
                  ),
                );
              },
              onError: (error) {
                completer.completeError(
                  PaymentErrorData(code: 'PHONEPE_ERROR', message: error),
                );
              },
            ),
      ),
    );

    return completer.future;
  }

  /// Process Paytm payment (WebView-based)
  Future<PaymentSuccessData> processPaytmPayment({
    required PaymentInitData initData,
    required BuildContext context,
  }) async {
    final completer = Completer<PaymentSuccessData>();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PaymentWebView(
              url: initData.gatewayData['payment_url'] as String,
              onSuccess: (reference) {
                completer.complete(
                  PaymentSuccessData(
                    paymentId: reference,
                    orderId: initData.orderId.toString(),
                    method: 'paytm',
                  ),
                );
              },
              onError: (error) {
                completer.completeError(
                  PaymentErrorData(code: 'PAYTM_ERROR', message: error),
                );
              },
            ),
      ),
    );

    return completer.future;
  }

  /// Verify payment with backend
  Future<bool> verifyPayment({
    required int orderId,
    required String paymentId,
    required String paymentMethod,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.paymentVerify,
        data: {
          'order_id': orderId,
          'payment_gateway': paymentMethod, // Backend expects 'payment_gateway'
          'transaction_id': paymentId,
          ...?additionalData,
        },
      );

      return response.data['success'] == true;
    } catch (e) {
      developer.log('Error verifying payment: $e');
      rethrow;
    }
  }

  void _handleRazorpaySuccess(PaymentSuccessResponse response) {
    developer.log('Razorpay Success: ${response.paymentId}');
    _onSuccess?.call(
      PaymentSuccessData(
        paymentId: response.paymentId!,
        orderId: response.orderId!,
        signature: response.signature,
        method: 'razorpay',
      ),
    );
  }

  void _handleRazorpayError(PaymentFailureResponse response) {
    developer.log('Razorpay Error: ${response.code} - ${response.message}');
    _onError?.call(
      PaymentErrorData(
        code: response.code.toString(),
        message: response.message ?? 'Payment failed',
      ),
    );
  }

  void dispose() {
    _razorpay.clear();
  }
}

// Data classes
class PaymentMethodInfo {
  final String id;
  final String name;
  final String type;
  final String? icon;
  final bool isEnabled;
  final Map<String, dynamic>? config;

  PaymentMethodInfo({
    required this.id,
    required this.name,
    required this.type,
    this.icon,
    this.isEnabled = true,
    this.config,
  });

  factory PaymentMethodInfo.fromJson(Map<String, dynamic> json) {
    return PaymentMethodInfo(
      id: json['name'] as String, // Backend returns 'name' as ID
      name: json['display_name'] as String? ?? json['name'] as String,
      type: json['name'] as String, // Use 'name' as type
      icon: json['icon'] as String?,
      isEnabled: json['is_enabled'] as bool? ?? true,
      config:
          json['config'] as Map<String, dynamic>? ??
          (json['bank_details'] != null
              ? {'bank_details': json['bank_details']}
              : null),
    );
  }

  bool get isCOD => type == 'cod' || type == 'cash';
  bool get isOnline => !isCOD && type != 'bank_transfer';
}

class PaymentInitData {
  final int orderId;
  final String? paymentId;
  final double amount;
  final String currency;
  final Map<String, dynamic> gatewayData;
  final bool success;
  final String? message;

  PaymentInitData({
    required this.orderId,
    this.paymentId,
    required this.amount,
    required this.currency,
    required this.gatewayData,
    required this.success,
    this.message,
  });

  factory PaymentInitData.fromJson(Map<String, dynamic> json) {
    // Backend returns different structure based on gateway
    final success = json['success'] as bool? ?? false;

    // Handle orderId - can be int or string depending on gateway
    int orderId = 0;
    if (json['order_id'] is int) {
      orderId = json['order_id'] as int;
    } else if (json['order_id'] is String) {
      orderId = int.tryParse(json['order_id']) ?? 0;
    }

    return PaymentInitData(
      orderId: orderId,
      paymentId:
          json['order_id']?.toString() ??
          json['payment_intent_id'] as String? ??
          json['reference'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'USD',
      gatewayData: json, // Store entire response as gateway data
      success: success,
      message: json['message'] as String?,
    );
  }
}

class PaymentSuccessData {
  final String paymentId;
  final String orderId;
  final String? signature;
  final String method;

  PaymentSuccessData({
    required this.paymentId,
    required this.orderId,
    this.signature,
    required this.method,
  });
}

class PaymentErrorData {
  final String code;
  final String message;

  PaymentErrorData({required this.code, required this.message});
}

/// WebView widget for payment gateways that require web-based checkout
class PaymentWebView extends StatefulWidget {
  final String url;
  final Function(String reference) onSuccess;
  final Function(String error) onError;

  const PaymentWebView({
    super.key,
    required this.url,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (url) {
                setState(() => _isLoading = true);
              },
              onPageFinished: (url) {
                setState(() => _isLoading = false);
                _checkPaymentStatus(url);
              },
              onWebResourceError: (error) {
                widget.onError(error.description);
                Navigator.pop(context);
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.url));
  }

  void _checkPaymentStatus(String url) {
    // Check for success/failure callbacks in URL
    if (url.contains('payment/success') || url.contains('status=success')) {
      // Extract reference from URL
      final uri = Uri.parse(url);
      final reference =
          uri.queryParameters['reference'] ??
          uri.queryParameters['trxref'] ??
          uri.queryParameters['transaction_id'] ??
          'unknown';
      widget.onSuccess(reference);
      Navigator.pop(context);
    } else if (url.contains('payment/cancel') ||
        url.contains('status=cancel')) {
      widget.onError('Payment cancelled by user');
      Navigator.pop(context);
    } else if (url.contains('payment/failed') ||
        url.contains('status=failed')) {
      widget.onError('Payment failed');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            widget.onError('Payment cancelled by user');
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
