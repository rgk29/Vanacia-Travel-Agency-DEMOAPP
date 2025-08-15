import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:agencedevoyage/vol/model.dart' as model;

final userProvider = StateNotifierProvider<UserNotifier, model.User>((ref) {
  return UserNotifier();
});

class UserNotifier extends StateNotifier<model.User> {
  final fb_auth.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  StreamSubscription<fb_auth.User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  UserNotifier()
      : _auth = fb_auth.FirebaseAuth.instance,
        _firestore = FirebaseFirestore.instance,
        super(model.User.initial()) {
    _authSubscription = _auth.authStateChanges().listen((firebaseUser) {
      if (firebaseUser == null) {
        _loadLocalGuestUser();
      } else {
        _setupUserStream(firebaseUser.uid);
      }
    });
  }

  void _setupUserStream(String userId) {
    _userSubscription?.cancel();
    _userSubscription =
        _firestore.collection('users').doc(userId).snapshots().listen((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        state = model.User(
          id: doc.id,
          fullName: data['fullName'] ?? '',
          country: data['country'] ?? '',
          email: data['email'] ?? '',
          passport: data['passport'] ?? '',
          address: data['address'] ?? '',
          bookings: state.bookings,
          preferredCurrency: data['preferredCurrency'] ?? 'DZD',
          gender: data['gender'] ?? '',
          phone: data['phone'] ?? '',
        );
      }
    });
  }

  Future<void> _loadLocalGuestUser() async {
    final prefs = await SharedPreferences.getInstance();
    final bookingsJson = prefs.getString('guest_bookings');
    final currency = prefs.getString('currency') ?? 'DZD';

    List<model.Booking> localBookings = [];

    if (bookingsJson != null) {
      final decoded = json.decode(bookingsJson) as List<dynamic>;
      localBookings = decoded.map((e) => model.Booking.fromJson(e)).toList();
    }

    state = model.User(
      id: 'default',
      fullName: 'Invité',
      country: '',
      email: '',
      passport: '',
      address: '',
      bookings: localBookings,
      preferredCurrency: currency,
      gender: '',
      phone: '',
    );
  }

  Future<void> _saveGuestBookings(List<model.Booking> bookings) async {
    final prefs = await SharedPreferences.getInstance();
    final bookingsJson = json.encode(bookings.map((e) => e.toJson()).toList());
    await prefs.setString('guest_bookings', bookingsJson);
  }

  Future<void> updateCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', currency);

    if (state.id != 'default') {
      await _firestore
          .collection('users')
          .doc(state.id)
          .update({'preferredCurrency': currency});
    }

    state = state.copyWith(preferredCurrency: currency);
  }

  Future<void> addBooking(model.Booking booking) async {
    try {
      final newBooking = booking.copyWith(userId: state.id);

      if (state.id == 'default') {
        final updatedBookings = [...state.bookings, newBooking];
        await _saveGuestBookings(updatedBookings);
        state = state.copyWith(bookings: updatedBookings);
      } else {
        final docRef =
            await _firestore.collection('bookings').add(newBooking.toJson());
        final updatedBooking = newBooking.copyWith(id: docRef.id);
        final newBookings = [...state.bookings, updatedBooking];

        await _firestore.collection('users').doc(state.id).update({
          'bookings': FieldValue.arrayUnion([updatedBooking.toJson()])
        });

        state = state.copyWith(bookings: newBookings);
      }
    } catch (e) {
      print('Erreur Firebase: $e');
      rethrow;
    }
  }

  Future<void> deleteBooking(String bookingId) async {
    try {
      final newBookings =
          state.bookings.where((b) => b.id != bookingId).toList();

      if (state.id == 'default') {
        await _saveGuestBookings(newBookings);
      } else {
        await _firestore.collection('bookings').doc(bookingId).delete();
        await _firestore
            .collection('users')
            .doc(state.id)
            .update({'bookings': newBookings.map((b) => b.toJson()).toList()});
      }

      state = state.copyWith(bookings: newBookings);
    } catch (e) {
      print('Erreur suppression: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _userSubscription?.cancel();
    super.dispose();
  }
}

bool isAuthenticated(model.User user) => user.id != 'default';

extension BookingExtension on model.Booking {
  model.Booking copyWith({
    String? id,
    String? userId,
    model.Flight? departureFlight,
    model.Flight? returnFlight,
    model.PassengerCount? passengers,
    DateTime? bookingDate,
    String? tripType,
  }) {
    return model.Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      departureFlight: departureFlight ?? this.departureFlight,
      returnFlight: returnFlight ?? this.returnFlight,
      passengers: passengers ?? this.passengers,
      bookingDate: bookingDate ?? this.bookingDate,
      tripType: tripType ?? this.tripType,
    );
  }
}
