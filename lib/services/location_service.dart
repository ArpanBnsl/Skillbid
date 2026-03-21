import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import '../utils/app_logger.dart';

class LocationService {
  StreamSubscription<Position>? _positionSubscription;

  /// Request location permission and return current position.
  /// Returns null if permission denied or location services disabled.
  Future<Position?> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      AppLogger.log('Location services are disabled');
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        AppLogger.log('Location permission denied');
        return null;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      AppLogger.log('Location permission permanently denied');
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (e) {
      AppLogger.logError('Failed to get current position', e);
      return null;
    }
  }

  /// Check if location permission is granted (without requesting).
  Future<bool> hasPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Start a periodic position stream (for provider tracking).
  /// [onPosition] is called each time a new position is received.
  /// [intervalMs] defaults to 5000 (5 seconds).
  void startLocationStream({
    required void Function(Position position) onPosition,
    int intervalMs = 5000,
  }) {
    stopLocationStream();

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // metres
        intervalDuration: Duration(milliseconds: intervalMs),
      ),
    ).listen(
      onPosition,
      onError: (e) => AppLogger.logError('Location stream error', e),
    );
  }

  /// Stop the active position stream.
  void stopLocationStream() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  /// Haversine distance between two lat/lng pairs in kilometres.
  static double distanceKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Estimate travel time in minutes given distance in km and average speed in km/h.
  static double estimateTravelMinutes(double distanceKm, {double avgSpeedKmh = 30}) {
    if (avgSpeedKmh <= 0) return double.infinity;
    return (distanceKm / avgSpeedKmh) * 60;
  }

  static double _degToRad(double deg) => deg * (pi / 180);
}
