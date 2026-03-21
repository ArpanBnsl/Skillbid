import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../models/job/job_model.dart';
import '../../providers/bid_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/user_provider.dart' as userp;
import '../../utils/formatters.dart';
import '../../widgets/common/image_viewer.dart';
import 'provider_place_bid_screen.dart';

class ProviderJobDetailScreen extends ConsumerWidget {
  final JobModel job;

  const ProviderJobDetailScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientAsync = ref.watch(userp.userProfileProvider(job.clientId));
    final myBidsAsync = ref.watch(providerBidsProvider);
    final myBid = myBidsAsync.valueOrNull?.where((bid) => bid.jobId == job.id).firstOrNull;
    final jobImagesAsync = ref.watch(jobImagesProvider(job.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Job Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFFF7FBFB), Color(0xFFE7F6F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _DetailChip(icon: Icons.payments_outlined, label: Formatters.formatCurrencyShort(job.budget)),
                    _DetailChip(icon: Icons.location_on_outlined, label: job.location),
                    if (job.desiredCompletionDays != null)
                      _DetailChip(icon: Icons.schedule_outlined, label: '${job.desiredCompletionDays} days'),
                  ],
                ),
                const SizedBox(height: 14),
                Text(job.description, style: TextStyle(color: Colors.grey.shade800, height: 1.5)),
              ],
            ),
          ),
          if (job.isImmediate) ...[
            const SizedBox(height: 10),
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.bolt, color: Colors.orange.shade800),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Immediate Service',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          if (job.expiresAt != null) ...[
                            const SizedBox(height: 2),
                            Builder(builder: (_) {
                              final remaining = job.expiresAt!.difference(DateTime.now());
                              final expired =
                                  remaining.isNegative || remaining == Duration.zero;
                              return Text(
                                expired
                                    ? 'Expired'
                                    : 'Expires in ${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m',
                                style: TextStyle(
                                  color: expired ? Colors.red : Colors.orange.shade900,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (job.jobLat != null && job.jobLng != null) ...[
            const SizedBox(height: 10),
            Card(
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                height: 180,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(job.jobLat!, job.jobLng!),
                    initialZoom: 14,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.skillbid.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(job.jobLat!, job.jobLng!),
                          width: 36,
                          height: 36,
                          child: const Icon(Icons.location_on,
                              color: Colors.red, size: 32),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Client', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(clientAsync.valueOrNull?.fullName ?? 'Client'),
                  const SizedBox(height: 4),
                  Text('Posted ${Formatters.formatDate(job.createdAt)}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          jobImagesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (images) {
              if (images.isEmpty) return const SizedBox.shrink();

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Client Reference Images', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 90,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: images.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final image = images[index];
                            return GestureDetector(
                              onTap: () => ImageViewer.showNetwork(context, image.imageUrl),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  image.imageUrl,
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          if (myBid != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your Bid', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Text('Status: ${myBid.status}'),
                    const SizedBox(height: 6),
                    Text('Amount: ${Formatters.formatCurrencyShort(myBid.amount)}'),
                    if (myBid.estimatedDays != null) ...[
                      const SizedBox(height: 6),
                      Text('Timeline: ${myBid.estimatedDays} days'),
                    ],
                    if (myBid.message?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 10),
                      Text(myBid.message!),
                    ],
                  ],
                ),
              ),
            )
          else
            FilledButton.icon(
              onPressed: () async {
                final placed = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProviderPlaceBidScreen(job: job),
                  ),
                );

                if (placed == true) {
                  ref.invalidate(providerBidsProvider);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bid placed successfully.')),
                  );
                }
              },
              icon: const Icon(Icons.gavel_outlined),
              label: const Text('Place Bid'),
            ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.teal.shade700),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}