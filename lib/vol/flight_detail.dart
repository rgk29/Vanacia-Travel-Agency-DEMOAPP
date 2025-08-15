import 'package:agencedevoyage/currency_provider.dart';
import 'package:agencedevoyage/vol/model.dart';
import 'package:agencedevoyage/vol/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FlightDetailPage extends ConsumerWidget {
  final Flight flight;
  final int adults;
  final int teens;
  final int children;

  const FlightDetailPage({
    super.key,
    required this.flight,
    required this.adults,
    required this.teens,
    required this.children,
  });

  int get totalPassengers => adults + teens + children;

  void _handleBooking(WidgetRef ref, BuildContext context) {
    final user = ref.read(userProvider);

    // Vérification cruciale de l'authentification
    if (!user.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez_vous_connecter_pour_réserver'.tr())),
      );
      return;
    }

    // Validation des données avant envoi
    if (totalPassengers <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre de passagers invalide')),
      );
      return;
    }

    final bookingData = {
      'type': 'flight',
      'departureFlight': flight.toMap(),
      'returnFlight': null,
      'passengers': {
        'adults': adults,
        'teens': teens,
        'children': children,
      },
      'totalPrice': flight.priceDZD * totalPassengers,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'confirmed', // Nouveau champ important
    };

    // Référence directe à la sous-collection flight_reservations
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.id)
        .collection('flight_reservations')
        .add(bookingData)
        .then((_) {
      Navigator.popUntil(context, (route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Réservation_confirmée'.tr())),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${error.toString()}')),
      );
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyNotifier = ref.read(currencyProvider.notifier);
    final totalPrice = flight.priceDZD * totalPassengers;

    return Scaffold(
      appBar: AppBar(
        title: Text('Détails_du_vol'.tr()),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.check),
        //     onPressed: () => _handleBooking(ref, context),
        //   ),
        // ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAirlineHeader(),
            const SizedBox(height: 20),
            _buildFlightDetail(
              'Départ'.tr(),
              '${flight.departure.code} - ${flight.departure.name}',
              flight.departureTime,
            ),
            _buildFlightDetail(
              'Arrivée'.tr(),
              '${flight.arrival.code} - ${flight.arrival.name}',
              flight.arrivalTime,
            ),
            const SizedBox(height: 20),
            _buildPriceSection(currencyNotifier.formatPrice(totalPrice)),
            const SizedBox(height: 30),
            _buildPassengerSummary(),
            const SizedBox(height: 40),
            // _buildBookingButton(ref, context),
          ],
        ),
      ),
    );
  }

  // Widget _buildBookingButton(WidgetRef ref, BuildContext context) {
  //   // Ajout du contexte en paramètre
  //   // return ElevatedButton(
  //   //   style: ElevatedButton.styleFrom(
  //   //     backgroundColor: Colors.blue[800],
  //   //     minimumSize: const Size(double.infinity, 50),
  //   //   ),
  //   //   // onPressed: () =>
  //   //   //     _handleBooking(ref, context), // Context est maintenant disponible
  //   //   // // child: Text(
  //   //   //   'Confirmer_la_réservation'.tr(),
  //   //   //   style: const TextStyle(color: Colors.white),
  //   //   // ),
  //   // );
  // }

  // Les méthodes de construction d'UI restent inchangées
  Widget _buildAirlineHeader() {
    return Row(
      children: [
        Image.asset(flight.logoAsset, width: 60, height: 60),
        const SizedBox(width: 15),
        Text(
          flight.company,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildFlightDetail(String title, String location, DateTime time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.blueGrey)),
          const SizedBox(height: 5),
          Text(location, style: const TextStyle(fontSize: 16)),
          Text(
            DateFormat('dd MMM yyyy - HH:mm').format(time),
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(String price) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Prix_total'.tr(),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(price,
                style: TextStyle(
                    fontSize: 20,
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Détail_des_passagers'.tr(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        if (adults > 0) _buildPassengerLine('Adultes'.tr(), adults),
        if (teens > 0) _buildPassengerLine('Adolescents'.tr(), teens),
        if (children > 0) _buildPassengerLine('Enfants'.tr(), children),
      ],
    );
  }

  Widget _buildPassengerLine(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:'),
          Text('$count', style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
