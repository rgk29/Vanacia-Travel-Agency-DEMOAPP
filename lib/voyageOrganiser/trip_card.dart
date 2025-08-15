import 'package:agencedevoyage/voyageOrganiser/pagetrip.dart';
import 'package:agencedevoyage/voyageOrganiser/trip_data.dart';
import 'package:agencedevoyage/voyageOrganiser/trip_notifier.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:agencedevoyage/voyageOrganiser/trip.dart';
import 'package:agencedevoyage/currency_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider pour la liste des voyages
final tripsProvider = Provider<List<Trip>>((ref) => getOrganizedTrips());

class TripCard extends ConsumerWidget {
  final Trip trip;

  const TripCard({super.key, required this.trip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyNotifier = ref.watch(currencyProvider.notifier);
    final theme = Theme.of(context);

    return _buildCardLayout(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          const SizedBox(height: 12),
          _buildDepartureInfo(),
          _buildPriceInfo(currencyNotifier, theme),
        ],
      ),
    );
  }

  Widget _buildCardLayout({
    required BuildContext context,
    required Widget child,
  }) {
    return Card(
      margin: const EdgeInsets.all(8),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '${trip.departureCity} → ${trip.destination}',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _buildAvailabilityBadge(),
      ],
    );
  }

  Widget _buildDepartureInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(
          Icons.calendar_today,
          'departure_date'.tr(),
          DateFormat('dd/MM/yyyy').format(trip.departureDate),
        ),
        _buildInfoRow(Icons.timer, 'duration'.tr(),
            '${trip.durationDays} ${'days'.tr()}'),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue[800]),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceInfo(CurrencyNotifier currencyNotifier, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'price_from'.tr(),
            style: theme.textTheme.bodyLarge,
          ),
          Text(
            currencyNotifier.formatPrice(trip.minPrice),
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.green[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: trip.remainingTickets > 3
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${trip.remainingTickets} ${'available'.tr()}',
        style: TextStyle(
          color: trip.remainingTickets > 3 ? Colors.green : Colors.orange,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProviderScope(
          overrides: [tripProvider.overrideWith((_) => TripNotifier(trip))],
          child: const TripDetailPage(),
        ),
      ),
    );
  }
}
