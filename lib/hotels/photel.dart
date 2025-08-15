import 'package:agencedevoyage/hotels/local.dart';
import 'package:agencedevoyage/VoyageOrganiser/paymentselectionsteps.dart';
import 'package:agencedevoyage/hotels/summary.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// à adapter selon ton projet

class PaymentPageHotel extends StatefulWidget {
  final HotelReservation reservation;
  final String totalPrice;
  final Hotells hotel;

  const PaymentPageHotel({
    super.key,
    required this.reservation,
    required this.totalPrice,
    required this.hotel,
    required Map<String, String> userData,
  });

  @override
  State<PaymentPageHotel> createState() => PaymentPageHotelState();
}

class PaymentPageHotelState extends State<PaymentPageHotel> {
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
      final updatedReservation = widget.reservation.copyWith(
        paymentMethod: selectedPayment!['card_type'],
        status: 'confirmed',
      );

      await _firestore
          .collection('hotel_reservations')
          .add(updatedReservation.toMap());

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
        SnackBar(content: Text('erreur_paiement'.tr(args: [e.toString()]))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Confirmation_de_paiement".tr()),
        backgroundColor: Colors.blue,
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
