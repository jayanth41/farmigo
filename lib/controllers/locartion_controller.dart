import 'package:get/get.dart';

class LocationController extends GetxController {
  var currentLocation = "Hyderabad".obs;

  void setLocation(String location) {
    currentLocation.value = location;
  }
}
