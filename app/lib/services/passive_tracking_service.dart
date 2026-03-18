import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';

final passiveTrackingProvider = Provider<PassiveTrackingService>((ref) {
  return PassiveTrackingService();
});

class PassiveTrackingService {
  final Logger _logger = Logger();

  PassiveTrackingService();

  Future<Position?> getCurrentLocation() async {
    try {
      final permission = await Permission.location.request();
      if (!permission.isGranted) {
        _logger.w('Location permission denied');
        return null;
      }

      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        _logger.w('Location service is disabled');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      _logger.e('Error getting current location: $e');
      return null;
    }
  }

  Future<bool> requestLocationPermission() async {
    try {
      final status = await Permission.location.request();
      return status.isGranted;
    } catch (e) {
      _logger.e('Error requesting location permission: $e');
      return false;
    }
  }

  Future<bool> hasLocationPermission() async {
    try {
      final status = await Permission.location.status;
      return status.isGranted;
    } catch (e) {
      _logger.e('Error checking location permission: $e');
      return false;
    }
  }
}
