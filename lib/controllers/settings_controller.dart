import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends ChangeNotifier {
  // ========== Notification Settings ==========
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;

  // ========== Appearance Settings ==========
  bool _darkMode = false;

  // ========== Language & Region Settings ==========
  String _language = 'English';
  String _currency = 'USD';

  // ========== SharedPreferences Instance ==========
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  // ========== Getters ==========
  bool get pushNotifications => _pushNotifications;
  bool get emailNotifications => _emailNotifications;
  bool get smsNotifications => _smsNotifications;
  bool get darkMode => _darkMode;
  String get language => _language;
  String get currency => _currency;
  bool get isInitialized => _isInitialized;

  // ========== Initialize from Storage ==========
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    _pushNotifications = _prefs.getBool('pushNotifications') ?? true;
    _emailNotifications = _prefs.getBool('emailNotifications') ?? true;
    _smsNotifications = _prefs.getBool('smsNotifications') ?? false;
    _darkMode = _prefs.getBool('darkMode') ?? false;
    _language = _prefs.getString('language') ?? 'English';
    _currency = _prefs.getString('currency') ?? 'USD';

    _isInitialized = true;
    notifyListeners();
  }

  // ========== Push Notifications ==========
  Future<void> setPushNotifications(bool value) async {
    _pushNotifications = value;
    await _prefs.setBool('pushNotifications', value);
    debugPrint('✅ Push Notifications: $value');
    notifyListeners();
  }

  // ========== Email Notifications ==========
  Future<void> setEmailNotifications(bool value) async {
    _emailNotifications = value;
    await _prefs.setBool('emailNotifications', value);
    debugPrint('✅ Email Notifications: $value');
    notifyListeners();
  }

  // ========== SMS Notifications ==========
  Future<void> setSmsNotifications(bool value) async {
    _smsNotifications = value;
    await _prefs.setBool('smsNotifications', value);
    debugPrint('✅ SMS Notifications: $value');
    notifyListeners();
  }

  // ========== Dark Mode ==========
  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    await _prefs.setBool('darkMode', value);
    debugPrint('✅ Dark Mode: $value');
    notifyListeners();
  }

  // ========== Language ==========
  Future<void> setLanguage(String value) async {
    _language = value;
    await _prefs.setString('language', value);
    debugPrint('✅ Language: $value');
    notifyListeners();
  }

  // ========== Currency ==========
  Future<void> setCurrency(String value) async {
    _currency = value;
    await _prefs.setString('currency', value);
    debugPrint('✅ Currency: $value');
    notifyListeners();
  }

  // ========== Reset All Settings to Defaults ==========
  Future<void> resetToDefaults() async {
    _pushNotifications = true;
    _emailNotifications = true;
    _smsNotifications = false;
    _darkMode = false;
    _language = 'English';
    _currency = 'USD';

    await _prefs.clear();
    await initialize();
    debugPrint('✅ Settings reset to defaults');
    notifyListeners();
  }
}
