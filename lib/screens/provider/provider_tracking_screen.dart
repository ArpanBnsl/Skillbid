import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/contract_model.dart';
import '../../repositories/job_repository.dart';
import '../../services/location_service.dart';
import '../../services/route_service.dart';
import '../../services/tracking_service.dart';

class ProviderTrackingScreen extends StatefulWidget {
  final ContractModel contract;

  const ProviderTrackingScreen({super.key, required this.contract});

  @override
  State<ProviderTrackingScreen> createState() => _ProviderTrackingScreenState();
}

class _ProviderTrackingScreenState extends State<ProviderTrackingScreen> {
  final _mapController = MapController();
  final _locationService = LocationService();
  final _trackingService = TrackingService();
  final _routeService = RouteService();

  LatLng? _providerLatLng;
  LatLng? _jobLatLng;
  RouteData? _routeData;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _startTrackingAndLoad();
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) => _refreshRoute());
  }

  Future<void> _startTrackingAndLoad() async {
    _trackingService.startProviderTracking(contractId: widget.contract.id);
    _trackingService.subscribeToProviderLocation(
      contractId: widget.contract.id,
      onLocationUpdate: (lat, lng) {
        if (!mounted) return;
        setState(() => _providerLatLng = LatLng(lat, lng));
        _refreshRoute();
      },
    );

    final current = await _locationService.getCurrentPosition();
    if (current != null && mounted) {
      setState(() {
        _providerLatLng = LatLng(current.latitude, current.longitude);
      });
    }

    await _loadJobLocation();
    await _refreshRoute();
  }

  Future<void> _loadJobLocation() async {
    try {
      final repo = JobRepository();
      final job = await repo.getJobById(widget.contract.jobId);
      if (!mounted || job == null || job.jobLat == null || job.jobLng == null) return;
      setState(() => _jobLatLng = LatLng(job.jobLat!, job.jobLng!));
    } catch (_) {
      // Non-fatal fallback: keep map without destination marker.
    }
  }

  Future<void> _refreshRoute() async {
    if (_providerLatLng == null || _jobLatLng == null) return;

    final data = await _routeService.getRoute(
      providerLat: _providerLatLng!.latitude,
      providerLng: _providerLatLng!.longitude,
      clientLat: _jobLatLng!.latitude,
      clientLng: _jobLatLng!.longitude,
    );
    if (!mounted) return;
    setState(() => _routeData = data);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _trackingService.unsubscribeFromProviderLocation();
    _trackingService.stopProviderTracking();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final center = _providerLatLng ?? _jobLatLng ?? const LatLng(20.5937, 78.9629);

    return Scaffold(
      appBar: AppBar(title: const Text('Navigate To Contract Location')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.skillbid.app',
              ),
              if (_routeData != null && _routeData!.polylinePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routeData!.polylinePoints,
                      strokeWidth: 4,
                      color: Colors.blue,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (_jobLatLng != null)
                    Marker(
                      point: _jobLatLng!,
                      width: 42,
                      height: 42,
                      child: const Icon(Icons.location_on, color: Colors.red, size: 36),
                    ),
                  if (_providerLatLng != null)
                    Marker(
                      point: _providerLatLng!,
                      width: 42,
                      height: 42,
                      child: const Icon(Icons.navigation, color: Colors.blue, size: 34),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: _routeData == null
                    ? const Text('Calculating ETA and distance...', textAlign: TextAlign.center)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _metric(Icons.route, _routeData!.distanceText),
                          _metric(Icons.access_time, _routeData!.durationText),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.teal),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
