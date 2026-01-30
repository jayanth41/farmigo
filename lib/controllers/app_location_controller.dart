import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Provider-based location controller that manages runtime permissions,
/// listens to location updates and exposes current latitude/longitude.
class AppLocationController extends ChangeNotifier {
  bool _isLocationEnabled = false;
  bool _isPermissionGranted = false;
  double? _latitude;
  double? _longitude;
  String _locationName = 'Fetching location...';
  StreamSubscription<Position?>? _positionSub;
  String _permissionStatus = 'unknown';

  bool get isLocationEnabled => _isLocationEnabled;
  bool get isPermissionGranted => _isPermissionGranted;
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  String get locationName => _locationName;
  String get permissionStatus => _permissionStatus;

  AppLocationController();

  /// Initialize controller: check service + permissions and start listening.
  Future<void> initialize() async {
    await _checkServiceAndPermission();
    if (_isPermissionGranted && _isLocationEnabled) {
      await startListening();
    }
  }

  Future<void> _checkServiceAndPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      _isLocationEnabled = serviceEnabled;

      LocationPermission permission = await Geolocator.checkPermission();
      _permissionStatus = permission.toString();
      _isPermissionGranted = permission == LocationPermission.always || permission == LocationPermission.whileInUse;
    } catch (e) {
      debugPrint('Location check error: $e');
      _isLocationEnabled = false;
      _isPermissionGranted = false;
      _permissionStatus = 'error';
    }

    notifyListeners();
  }

  /// Request runtime permission from the user.
  Future<bool> requestPermission() async {
    try {
      final permission = await Geolocator.requestPermission();
      _permissionStatus = permission.toString();
      _isPermissionGranted = permission == LocationPermission.always || permission == LocationPermission.whileInUse;

      if (!_isPermissionGranted) {
        // do not start listening
        notifyListeners();
        return false;
      }

      // re-check service
      _isLocationEnabled = await Geolocator.isLocationServiceEnabled();
      notifyListeners();

      if (_isLocationEnabled) await startListening();

      return true;
    } catch (e) {
      debugPrint('requestPermission error: $e');
      return false;
    }
  }

  /// Start listening to position updates.
  Future<void> startListening() async {
    try {
      // Cancel existing
      await stopListening();

      // Try to get a last known position first
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        _latitude = last.latitude;
        _longitude = last.longitude;
        notifyListeners();
      }

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10,
      );

      _positionSub = Geolocator.getPositionStream(locationSettings: locationSettings)
          .listen((pos) {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
        _reverseGeocode(pos.latitude, pos.longitude);
        notifyListeners();
      }, onError: (err) {
        debugPrint('Position stream error: $err');
      });
    } catch (e) {
      debugPrint('startListening error: $e');
    }
  }

  /// Stop listening to position updates.
  Future<void> stopListening() async {
    try {
      await _positionSub?.cancel();
      _positionSub = null;
    } catch (e) {
      debugPrint('stopListening error: $e');
    }
  }

  /// Reverse geocode latitude/longitude into readable location name.
  Future<void> _reverseGeocode(double lat, double lon) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final city = p.locality ?? 'Unknown';
        final state = p.administrativeArea ?? '';
        _locationName = state.isNotEmpty ? '$city, $state' : city;
        notifyListeners();
        debugPrint('✅ Location: $_locationName');
      }
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
      _locationName = 'Location unavailable';
      notifyListeners();
    }
  }

  /// Get current one-shot position.
  Future<Position?> getCurrentPosition() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      _latitude = pos.latitude;
      _longitude = pos.longitude;
      await _reverseGeocode(pos.latitude, pos.longitude);
      return pos;
    } catch (e) {
      debugPrint('getCurrentPosition error: $e');
      return null;
    }
  }

  /// Allow setting a custom location name (manual override) and notify listeners.
  void setLocationName(String name) {
    _locationName = name;
    notifyListeners();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }
}
