import 'package:agencedevoyage/voyageOrganiser/paymentselectionsteps.dart';
import 'package:agencedevoyage/voyageOrganiser/tripreservationsummary.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'trip.dart';

class PaymentPagee extends StatefulWidget {
  final Reservation reservation;
  final String totalPrice;
  final Hotel hotel;
  final Map<String, dynamic> userData;

  const PaymentPagee({
    super.key,
    required this.hotel,
    required this.reservation,
    required this.totalPrice,
    required this.userData,
  });

  @override
  State<PaymentPagee> createState() => PaymentPageeState();
}

class PaymentPageeState extends State<PaymentPagee> {
  Map<String, dynamic>? selectedPayment;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _confirmReservation() async {
    if (selectedPayment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('selectionnez_moyen_paiement'.tr())),
      );
      return;
    }

    try {
      // Mettre à jour la réservation avec les infos de paiement
      final updatedReservation = widget.reservation.copyWith(
        paymentMethod: selectedPayment!['card_type'],
        status: 'confirmed',
      );

      // Sauvegarder dans Firestore
      await _firestore
          .collection('organized_trips_reservations')
          .add(updatedReservation.toMap());

      // Naviguer vers la confirmation finale
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TripReservationSummaryPage(
              reservation: updatedReservation,
              hotel: widget.hotel,
            ),
          ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('erreur_paiement'.tr(args: [e.toString()]))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Confirmation_de_paiement".tr(),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: PaymentSelectionStep(
                totalAmount: widget.totalPrice,
                onCardSelected: (card) =>
                    setState(() => selectedPayment = card),
                onPaymentConfirmed: _confirmReservation,
                cardHeight: 160,
                cardColor: Colors.blue.shade100,
                selectedCardColor: Colors.blue.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
