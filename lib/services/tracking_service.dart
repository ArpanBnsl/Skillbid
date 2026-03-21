import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../repositories/job_repository.dart';
import '../utils/app_logger.dart';

/// Manages provider-side location broadcasting and client-side location listening.
class TrackingService {
  final _locationService = LocationService();
  final _databaseService = DatabaseService();
  final _jobRepository = JobRepository();
  RealtimeChannel? _trackingChannel;

  /// Provider side: start pushing location updates to the contracts table.
  void startProviderTracking({
    required String contractId,
  }) {
    _locationService.startLocationStream(
      intervalMs: 7000,
      onPosition: (Position position) async {
        try {
          final nowIso = DateTime.now().toUtc().toIso8601String();

          final contractRows = await _databaseService.fetchData(
            table: 'contracts',
            select: 'job_id,arrived_at',
            filters: {'id': contractId},
          );

          String? arrivedAtToSet;
          if (contractRows.isNotEmpty) {
            final jobId = contractRows.first['job_id'] as String?;
            final arrivedAt = contractRows.first['arrived_at'];
            if (jobId != null && arrivedAt == null) {
              final job = await _jobRepository.getJobById(jobId);
              if (job != null && job.isImmediate && job.jobLat != null && job.jobLng != null) {
                final distance = LocationService.distanceKm(
                  position.latitude,
                  position.longitude,
                  job.jobLat!,
                  job.jobLng!,
                );
                if (distance <= 0.2) {
                  arrivedAtToSet = nowIso;
                }
              }
            }
          }

          await _databaseService.updateData(
            table: 'contracts',
            id: contractId,
            data: {
              'provider_lat': position.latitude,
              'provider_lng': position.longitude,
              'last_location_update': nowIso,
              if (arrivedAtToSet != null) 'arrived_at': arrivedAtToSet,
            },
          );
        } catch (e) {
          AppLogger.logError('Provider tracking update failed', e);
        }
      },
    );
  }

  /// Provider side: stop pushing location updates.
  void stopProviderTracking() {
    _locationService.stopLocationStream();
  }

  /// Client side: subscribe to realtime location updates for a contract.
  /// Calls [onLocationUpdate] with (lat, lng) whenever the provider location changes.
  void subscribeToProviderLocation({
    required String contractId,
    required void Function(double lat, double lng) onLocationUpdate,
  }) {
    _trackingChannel?.unsubscribe();

    _trackingChannel = supabase
        .channel('contract-tracking-$contractId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'contracts',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: contractId,
          ),
          callback: (payload) {
            final newRow = payload.newRecord;
            final lat = (newRow['provider_lat'] as num?)?.toDouble();
            final lng = (newRow['provider_lng'] as num?)?.toDouble();
            if (lat != null && lng != null) {
              onLocationUpdate(lat, lng);
            }
          },
        )
        .subscribe();
  }

  /// Client side: stop listening to provider location updates.
  Future<void> unsubscribeFromProviderLocation() async {
    if (_trackingChannel != null) {
      await supabase.removeChannel(_trackingChannel!);
      _trackingChannel = null;
    }
  }

  /// Enable tracking on a contract (called when contract becomes active from immediate job).
  Future<void> enableTracking(String contractId) async {
    await _databaseService.updateData(
      table: 'contracts',
      id: contractId,
      data: {'tracking_enabled': true},
    );
  }

  /// Disable tracking on a contract (called on complete/terminate).
  Future<void> disableTracking(String contractId) async {
    await _databaseService.updateData(
      table: 'contracts',
      id: contractId,
      data: {
        'tracking_enabled': false,
        'provider_lat': null,
        'provider_lng': null,
      },
    );
  }
}
