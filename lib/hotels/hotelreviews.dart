import 'package:agencedevoyage/hotels/local.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HotelReviewsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addReview({
    required String hotelId,
    required String text,
    required double rating,
    required String userName,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');
    if (text.isEmpty) throw Exception('Le texte ne peut pas être vide');
    if (rating < 1 || rating > 5) throw Exception('Note invalide');

    final reviewRef = _firestore
        .collection('hotels')
        .doc(hotelId)
        .collection('reviews')
        .doc();

    await reviewRef.set({
      'id': reviewRef.id,
      'userId': user.uid,
      'userName': userName,
      'text': text,
      'rating': rating,
      'date': DateTime.now().toIso8601String(),
      'likedBy': [],
      'dislikedBy': [],
    });
  }

  Future<void> updateReview({
    required String hotelId,
    required String reviewId,
    required String text,
    required double rating,
  }) async {
    await _firestore
        .collection('hotels')
        .doc(hotelId)
        .collection('reviews')
        .doc(reviewId)
        .update({
      'text': text,
      'rating': rating,
    });
  }

  Future<void> deleteReview({
    required String hotelId,
    required String reviewId,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final docRef = _firestore
          .collection('hotels')
          .doc(hotelId)
          .collection('reviews')
          .doc(reviewId);

      // Vérification supplémentaire côté client
      final doc = await docRef.get();
      if (!doc.exists) throw Exception('Review not found');
      if (doc.data()?['userId'] != user.uid) {
        throw Exception('Not authorized to delete this review');
      }

      await docRef.delete();
    } catch (e) {
      print('Error deleting review: $e');
      rethrow;
    }
  }

  Future<void> toggleLike({
    required String hotelId,
    required String reviewId,
    required String userId,
    required bool isLike,
  }) async {
    try {
      final reviewRef = _firestore
          .collection('hotels')
          .doc(hotelId)
          .collection('reviews')
          .doc(reviewId);

      final updates = <String, dynamic>{};

      if (isLike) {
        updates['likedBy'] = FieldValue.arrayUnion([userId]);
        updates['dislikedBy'] = FieldValue.arrayRemove([userId]);
      } else {
        updates['likedBy'] = FieldValue.arrayRemove([userId]);
        updates['dislikedBy'] = FieldValue.arrayUnion([userId]);
      }

      await reviewRef.update(updates);
    } catch (e) {
      print('Error in toggleLike: $e');
      throw Exception('Failed to update like status: ${e.toString()}');
    }
  }

  Stream<List<Review>> getReviewsStream(String hotelId) {
    return _firestore
        .collection('hotels')
        .doc(hotelId)
        .collection('reviews')
        .orderBy('date', descending: true)
        .snapshots()
        .handleError((error) {
      print('Error fetching reviews: $error');
      throw error;
    }).map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          return Review.fromMap(doc.data());
        } catch (e) {
          print('Error parsing document ${doc.id}: $e');
          rethrow;
        }
      }).toList();
    });
  }
}
