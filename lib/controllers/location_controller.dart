import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

class LocationController extends GetxController {
  RxBool isLocationEnabled = false.obs;
  RxString selectedState = "Telangana".obs;

  @override
  void onInit() {
    super.onInit();
    checkLocationStatus();
  }

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

  Future<void> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      isLocationEnabled.value = true;
    } else {
      isLocationEnabled.value = false;
    }
  }

  void openStateSelector(BuildContext context) {
    final states = [ "Andhra Pradesh", "Arunachal Pradesh" ,"Assam","Bihar","Chhatisgarh","Goa","Gujarat","Haryana","Himachal Pradesh","Jharkhand","Karnataka","Kerala","Madhya Pradesh", "Maharashtra" ,"Manipur","Meghalaya","Mizoram","Nagaland","Odisha","Punjab","Rajasthan","Sikkim","Tamil Nadu","Telangana","Tripura","Uttar Pradesh","Uttarakhand","West Bengal","Andaman and Nicobar Islands","Chandigarh","Dadra and Nagar Haveli and Daman and Diu","Delhi","Jammu and Kashmir","Ladakh","Lakshadweep","Puducherry"];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ListView(
        children: states.map((state) {
          return ListTile(
            title: Text(state),
            trailing: state == selectedState.value
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () {
              selectedState.value = state;
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }
}
