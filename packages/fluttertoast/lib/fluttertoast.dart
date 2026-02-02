// Local stub of fluttertoast for compile-time only.

enum Toast {
  LENGTH_SHORT,
  LENGTH_LONG,
}

enum ToastGravity { TOP, BOTTOM, CENTER }

class Fluttertoast {
  static Future<void> showToast({
    required String msg,
    Toast? toastLength,
    ToastGravity? gravity,
    int? timeInSecForIosWeb,
  }) async {
    // no-op stub
  }
}
