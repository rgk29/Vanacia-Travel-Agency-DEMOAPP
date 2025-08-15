import 'package:agencedevoyage/vol/model.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
// Ajout de l'import Riverpod

class FlightReservationDetails extends StatelessWidget {
  final Flight departureFlight;
  final Flight? returnFlight;
  final Map<String, dynamic> passengers;
  final double totalPrice;
  final List<Map<String, dynamic>> luggage;

  const FlightReservationDetails({
    super.key,
    required this.departureFlight,
    this.returnFlight,
    required this.passengers,
    required this.totalPrice,
    required this.luggage,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFlightSegment('Vol Aller', departureFlight),
          if (returnFlight != null)
            _buildFlightSegment('Vol Retour', returnFlight!),
          _buildPassengersInfo(),
          _buildLuggageInfo(),
          _buildPriceInfo(context),
        ],
      ),
    );
  }

  Widget _buildFlightSegment(String title, Flight flight) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          Text('${flight.departure} → ${flight.arrival}'),
          Text('Compagnie: ${flight.company}'),
          Text(
              'Départ: ${DateFormat('dd/MM/yyyy HH:mm').format(flight.departureTime)}'),
        ],
      ),
    );
  }

  Widget _buildPassengersInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Passagers:', style: TextStyle(fontWeight: FontWeight.bold)),
        Text('Adultes: ${passengers['adults']}'),
        Text('Ados: ${passengers['teens']}'),
        Text('Enfants: ${passengers['children']}'),
      ],
    );
  }

  Widget _buildLuggageInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bagages:', style: TextStyle(fontWeight: FontWeight.bold)),
        ...luggage
            .map((item) => Text('${item['title']} - ${item['price']} DA')),
      ],
    );
  }

  Widget _buildPriceInfo(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Total:'),
          Text(
            NumberFormat.currency(symbol: 'DA ', decimalDigits: 0)
                .format(totalPrice),
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
