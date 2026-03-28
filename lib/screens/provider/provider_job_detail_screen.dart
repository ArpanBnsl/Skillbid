import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../models/job/job_model.dart';
import '../../providers/bid_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/user_provider.dart' as userp;
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
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
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Job Details', style: AppTypography.heading4.copyWith(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Job header gradient card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: AppColors.cardGradient,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.title, style: AppTypography.heading3.copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: 12),
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
                Text(job.description, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.5)),
              ],
            ),
          ),
          if (job.isImmediate) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.bolt, color: AppColors.warning),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Immediate Service',
                            style: AppTypography.labelLarge.copyWith(color: AppColors.warning)),
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
                              style: AppTypography.caption.copyWith(
                                color: expired ? AppColors.error : AppColors.warning,
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
          ],
          if (job.jobLat != null && job.jobLng != null) ...[
            const SizedBox(height: 10),
            Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
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
                          'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.skillbid.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(job.jobLat!, job.jobLng!),
                          width: 36,
                          height: 36,
                          child: Icon(Icons.location_on,
                              color: AppColors.error, size: 32),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Client info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Client', style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Text(clientAsync.valueOrNull?.fullName ?? 'Client', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text('Posted ${Formatters.formatDate(job.createdAt)}', style: AppTypography.caption.copyWith(color: AppColors.textHint)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          jobImagesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (images) {
              if (images.isEmpty) return const SizedBox.shrink();

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Client Reference Images', style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary)),
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
              );
            },
          ),
          const SizedBox(height: 16),
          if (myBid != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Bid', style: AppTypography.labelLarge.copyWith(color: AppColors.primaryColor)),
                  const SizedBox(height: 10),
                  _BidInfoRow(label: 'Status', value: myBid.status),
                  const SizedBox(height: 6),
                  _BidInfoRow(label: 'Amount', value: Formatters.formatCurrencyShort(myBid.amount)),
                  if (myBid.estimatedDays != null) ...[
                    const SizedBox(height: 6),
                    _BidInfoRow(label: 'Timeline', value: '${myBid.estimatedDays} days'),
                  ],
                  if (myBid.message?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 10),
                    Text(myBid.message!, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                  ],
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: MaterialButton(
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
                        SnackBar(
                          content: const Text('Bid placed successfully.'),
                          backgroundColor: AppColors.successLight,
                        ),
                      );
                    }
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.gavel_outlined, color: AppColors.textDark),
                      const SizedBox(width: 8),
                      Text('Place Bid', style: AppTypography.buttonText.copyWith(color: AppColors.textDark)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BidInfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _BidInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label: ', style: AppTypography.caption.copyWith(color: AppColors.textHint)),
        Text(value, style: AppTypography.labelMedium.copyWith(color: AppColors.textPrimary)),
      ],
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
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryColor),
          const SizedBox(width: 6),
          Text(label, style: AppTypography.caption.copyWith(color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
