import 'package:agencedevoyage/hotels/local.dart';
import 'package:agencedevoyage/hotels/summary.dart';
import 'package:agencedevoyage/voyageOrganiser/paymentselectionsteps.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HotelPaymentPage extends StatefulWidget {
  final HotelReservation reservation;
  final String totalPrice;
  final Hotells hotel;
  final Map<String, dynamic> userData;

  const HotelPaymentPage({
    super.key,
    required this.hotel,
    required this.reservation,
    required this.totalPrice,
    required this.userData,
  });

  @override
  State<HotelPaymentPage> createState() => HotelPaymentPageState();
}

class HotelPaymentPageState extends State<HotelPaymentPage> {
  Map<String, dynamic>? selectedPayment;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _confirmReservation() async {
    try {
      if (selectedPayment == null) {
        throw Exception("Moyen_de_paiement_non_sélectionné".tr());
      }

      final updatedReservation = widget.reservation.copyWith(
        paymentMethod: selectedPayment!['card_type'],
        status: 'confirmed',
        paymentDetails: {
          'method': selectedPayment,
          'date': DateTime.now(),
          'amount': widget.totalPrice,
        },
      );

      await FirebaseFirestore.instance
          .collection('hotel_reservations')
          .doc(updatedReservation.id) // Utiliser l'ID existant
          .update(updatedReservation.toMap());

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HotelSummaryPage(
            reservation: updatedReservation,
            hotel: widget.hotel,
            onConfirm: () {},
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de paiement : ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Confirmation_de_paiement".tr(),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).appBarTheme.foregroundColor,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
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
            // Ajouter un en-tête informatif
            Padding(
              padding: const EdgeInsets.all(16.0),
              // child: Text(
              //   'payment_hotel_header'.tr(),
              //   style: Theme.of(context).textTheme.titleLarge,
              // ),
            ),
            Expanded(
              child: PaymentSelectionStep(
                totalAmount: widget.reservation.totalPrice.toString(),
                onCardSelected: (card) =>
                    setState(() => selectedPayment = card),
                onPaymentConfirmed: _confirmReservation,
                cardHeight: 160,
                cardColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                selectedCardColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
