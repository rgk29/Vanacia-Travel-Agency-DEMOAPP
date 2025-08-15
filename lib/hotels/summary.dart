import 'package:agencedevoyage/api/firebase_api.dart';
import 'package:agencedevoyage/hotels/data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'local.dart';

class HotelSummaryPage extends StatelessWidget {
  final Hotells hotel;
  final VoidCallback onConfirm;

  const HotelSummaryPage({
    super.key,
    required this.hotel,
    required this.onConfirm,
    required HotelReservation reservation,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        colorScheme: ColorScheme.light(
          primary: Colors.blue.shade800,
          secondary: Colors.amber.shade600,
        ),
        fontFamily: 'Montserrat',
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Confirmation_de_Réservation'.tr()),
          centerTitle: true,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageGallery(),
              const SizedBox(height: 24),
              _buildHotelHeader(),
              const SizedBox(height: 20),
              _buildDetailCards(),
              const SizedBox(height: 30),
              _buildPriceSection(),
              const SizedBox(height: 30),
              _buildConfirmationButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageGallery() {
    return SizedBox(
      height: 250,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: hotel.imageUrls.length,
            itemBuilder: (context, index) => Image.asset(
              hotel.imageUrls[index],
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${hotel.imageUrls.length} photos',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotelHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hotel.name.tr(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              '${hotel.address.city.tr()}, ${hotel.address.country.tr()}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(
            5,
            (index) => Icon(
              index < hotel.stars ? Icons.star : Icons.star_border,
              color: Colors.amber.shade600,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCards() {
    return Column(
      children: [
        _buildInfoCard(
          icon: Icons.calendar_today,
          title: 'Dates_de_séjour'.tr(),
          content: Text(
              'Du ${_formatDate(hotel.arrivalDate)} au ${_formatDate(hotel.departureDate)}'),
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          icon: Icons.hotel,
          title: 'Équipements'.tr(),
          content: Wrap(
            spacing: 8,
            children: hotel.facilities
                .map((f) => Chip(
                      backgroundColor: Colors.blue.shade50,
                      avatar: Icon(f.icon, size: 18),
                      label: Text(_getFacilityTranslation(f).toUpperCase()),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          icon: Icons.place,
          title: 'À_proximité'.tr(),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: hotel.nearbyPoints.entries
                .map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(_getCategoryIcon(entry.key), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${entry.key.tr()} : ${entry.value.map((e) => e.tr()).join(', ')}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
      {required IconData icon,
      required String title,
      required Widget content}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue.shade800),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Total_de_votre_séjour'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${hotel.pricePerNight * hotel.durationDays} DA',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'booking_nights_price'.tr(namedArgs: {
              'nights': hotel.durationDays.toString(),
              'price': hotel.pricePerNight.toString(),
            }),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          onConfirm();
          _showConfirmationDialog(context);
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.blue.shade800,
        ),
        child: Text(
          'Réservation_avec_Succes'.tr(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // Dans HotelSummaryPage
  void _showConfirmationDialog(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Enregistrer la réservation dans Firestore
      await FirebaseFirestore.instance.collection('hotel_reservations').add({
        'userId': user.uid,
        'email': user.email,
        'clientName': user.displayName ?? 'Client',
        'hotelId': hotel.id,
        'hotelName': hotel.name,
        'checkInDate': _formatDate(hotel.arrivalDate),
        'checkOutDate': _formatDate(hotel.departureDate),
        'nightsCount': hotel.durationDays,
        'totalPrice': hotel.pricePerNight * hotel.durationDays,
        'currency': '',
        'roomType': '', // À adapter selon votre logique
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'confirmed'
      });
      FirebaseApi().addLocalNotification(
        title: 'Réservation_hôtelière_confirmée_🎉'.tr(),
        body: 'Votre_séjour_est_confirmé'
            .tr(namedArgs: {'name': hotel.name.tr()}),
        data: {
          'type': 'hotel',
          'id': hotel.id,
          'hotelId': hotel.id,
          'action': 'open_reservation'
        },
      );

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
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            // content: Text(
            //   'Un email de confirmation a été envoyé à ${user.email}',
            //   style: const TextStyle(fontSize: 16),
            // ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/HomePage', (route) => false);
                },
                child: Text('OK'.tr()),
              ),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  Widget _buildConfirmationDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Monuments':
        return Icons.landscape;
      case 'Restaurants':
        return Icons.restaurant;
      case 'Nature':
        return Icons.nature;
      case 'Commodités':
        return Icons.shopping_cart;
      default:
        return Icons.place;
    }
  }
}

String _getFacilityTranslation(Facilities facility) {
  switch (facility) {
    case Facilities.wifi:
      return 'facilities.wifi'.tr(); // traduction pour wifi
    case Facilities.tv:
      return 'facilities.tv'.tr(); // traduction pour tv
    case Facilities.parking:
      return 'facilities.parking'.tr(); // traduction pour parking
    case Facilities.pool:
      return 'facilities.pool'.tr(); // traduction pour piscine
    case Facilities.restaurant:
      return 'facilities.restaurant'.tr(); // traduction pour restaurant
    case Facilities.spa:
      return 'facilities.spa'.tr(); // traduction pour spa
    case Facilities.airportShuttle:
      return 'facilities.airportShuttle'
          .tr(); // traduction pour navette aéroport
    case Facilities.nonSmokingRooms:
      return 'facilities.nonSmokingRooms'
          .tr(); // traduction pour chambres non fumeur
    case Facilities.frontDesk24h:
      return 'facilities.frontDesk24h'.tr(); // traduction pour réception 24h
    case Facilities.heating:
      return 'facilities.heating'.tr(); // traduction pour chauffage
    case Facilities.housekeeping:
      return 'facilities.housekeeping'.tr(); // traduction pour ménage
    case Facilities.luggageStorage:
      return 'facilities.luggageStorage'
          .tr(); // traduction pour consigne à bagages
    case Facilities.airConditioning:
      return 'facilities.airConditioning'.tr(); // traduction pour climatisation
    case Facilities.roomService:
      return 'facilities.roomService'.tr(); // traduction pour service d'étage
    case Facilities.familyRooms:
      return 'facilities.familyRooms'
          .tr(); // traduction pour chambres familiales
    case Facilities.breakfast:
      return 'facilities.breakfast'.tr(); // traduction pour petit-déjeuner
    case Facilities.kitchen:
      return 'facilities.kitchen'.tr(); // traduction pour cuisine
    case Facilities.garden:
      return 'facilities.garden'.tr(); // traduction pour jardin
    case Facilities.petsAllowed:
      return 'facilities.petsAllowed'.tr(); // traduction pour animaux acceptés
    default:
      return '';
  }
}
