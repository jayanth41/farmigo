// Local stub of razorpay_flutter for compile-time only.

class Razorpay {
  Razorpay();

  void on(String event, Function handler) {
    // no-op in stub
  }

  void open(Map<String, dynamic> options) {
    // no-op in stub
  }

  void clear() {}

  static const String EVENT_PAYMENT_SUCCESS = 'payment.success';
  static const String EVENT_PAYMENT_ERROR = 'payment.error';
  static const String EVENT_EXTERNAL_WALLET = 'external.wallet';
}

class PaymentSuccessResponse {
  final String? paymentId;
  final String? orderId;
  final String? signature;

  PaymentSuccessResponse({this.paymentId, this.orderId, this.signature});
}

class PaymentFailureResponse {
  final int? code;
  final String? message;

  PaymentFailureResponse({this.code, this.message});
}

class ExternalWalletResponse {
  final String? walletName;

  ExternalWalletResponse({this.walletName});
}
