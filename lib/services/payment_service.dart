import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentService {
  late Razorpay _razorpay;

  Function()? onSuccess;
  Function(String)? onError;

  void init({
    required Function() onSuccess,
    required Function(String) onError,
  }) {
    this.onSuccess = onSuccess;
    this.onError = onError;

    _razorpay = Razorpay();

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
  }

  void startPayment({
    required String amount,
    required String email,
    required String phone,
  }) {
    final parsedAmount = double.tryParse(amount);
    if (parsedAmount == null) {
      onError?.call("Invalid amount");
      return;
    }

    var options = {
      'key': 'rzp_test_XXXXXXXX', // 🔥 replace with your key
      'amount': (parsedAmount * 100).toInt(), // paise
      'name': 'Skybase Flights',
      'description': 'Flight Booking',
      'prefill': {
        'contact': phone,
        'email': email,
      },
      'theme': {
        'color': '#3399cc'
      }
    };

    print("💳 Razorpay options => $options");

    try {
      _razorpay.open(options);
    } catch (e) {
      onError?.call(e.toString());
    }
  }

  void _handleSuccess(PaymentSuccessResponse response) {
    print("✅ Payment Success => ${response.paymentId}");
    onSuccess?.call();
  }

  void _handleError(PaymentFailureResponse response) {
    print("❌ Payment Error => ${response.message}");
    onError?.call(response.message ?? "Payment failed");
  }

  void dispose() {
    _razorpay.clear();
  }
}