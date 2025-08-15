import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReservationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveReservation(Map<String, dynamic> reservationData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Utilisateur non connecté");

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('reservations')
        .add(reservationData);
  }

  Stream<QuerySnapshot> getReservations() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Utilisateur non connecté");

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('reservations')
        .orderBy('reservationDate', descending: true)
        .snapshots();
  }
}
