// admin_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> isAdmin(User? user) async {
    if (user == null) return false;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data()?['isAdmin'] ?? false;
  }

  Future<void> setAdminStatus(String userId, bool isAdmin) async {
    await _firestore.collection('users').doc(userId).update({
      'isAdmin': isAdmin,
    });
  }
}
