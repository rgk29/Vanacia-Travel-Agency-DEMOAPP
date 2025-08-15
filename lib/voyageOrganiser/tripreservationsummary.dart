import 'package:agencedevoyage/api/firebase_api.dart';
import 'package:agencedevoyage/homepage.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:agencedevoyage/voyageOrganiser/trip.dart'; // Import de votre modèle Trip

class TripReservationSummaryPage extends StatelessWidget {
  final Reservation reservation;
  final Hotel hotel;

  // Constructeur
  const TripReservationSummaryPage({
    super.key,
    required this.reservation,
    required this.hotel,
  });

  // Méthode pour afficher les photos de l'hôtel
  Widget _buildHotelPhotos(Hotel hotel) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: hotel.photos.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(left: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              hotel.photos[index],
              width: 300,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Résumé_de_la_Réservation').tr(),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade800, Colors.lightBlue.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 3,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_user,
                          color: Colors.blue.shade800, size: 18),
                      const SizedBox(width: 8),
                      Text('Confirmation_de_réservation'.tr(),
                          style: TextStyle(
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Carte hôtel
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(15)),
                        child: _buildHotelPhotos(hotel),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    hotel.name,
                                    style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.indigo),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: Colors.amber.shade100,
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Row(
                                    children: [
                                      Icon(Icons.star,
                                          color: Colors.amber.shade700,
                                          size: 20),
                                      Text(' ${hotel.stars}',
                                          style: TextStyle(
                                              color: Colors.amber.shade800,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              Icons.king_bed,
                              '${'Type_de_chambre'.tr()}: ${'room_types.${reservation.roomType.toLowerCase() ?? 'unknown'}'.tr()}',
                            ),
                            _buildDetailRow(Icons.flight_takeoff,
                                '${'Départ'.tr()}: ${reservation.departureDate.toLocal().toString().split(' ')[0]}'),
                            _buildDetailRow(Icons.flight_land,
                                '${'Retour'.tr()}: ${reservation.returnDate.toLocal().toString().split(' ')[0]}'),
                            _buildDetailRow(Icons.timelapse,
                                '${'Durée'.tr()}: ${reservation.returnDate.difference(reservation.departureDate).inDays} ${'jours'.tr()}'),
                            _buildDetailRow(Icons.location_pin,
                                '${'Adresse'.tr()}: ${hotel.address}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Section prix
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 10,
                          spreadRadius: 2),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total_a_payer'.tr(),
                          style: const TextStyle(
                              fontSize: 14, color: Colors.grey)),
                      Text('${reservation.totalPrice} ${reservation.currency}',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo)),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Bouton d'action
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.celebration, color: Colors.white),
                    label: Text('Réservation_Confirmée_!'.tr(),
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue.shade800,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      shadowColor: Colors.blue.shade200,
                      elevation: 5,
                    ),
                    onPressed: () {
                      // Ajouter la notification ici
                      FirebaseApi.instance.addLocalNotification(
                        title: 'Confirmation_de_voyage',
                        body: 'Votre séjour à ${hotel.name} est confirmé !   ',
                        data: {
                          'type': 'trip_reservation',
                          'hotelName': hotel.name,
                          'price':
                              '${reservation.totalPrice} ${reservation.currency}',
                          'dates':
                              '${reservation.departureDate.toLocal().toString().split(' ')[0]}'
                                  ' - ${reservation.returnDate.toLocal().toString().split(' ')[0]}'
                        },
                      );

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => HomePage()),
                        (Route<dynamic> route) => false,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade600, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
