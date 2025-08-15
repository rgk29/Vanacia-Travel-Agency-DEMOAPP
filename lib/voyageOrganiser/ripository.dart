import 'package:agencedevoyage/voyageOrganiser/trip.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReservationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> saveReservation(Reservation reservation) async {
    await _firestore
        .collection('organized_trips_reservations')
        .add(reservation.toMap());
  }

  String? getCurrentUserEmail() {
    return _auth.currentUser?.email;
  }
}
