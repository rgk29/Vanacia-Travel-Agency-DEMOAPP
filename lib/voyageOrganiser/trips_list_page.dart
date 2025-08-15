import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agencedevoyage/voyageOrganiser/trip.dart';
import 'package:agencedevoyage/voyageOrganiser/trip_notifier.dart';
import 'package:agencedevoyage/voyageOrganiser/pagetrip.dart';
import 'package:agencedevoyage/currency_provider.dart';

class TripsListPage extends ConsumerWidget {
  final List<Trip> trips;

  const TripsListPage({super.key, required this.trips});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyNotifier = ref.watch(currencyProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('our_offers'.tr()),
        elevation: 4,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: trips.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) =>
            _buildTripCard(context, trips[index], currencyNotifier),
      ),
    );
  }

  Widget _buildTripCard(
      BuildContext context, Trip trip, CurrencyNotifier currencyNotifier) {
    final cheapestPrice = trip.hotels
        .map((h) => h.roomPrices.values.reduce((a, b) => a < b ? a : b))
        .reduce((a, b) => a < b ? a : b);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 4,
      child: InkWell(
        onTap: () => _navigateToTripDetail(context, trip),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageHeader(trip),
              const SizedBox(height: 16),
              _buildMainInfo(context, trip, currencyNotifier, cheapestPrice),
              const SizedBox(height: 12),
              _buildAdditionalDetails(trip),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageHeader(Trip trip) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            trip.photos.first,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          bottom: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${trip.photos.length}+',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainInfo(BuildContext context, Trip trip,
      CurrencyNotifier currencyNotifier, double price) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${trip.departureCity} → ${trip.destination}',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('dd MMM yyyy').format(trip.departureDate),
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              currencyNotifier.formatPrice(price),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
            Text(
              '${'duration'.tr()} ${trip.durationDays} ${'days'.tr()}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdditionalDetails(Trip trip) {
    return Wrap(
      spacing: 8,
      runSpacing: 5,
      children: [
        _buildDetailChip(
            icon: Icons.hotel, label: '${trip.hotels.length} ${'hotels'.tr()}'),
        _buildDetailChip(
            icon: Icons.confirmation_number,
            label: '${trip.remainingTickets} ${'available'.tr()}'),
        _buildDetailChip(
            icon: Icons.star,
            label: '${trip.hotels.first.stars} ${'stars'.tr()}'),
      ],
    );
  }

  Widget _buildDetailChip({required IconData icon, required String label}) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      backgroundColor: Colors.blue[50],
      visualDensity: VisualDensity.compact,
    );
  }

  void _navigateToTripDetail(BuildContext context, Trip selectedTrip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProviderScope(
          overrides: [
            tripProvider.overrideWith((ref) => TripNotifier(selectedTrip)),
          ],
          child: const TripDetailPage(),
        ),
      ),
    );
  }
}
