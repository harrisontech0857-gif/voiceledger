import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

class PrivacyService {
  static final PrivacyService _instance = PrivacyService._internal();
  final Logger _logger = Logger();

  factory PrivacyService() {
    return _instance;
  }

  PrivacyService._internal();

  Future<bool> getLocationTrackingConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('locationTrackingConsent') ?? false;
    } catch (e) {
      _logger.e('Error getting location tracking consent: $e');
      return false;
    }
  }

  Future<void> setLocationTrackingConsent(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('locationTrackingConsent', value);
    } catch (e) {
      _logger.e('Error setting location tracking consent: $e');
      rethrow;
    }
  }

  Future<bool> getPhotoAnalysisConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('photoAnalysisConsent') ?? false;
    } catch (e) {
      _logger.e('Error getting photo analysis consent: $e');
      return false;
    }
  }

  Future<void> setPhotoAnalysisConsent(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('photoAnalysisConsent', value);
    } catch (e) {
      _logger.e('Error setting photo analysis consent: $e');
      rethrow;
    }
  }

  Future<bool> getPushNotificationsConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('pushNotificationsConsent') ?? true;
    } catch (e) {
      _logger.e('Error getting push notifications consent: $e');
      return true;
    }
  }

  Future<void> setPushNotificationsConsent(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pushNotificationsConsent', value);
    } catch (e) {
      _logger.e('Error setting push notifications consent: $e');
      rethrow;
    }
  }

  Future<int> getLocationRetentionDays() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('locationRetentionDays') ?? 30;
    } catch (e) {
      _logger.e('Error getting location retention days: $e');
      return 30;
    }
  }

  Future<void> setLocationRetentionDays(int days) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('locationRetentionDays', days);
    } catch (e) {
      _logger.e('Error setting location retention days: $e');
      rethrow;
    }
  }
}
