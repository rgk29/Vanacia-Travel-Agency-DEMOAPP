import 'dart:math';

import 'package:agencedevoyage/currency_provider.dart';
import 'package:agencedevoyage/voiture/local.dart';
import 'package:agencedevoyage/voiture/personalinfo.dart';
import 'package:agencedevoyage/voiture/recherche.dart';
import 'package:agencedevoyage/voiture/reservationdetails.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CarDetailsPage extends ConsumerWidget {
  final CarModel car;
  final String totalPrice;

  const CarDetailsPage(
      {super.key, required this.car, required this.totalPrice});

  void _navigateToReservationForm(BuildContext context, WidgetRef ref) {
    // 1. Calculer rentalDays
    final rentalDays = car.returnDate.difference(car.pickupDate).inDays;

    // 2. Accéder correctement au CurrencyNotifier
    final currencyNotifier = ref.read(currencyProvider.notifier);

    // 3. Formater le prix
    final formattedPrice =
        currencyNotifier.formatPrice(car.pricePerDay * rentalDays);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PersonalInfoPage(
          car: car,
          totalPrice: formattedPrice,
        ),
      ),
    );
  }

  Future<void> _confirmReservation(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("connectez_vous_dabord".tr())),
        );
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final pickupDateTime = DateTime(
        car.pickupDate.year,
        car.pickupDate.month,
        car.pickupDate.day,
        car.pickupTime.hour,
        car.pickupTime.minute,
      );

      final returnDateTime = DateTime(
        car.returnDate.year,
        car.returnDate.month,
        car.returnDate.day,
        0, // Heure par défaut si non spécifiée
        0,
      );

      final reservationData = {
        'userId': user.uid,
        'userEmail': user.email,
        'fullName': userDoc['fullName'],
        'carImage': car.imageUrl,
        'carName': car.name,
        'totalPrice': totalPrice,
        'pickupLocation': car.pickupLocation,
        'returnLocation': car.returnLocation,
        'pickupDateTime': pickupDateTime.toIso8601String(),
        'returnDateTime': returnDateTime.toIso8601String(),
        'pickupTime': '${car.pickupTime.hour}:${car.pickupTime.minute}',
        'reservationDate': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('reservations')
          .add(reservationData);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReservationSummaryPage(
            reservationData: reservationData,
            car: car,
            totalPrice: totalPrice,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final currencyNotifier = ref.watch(currencyProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text("Détails_de_la_réservation".tr())),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("${'erreur'.tr()}: ${e.toString()}"));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Utilisateur_non_trouvé'.tr()));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final fullName = userData['fullName'] ?? "Non spécifié";

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    car.imageUrl,
                    height: 200,
                    width: 400,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    car.name,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "specifications_vehicule".tr(namedArgs: {
                      'type': car.type,
                      'transmission': car.transmission,
                      'doors': car.doors.toString()
                    }),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'agence_de_location'
                        .tr(namedArgs: {'agency': car.rentalAgency}),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "lieu_de_prise_en_charge"
                        .tr(namedArgs: {'pickupLocation': car.pickupLocation}),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "lieu_de_retour"
                        .tr(namedArgs: {'returnLocation': car.returnLocation}),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "politique_annulation"
                        .tr(namedArgs: {'policy': car.cancellationPolicy}),
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "depot_garantie".tr(namedArgs: {
                      'amount':
                          currencyNotifier.formatPrice(car.securityDeposit)
                    }),
                  ),
                  Text(
                    "prix_total".tr(namedArgs: {'total': totalPrice}),
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _navigateToReservationForm(context, ref),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 30),
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 5,
                      shadowColor: primaryColor.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      animationDuration: const Duration(milliseconds: 200),
                      enableFeedback: true,
                    ),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_outline,
                                size: 24, color: Colors.white),
                            const SizedBox(width: 5),
                            Text(
                              "Confirmer_la_réservation".tr(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
