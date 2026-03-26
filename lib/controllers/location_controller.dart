import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geocoding/geocoding.dart';

class LocationController extends GetxController {
  // Whether device location services / permission are enabled
  RxBool isLocationEnabled = false.obs;

  // Persisted selection while app is running
  RxString selectedCity = ''.obs;
  RxString selectedState = 'Telangana'.obs; // default state

  // Computed display name like "Anajpur, Telangana"
  String get selectedLocationName {
    final city = selectedCity.value.trim();
    final state = selectedState.value.trim();
    if (city.isNotEmpty && state.isNotEmpty) return '$city, $state';
    if (city.isNotEmpty) return city;
    return state.isNotEmpty ? state : 'Location unavailable';
  }

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

  /// Set selected city/state programmatically. Persists in memory only.
  void setLocation({required String city, required String state}) {
    selectedCity.value = city.trim();
    selectedState.value = state.trim();
  }

  /// Try to detect current location (reverse geocode). Returns a human
  /// readable string on success, or null on failure.
  Future<String?> detectCurrentLocation() async {
    try {
      await checkLocationStatus();
      if (!isLocationEnabled.value) {
        // Try requesting permission once
        await requestLocationPermission();
      }

      if (!isLocationEnabled.value) return null;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception("Location timeout"),
      );
      final List<Placemark> placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;

        final city = p.locality ?? p.subAdministrativeArea ?? '';
        final state = p.administrativeArea ?? '';

        // update controller state safely
        if (city.isNotEmpty) {
          selectedCity.value = city;
        }

        if (state.isNotEmpty) {
          selectedState.value = state;
        }

        if (city.isNotEmpty || state.isNotEmpty) {
          return selectedLocationName;
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ detectCurrentLocation error: $e');
      return null;
    }
  }

  void openStateSelector(BuildContext context) {
    final states = [ "Andhra Pradesh", "Arunachal Pradesh" ,"Assam","Bihar","Chhattisgarh","Goa","Gujarat","Haryana","Himachal Pradesh","Jharkhand","Karnataka","Kerala","Madhya Pradesh", "Maharashtra" ,"Manipur","Meghalaya","Mizoram","Nagaland","Odisha","Punjab","Rajasthan","Sikkim","Tamil Nadu","Telangana","Tripura","Uttar Pradesh","Uttarakhand","West Bengal","Andaman and Nicobar Islands","Chandigarh","Dadra and Nagar Haveli and Daman and Diu","Delhi","Jammu and Kashmir","Ladakh","Lakshadweep","Puducherry"];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ListView(
        children: states.map((s) {
          final isSelected = s == selectedState.value;
          return ListTile(
            title: Text(s, style: const TextStyle()),
            selected: isSelected,
            selectedTileColor: Colors.blue.withValues(alpha: 0.08),
            selectedColor: Colors.blue,
            trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
            onTap: () {
              selectedState.value = s;
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }
}
