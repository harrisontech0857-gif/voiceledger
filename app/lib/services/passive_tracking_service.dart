import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import 'dart:async';

final passiveTrackingProvider = Provider<PassiveTrackingService>((ref) {
  return PassiveTrackingService();
});

final currentLocationProvider = StreamProvider<Position?>((ref) async* {
  final trackingService = ref.watch(passiveTrackingProvider);
  yield* trackingService.getLocationStream();
});

final geofenceAlertsProvider = StreamProvider<GeofenceAlert>((ref) async* {
  final trackingService = ref.watch(passiveTrackingProvider);
  yield* trackingService.getGeofenceAlerts();
});

class GeofenceLocation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String category;

  GeofenceLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.category,
  });
}

class GeofenceAlert {
  final String id;
  final GeofenceLocation location;
  final bool isEntering;
  final DateTime timestamp;

  GeofenceAlert({
    required this.id,
    required this.location,
    required this.isEntering,
    required this.timestamp,
  });
}

class PassiveTrackingService {
  final Logger _logger = Logger();
  final StreamController<GeofenceAlert> _geofenceController =
      StreamController<GeofenceAlert>.broadcast();
  final StreamController<Position?> _locationController =
      StreamController<Position?>.broadcast();

  List<GeofenceLocation> _geofences = [];
  Position? _lastPosition;
  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<ServiceStatus>? _serviceStatusSubscription;

  PassiveTrackingService() {
    _initializeLocationService();
  }

  Future<void> _initializeLocationService() async {
    try {
      final permission = await Permission.location.request();
      if (permission.isDenied) {
        _logger.w('Location permission denied');
        return;
      }

      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        _logger.w('Location service is disabled');
        return;
      }

      _startLocationTracking();
    } catch (e) {
      _logger.e('Error initializing location service: $e');
    }
  }

  void _startLocationTracking() {
    _locationSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 10, // Update only when moved 10 meters
          ),
        ).listen(
          (Position position) {
            _lastPosition = position;
            _locationController.add(position);
            _checkGeofences(position);
          },
          onError: (e) {
            _logger.e('Error in location stream: $e');
          },
        );
  }

  void _checkGeofences(Position currentPosition) {
    for (final geofence in _geofences) {
      final distance = Geolocator.distanceBetween(
        geofence.latitude,
        geofence.longitude,
        currentPosition.latitude,
        currentPosition.longitude,
      );

      final isInside = distance <= geofence.radiusMeters;

      // Emit alert when entering or exiting geofence
      _geofenceController.add(
        GeofenceAlert(
          id: '${geofence.id}_${DateTime.now().millisecondsSinceEpoch}',
          location: geofence,
          isEntering: isInside,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  Stream<Position?> getLocationStream() {
    return _locationController.stream;
  }

  Stream<GeofenceAlert> getGeofenceAlerts() {
    return _geofenceController.stream;
  }

  Future<Position?> getCurrentLocation() async {
    try {
      return await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      _logger.e('Error getting current location: $e');
      return null;
    }
  }

  Future<void> addGeofence(
    String id,
    String name,
    double latitude,
    double longitude,
    double radiusMeters,
    String category,
  ) async {
    _geofences.add(
      GeofenceLocation(
        id: id,
        name: name,
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
        category: category,
      ),
    );
    _logger.d('Added geofence: $name');
  }

  Future<void> removeGeofence(String id) async {
    _geofences.removeWhere((g) => g.id == id);
    _logger.d('Removed geofence: $id');
  }

  List<GeofenceLocation> getActiveGeofences() {
    return _geofences;
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

  Position? get lastPosition => _lastPosition;

  void dispose() {
    _locationSubscription?.cancel();
    _serviceStatusSubscription?.cancel();
    _locationController.close();
    _geofenceController.close();
  }
}
