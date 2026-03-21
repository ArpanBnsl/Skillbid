import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/location_service.dart';

/// A full-screen map picker that lets the user tap to select a location.
/// Returns the selected [LatLng] when the user confirms, or null on cancel.
class MapPickerScreen extends StatefulWidget {
  final LatLng? initialCenter;

  const MapPickerScreen({super.key, this.initialCenter});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? _selectedPoint;
  late final MapController _mapController;
  final _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedPoint = widget.initialCenter;
  }

  @override
  Widget build(BuildContext context) {
    final center = widget.initialCenter ?? const LatLng(20.5937, 78.9629); // India center

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        actions: [
          TextButton(
            onPressed: _selectedPoint != null
                ? () => Navigator.pop(context, _selectedPoint)
                : null,
            child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: widget.initialCenter != null ? 15 : 5,
              onTap: (tapPosition, point) {
                setState(() => _selectedPoint = point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.skillbid.app',
              ),
              if (_selectedPoint != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedPoint!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (_selectedPoint != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Lat: ${_selectedPoint!.latitude.toStringAsFixed(6)}, '
                    'Lng: ${_selectedPoint!.longitude.toStringAsFixed(6)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          Positioned(
            right: 16,
            top: 16,
            child: FloatingActionButton.small(
              heroTag: 'map_picker_current_location',
              onPressed: () async {
                final current = await _locationService.getCurrentPosition();
                if (!mounted) return;
                if (current == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Unable to access current location.')),
                  );
                  return;
                }

                final point = LatLng(current.latitude, current.longitude);
                setState(() => _selectedPoint = point);
                _mapController.move(point, 16);
              },
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}
