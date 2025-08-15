import 'package:agencedevoyage/currency_provider.dart';
import 'package:agencedevoyage/vol/flight_detail.dart';
import 'package:agencedevoyage/vol/model.dart';
import 'package:agencedevoyage/vol/user_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FlightResultsPage extends ConsumerWidget {
  final List<Flight> departureFlights;
  final List<Flight> returnFlights;
  final bool isRoundTrip;
  final int adults;
  final int teens;
  final int children;

  const FlightResultsPage({
    super.key,
    required this.departureFlights,
    required this.returnFlights,
    required this.isRoundTrip,
    required this.adults,
    required this.teens,
    required this.children,
  });

  // ... (Garder les méthodes _saveBooking et _buildReserveButton inchangées)
  Future<void> _handleReservationFlow(
    BuildContext context,
    WidgetRef ref, {
    Flight? returnFlight,
    required Flight departureFlight,
    required int selectedAdults,
    required int selectedTeens,
    required int selectedChildren,
  }) async {
    final user = ref.read(userProvider);
    final totalPassengers = selectedAdults + selectedTeens + selectedChildren;
    final totalPrice = departureFlight.priceDZD * totalPassengers +
        (returnFlight?.priceDZD ?? 0) * totalPassengers;
    final luggageArgs = await Navigator.pushNamed(
      context,
      '/luggageSelection',
      arguments: {
        'departureFlight': departureFlight,
        'returnFlight': returnFlight,
        'passengerCounts': {
          'adults': selectedAdults,
          'teens': selectedTeens,
          'children': selectedChildren,
        },
        'totalPassengers': totalPassengers,
        'basePrice': totalPrice,
        'selectedSeats': [],
        'seatPrice': 0.0,
      },
    );

    // 2. Si retour de luggageSelection, aller vers reservationSteps
    if (luggageArgs != null) {
      Navigator.pushNamed(
        context,
        '/reservationSteps',
        arguments: luggageArgs,
      );
    }
  }

  Widget _buildReserveButton(BuildContext context, WidgetRef ref, Flight flight,
      {Flight? returnFlight}) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.airplane_ticket, color: Colors.white),
      label: Text('Réserver'.tr()),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 25, 113, 186),
        foregroundColor: Colors.white,
      ),
      onPressed: () => _handleReservationFlow(
        context,
        ref,
        returnFlight: returnFlight,
        departureFlight: flight,
        selectedAdults: adults,
        selectedTeens: teens,
        selectedChildren: children,
      ),
    );
  }

  int get totalPassengers => adults + teens + children;

  void _showFlightDetails(BuildContext context, Flight flight) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlightDetailPage(
            flight: flight, adults: adults, teens: teens, children: children),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyNotifier = ref.read(currencyProvider.notifier);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(title: Text('Résultats_des_vols'.tr())),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                  maxWidth: 1200,
                ),
                child: isRoundTrip
                    ? _buildRoundTripView(currencyNotifier, context, ref)
                    : _buildOneWayView(currencyNotifier, context, ref),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOneWayView(
    CurrencyNotifier currencyNotifier,
    BuildContext context,
    WidgetRef ref,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: departureFlights.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _buildFlightCard(
        departureFlights[index],
        currencyNotifier,
        context,
        ref,
      ),
    );
  }

  Widget _buildRoundTripView(
    CurrencyNotifier currencyNotifier,
    BuildContext context,
    WidgetRef ref,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: departureFlights.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final departure = departureFlights[index];
        final returnFlight = returnFlights.firstWhere(
          (f) => f.departure.code == departure.arrival.code,
          orElse: () => returnFlights.first,
        );

        return _buildRoundTripCard(
          departure,
          returnFlight,
          currencyNotifier,
          context,
          ref,
        );
      },
    );
  }

  Widget _buildFlightCard(
    Flight flight,
    CurrencyNotifier currencyNotifier,
    BuildContext context,
    WidgetRef ref,
  ) {
    final totalPrice = flight.priceDZD * totalPassengers;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(flight.logoAsset, width: 60, height: 60),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${flight.departure.code} → ${flight.arrival.code}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        flight.company,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildFlightInfoRow(
                          'Départ'.tr(), _formatTime(flight.departureTime)),
                      _buildFlightInfoRow(
                          'Arrivée'.tr(), _formatTime(flight.arrivalTime)),
                      _buildFlightInfoRow('Classe'.tr(), flight.classe),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyNotifier.formatPrice(totalPrice),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildReserveButton(context, ref, flight),
                  ],
                ),
              ],
            ),
            if (flight.stops.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${flight.stops.length}${'Vol_Direct'.tr()}${flight.stops.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundTripCard(
    Flight departure,
    Flight returnFlight,
    CurrencyNotifier currencyNotifier,
    BuildContext context,
    WidgetRef ref,
  ) {
    final totalPrice =
        (departure.priceDZD + returnFlight.priceDZD) * totalPassengers;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildFlightSection(
                'Aller'.tr(), departure, currencyNotifier, context),
            const Divider(height: 24),
            _buildFlightSection(
                'Retour'.tr(), returnFlight, currencyNotifier, context),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    child: Text(
                  '${'Total_pour'.tr()} $totalPassengers ${'passager'.tr()}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                )),
                Text(
                  currencyNotifier.formatPrice(totalPrice),
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: _buildReserveButton(context, ref, departure,
                  returnFlight: returnFlight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlightInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label : ',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildFlightSection(String title, Flight flight,
      CurrencyNotifier currencyNotifier, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showFlightDetails(context, flight),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(flight.logoAsset, width: 70),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${flight.departure.code} → ${flight.arrival.code}'),
                  // Exemple pour la compagnie aérienne :
                  Text('${'Compagnie'.tr()} : ${flight.company}'),
                  Text('${'Classe'.tr()}: ${flight.classe}'.tr()),
                  Text('${'Départ'.tr()}: ${_formatTime(flight.departureTime)}'
                      .tr()),
                  Text('${'Arrivée'.tr()} : ${_formatTime(flight.arrivalTime)}'
                      .tr()),
                  if (flight.stops.isNotEmpty)
                    Text('${'Vol_Direct'.tr()}: ${flight.stops.join(", ")}'
                        .tr()),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  currencyNotifier
                      .formatPrice(flight.priceDZD * totalPassengers),
                  style: TextStyle(color: Colors.green[700]),
                ),
                if (flight.stops.isNotEmpty)
                  Text(
                    '${flight.stops.length} ${'Vol_Direct'.tr()}${flight.stops.length > 1 ? "s" : ""}',
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  String get _passengerSummary {
    List<String> parts = [];
    if (adults > 0) parts.add('$adults Adultes'.tr());
    if (teens > 0) parts.add('$teens Ados'.tr());
    if (children > 0) parts.add('$children Enfants'.tr());
    return parts.join(' + ');
  }

  String _formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }
}
