import 'package:agencedevoyage/currency_provider.dart';
import 'package:agencedevoyage/voiture/recherche.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agencedevoyage/voiture/local.dart';

class ReservationSummaryPage extends ConsumerWidget {
  final Map<String, dynamic> reservationData;
  final CarModel car;
  final String totalPrice;

  const ReservationSummaryPage({
    super.key,
    required this.car,
    required this.totalPrice,
    required this.reservationData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ajouter WidgetRef
    final currencyNotifier = ref.watch(currencyProvider.notifier);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(
          child: Text("Vous_devez_être_connecté_pour_voir_les_détails".tr()));
    }

    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text("Détails_de_la_réservation".tr()),
        elevation: 4,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // if (snapshot.hasError) {
          //   return Center(child: Text('Erreur: ${snapshot.error}'));
          // }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final fullName = userData['fullName'] ?? "Non_spécifié".tr();

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section photo et caractéristiques principales
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            car.imageUrl,
                            height: 220,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              height: 220,
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.error_outline,
                                    color: Colors.red),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                car.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[800],
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                children: [
                                  _buildFeatureChip(
                                    icon: Icons.directions_car,
                                    label: car.type,
                                  ),
                                  _buildFeatureChip(
                                    icon: car.transmission == 'Automatique'
                                        ? Icons.settings
                                        : Icons.engineering,
                                    label: car.transmission,
                                  ),
                                  _buildFeatureChip(
                                    icon: Icons.door_front_door,
                                    label: '${car.doors} portes',
                                  ),
                                  _buildFeatureChip(
                                    icon: Icons.ac_unit,
                                    label: car.hasAC
                                        ? 'Climatisation'
                                        : 'Pas de climatisation',
                                    color: car.hasAC
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Section détails de location
                  _buildSectionTitle(context, 'Détails_de_la_location'.tr()),
                  _buildDetailCard(
                    children: [
                      _buildDetailItem(
                        icon: Icons.location_on,
                        title: 'Prise_en_charge'.tr(),
                        subtitle: car.pickupLocation,
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(dateFormat.format(car.pickupDate)),
                            Text(car.formattedPickupTime),
                          ],
                        ),
                      ),
                      const Divider(height: 30),
                      _buildDetailItem(
                        icon: Icons.location_off,
                        title: 'Retour'.tr(),
                        subtitle: car.returnLocation,
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(dateFormat.format(car.returnDate)),
                            // Text('Avant ${timeFormat.format(car.returnDate)}'),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Section coûts et politique
                  _buildSectionTitle(context, 'Coûts'.tr()),
                  _buildDetailCard(
                    children: [
                      _buildPriceRow(
                        'Prix_journalier'.tr(),
                        currencyNotifier.formatPrice(car.pricePerDay),
                      ),
                      _buildPriceRow(
                        'Durée_location'.tr(),
                        '${car.returnDate.difference(car.pickupDate).inDays} jours',
                      ),
                      _buildPriceRow(
                        'Dépôt_de_garantie'.tr(),
                        currencyNotifier.formatPrice(car.securityDeposit),
                        color: Colors.orange,
                      ),
                      const Divider(height: 30),
                      _buildPriceRow(
                        'Total_à_payer'.tr(),
                        totalPrice,
                        isTotal: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // Bouton de confirmation
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () => _saveReservation(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 35,
                        ),
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                        shadowColor: primaryColor.withOpacity(0.3),
                      ),
                      icon: const Icon(
                        Icons.verified_user,
                        size: 24,
                        color: Colors.white,
                      ),
                      label: Text(
                        "Réservation_Confirmer_👌".tr(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.05,
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

  void _saveReservation(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      // if (user == null) return;

      // Ajout infos client
      final DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .get();

      final userData = userSnapshot.data() as Map<String, dynamic>?;

      final reservationWithUserInfo = {
        ...reservationData,
        'clientInfo': {
          'fullName': userData?['fullName'] ?? 'Nom inconnu',
          'email': user?.email ?? 'Email inconnu',
          'uid': user?.uid,
        },
        'userId': user?.uid, // important pour que Firestore autorise l'ajout
        'timestamp': FieldValue.serverTimestamp(),
      };
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 10),
                Text(
                  'Confirmation_réussie'.tr(),
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext); // Ferme la boîte de dialogue
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/HomePage', (route) => false);
                },
                child: Text('OK'.tr()),
              ),
            ],
          );
        },
      );
      await FirebaseFirestore.instance
          .collection('reservations')
          .add(reservationWithUserInfo);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Réservation_enregistrée_avec_succès".tr())),
      );

      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur de sauvegarde: ${e.toString()}")),
      );
    }
  }

// Méthodes helper
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
      ),
    );
  }

  Widget _buildDetailCard({required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue[800], size: 28),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(subtitle, style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
        trailing,
      ],
    );
  }

  Widget _buildPriceRow(String label, String value,
      {Color? color, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(
                fontSize: isTotal ? 16 : 15,
                color: Colors.grey[700],
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              )),
          const Spacer(),
          Text(value,
              style: TextStyle(
                fontSize: isTotal ? 18 : 16,
                color: color ?? (isTotal ? Colors.green : Colors.blueGrey[800]),
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              )),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(
      {required IconData icon, required String label, Color? color}) {
    return Chip(
      avatar: Icon(icon, size: 18, color: color ?? Colors.blue[800]),
      label: Text(label),
      backgroundColor: Colors.blue[50],
      side: BorderSide(color: Colors.blue[100]!),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
