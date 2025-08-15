import 'package:agencedevoyage/api/firebase_api.dart';
import 'package:agencedevoyage/voiture/local.dart';
import 'package:agencedevoyage/voiture/paimentselectionstep.dart';
import 'package:agencedevoyage/voiture/recherche.dart';
import 'package:agencedevoyage/voiture/reservationdetails.dart';
// import 'package:agencedevoyage/voyageOrganiser/trip.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class PaymentPage extends StatefulWidget {
  final CarModel car;
  final String totalPrice;
  final Map<String, dynamic> userData;

  const PaymentPage({
    super.key,
    required this.car,
    required this.totalPrice,
    required this.userData,
  });

  @override
  State<PaymentPage> createState() => PaymentPageState();
}

class PaymentPageState extends State<PaymentPage> {
  Map<String, dynamic>? selectedPayment;

  void _navigateToSummary() {
    if (selectedPayment == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('selectionnez_moyen_paiement'.tr()),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    FirebaseApi.instance.addLocalNotification(
      title: 'Confirmation_de_Réservation'.tr(),
      body: 'Votre_réservation_est_confirmée_pour'
          .tr(namedArgs: {'car': widget.car.name}),
      data: {
        'type': 'reservation',
        'carName': widget.car.name, // 🚗 Nom de la voiture depuis CarModel
        'price': widget.totalPrice,
      },
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReservationSummaryPage(
          reservationData: {
            'userDetails': widget.userData,
            'paymentDetails': selectedPayment,
            'carDetails': widget.car.toJson(),
            'totalPrice': widget.totalPrice,
          },
          car: widget.car,
          totalPrice: widget.totalPrice,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Confirmation_de_paiement".tr(),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: const Color.fromARGB(255, 239, 245, 250),
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: primaryColor,
          ),
        ),
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
            Padding(
              padding: const EdgeInsets.all(20.0),
              // child: Text(
              //   'Montant total : ${widget.totalPrice}',
              //   style: TextStyle(
              //     fontSize: 22,
              //     fontWeight: FontWeight.bold,
              //     color: Colors.blue.shade900,
              //   ),
              // ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Material(
                  borderRadius: BorderRadius.circular(15),
                  elevation: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: PaymentSelectionStep(
                      totalAmount: widget.totalPrice,
                      onCardSelected: (card) =>
                          setState(() => selectedPayment = card),
                      cardHeight: 160,
                      cardColor: Colors.blue.shade100,
                      selectedCardColor: Colors.blue.shade400,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _navigateToSummary,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: accentColor,
                    shadowColor: Colors.blue.shade200,
                    elevation: 5,
                  ),
                  child: Text(
                    'Voir_les_détails_de_ma_réservation'.tr(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
