import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';

class LocationController extends GetxController {
  // MAIN STATE
  RxBool isLocationEnabled = false.obs;

  // ✅ BACKWARD-COMPATIBLE ALIAS (THIS FIXES YOUR ERROR)
  RxBool get locationEnabled => isLocationEnabled;

  @override
  void onInit() {
    super.onInit();
    checkLocationStatus();
  }

  Future<void> checkLocationStatus() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    isLocationEnabled.value = serviceEnabled;
  }

  Future<void> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      isLocationEnabled.value = true;
    }
  }
}
