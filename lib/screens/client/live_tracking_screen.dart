import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/contract_model.dart';
import '../../repositories/contract_repository.dart';
import '../../services/route_service.dart';
import '../../services/tracking_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Full-screen map that shows the provider's live location, the job site,
/// the route polyline, and an ETA info card.
class LiveTrackingScreen extends StatefulWidget {
  final ContractModel contract;

  /// The job site location (client / work address).
  final LatLng jobLocation;

  const LiveTrackingScreen({
    super.key,
    required this.contract,
    required this.jobLocation,
  });

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final _trackingService = TrackingService();
  final _routeService = RouteService();
  final _contractRepository = ContractRepository();
  final _mapController = MapController();

  LatLng? _providerLatLng;
  RouteData? _routeData;
  Timer? _routeRefreshTimer;
  Timer? _contractRefreshTimer;
  bool _fetchingRoute = false;

  @override
  void initState() {
    super.initState();

    // Seed the provider marker from contract data
    final c = widget.contract;
    if (c.providerLat != null && c.providerLng != null) {
      _providerLatLng = LatLng(c.providerLat!, c.providerLng!);
    }

    // Subscribe to real-time location updates
    _trackingService.subscribeToProviderLocation(
      contractId: c.id,
      onLocationUpdate: (lat, lng) {
        if (!mounted) return;
        setState(() => _providerLatLng = LatLng(lat, lng));
      },
    );

    // Fetch the initial route
    _fetchRoute();
    _refreshFromLatestContract();

    // Periodically refresh the route every 30 seconds
    _routeRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _fetchRoute(),
    );

    _contractRefreshTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _refreshFromLatestContract(),
    );
  }

  Future<void> _refreshFromLatestContract() async {
    final latest = await _contractRepository.getContractById(widget.contract.id);
    if (!mounted || latest == null) return;
    final lat = latest.providerLat;
    final lng = latest.providerLng;
    if (lat != null && lng != null) {
      setState(() => _providerLatLng = LatLng(lat, lng));
    }
  }

  Future<void> _fetchRoute() async {
    if (_providerLatLng == null || _fetchingRoute) return;
    _fetchingRoute = true;

    final data = await _routeService.getRoute(
      providerLat: _providerLatLng!.latitude,
      providerLng: _providerLatLng!.longitude,
      clientLat: widget.jobLocation.latitude,
      clientLng: widget.jobLocation.longitude,
    );

    if (!mounted) return;
    setState(() {
      _routeData = data;
      _fetchingRoute = false;
    });
  }

  @override
  void dispose() {
    _routeRefreshTimer?.cancel();
    _contractRefreshTimer?.cancel();
    _trackingService.unsubscribeFromProviderLocation();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final centre = _providerLatLng ?? widget.jobLocation;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        title: Text('Live Tracking', style: AppTypography.heading4.copyWith(color: AppColors.textPrimary)),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: centre,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.skillbid.app',
              ),
              // Route polyline
              if (_routeData != null && _routeData!.polylinePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routeData!.polylinePoints,
                      strokeWidth: 4,
                      color: AppColors.primaryColor,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  // Job site marker (accent orange)
                  Marker(
                    point: widget.jobLocation,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_on, color: AppColors.accent, size: 36),
                  ),
                  // Provider marker (primary teal)
                  if (_providerLatLng != null)
                    Marker(
                      point: _providerLatLng!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.directions_walk, color: AppColors.primaryColor, size: 32),
                    ),
                ],
              ),
            ],
          ),

          // ETA info card
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: _routeData != null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _metric(Icons.route, _routeData!.distanceText),
                        _metric(Icons.access_time, _routeData!.durationText),
                      ],
                    )
                  : _providerLatLng == null
                      ? Text(
                          'Waiting for provider location...',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        )
                      : Text(
                          'Loading route...',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: AppColors.primaryColor),
        const SizedBox(width: 6),
        Text(
          text,
          style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
