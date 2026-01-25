import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';

class LocationController extends GetxController {
  // Location ON / OFF status
  RxBool isLocationEnabled = false.obs;

  @override
  void onInit() {
    super.onInit();
    checkLocationStatus();
  }

  /// Check if location service + permission is enabled
  Future<void> checkLocationStatus() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      isLocationEnabled.value = false;
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      isLocationEnabled.value = false;
    } else {
      isLocationEnabled.value = true;
    }
  }

  /// Request permission from user
  Future<void> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      isLocationEnabled.value = true;
    } else {
      isLocationEnabled.value = false;
    }
  }
}
