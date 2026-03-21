import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import '../config/supabase_config.dart';
import '../utils/app_logger.dart';

class RouteData {
  final List<LatLng> polylinePoints;
  final double distanceMeters;
  final double durationSeconds;

  RouteData({
    required this.polylinePoints,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  String get distanceText {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
    return '${distanceMeters.toStringAsFixed(0)} m';
  }

  String get durationText {
    final totalMinutes = (durationSeconds / 60).round();
    if (totalMinutes < 60) return '$totalMinutes min';
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    return '${hours}h ${mins}m';
  }
}

class RouteService {
  final _dio = Dio();

  /// Fetch route from the Supabase Edge Function `get-route`.
  /// Returns null on any failure (graceful fallback).
  Future<RouteData?> getRoute({
    required double providerLat,
    required double providerLng,
    required double clientLat,
    required double clientLng,
  }) async {
    try {
      final functionUrl =
          '${SupabaseConfig.supabaseUrl}/functions/v1/get-route';

      final response = await _dio.post(
        functionUrl,
        data: {
          'start': [providerLng, providerLat], // ORS uses [lng, lat]
          'end': [clientLng, clientLat],
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${SupabaseConfig.supabaseAnonKey}',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode != 200 || response.data == null) return null;

      final data = response.data as Map<String, dynamic>;
      final geometry = data['geometry'] as String?;
      final distance = (data['distance'] as num?)?.toDouble() ?? 0;
      final duration = (data['duration'] as num?)?.toDouble() ?? 0;

      if (geometry == null || geometry.isEmpty) return null;

      final points = _decodePolyline(geometry);
      if (points.isEmpty) return null;

      return RouteData(
        polylinePoints: points,
        distanceMeters: distance,
        durationSeconds: duration,
      );
    } catch (e) {
      AppLogger.logError('Route fetch failed', e);
      return null;
    }
  }

  /// Decode an encoded polyline string into a list of LatLng.
  /// Works with both Google-style and ORS-style encoded polylines.
  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      int byte;

      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);

      final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);

      final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }
}
