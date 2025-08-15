// trip_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// Ajoutez 'hide PaymentMethod' si la classe existe dans les deux fichiers

// ... reste de l'implémentation ...

class Reservation {
  final String userEmail;
  final String roomType;
  final String departureCity;
  final String destination;
  final DateTime departureDate;
  final DateTime returnDate;
  final String hotelName;
  final int hotelStars;
  final String paymentMethod;
  final double totalPrice;
  final String currency;
  final String status;
  final String reservationType;

  const Reservation({
    required this.userEmail,
    required this.roomType,
    required this.departureCity,
    required this.destination,
    required this.departureDate,
    required this.returnDate,
    required this.hotelName,
    required this.hotelStars,
    required this.paymentMethod,
    required this.totalPrice,
    required this.currency,
    required this.status,
    required this.reservationType,
  });

  Reservation copyWith({
    String? userEmail,
    String? roomType,
    String? departureCity,
    String? destination,
    DateTime? departureDate,
    DateTime? returnDate,
    String? hotelName,
    int? hotelStars,
    double? totalPrice,
    String? currency,
    String? paymentMethod,
    required String status,
    String? reservationType,
  }) {
    return Reservation(
      userEmail: userEmail ?? this.userEmail,
      roomType: roomType ?? this.roomType,
      departureCity: departureCity ?? this.departureCity,
      destination: destination ?? this.destination,
      departureDate: departureDate ?? this.departureDate,
      returnDate: returnDate ?? this.returnDate,
      hotelName: hotelName ?? this.hotelName,
      hotelStars: hotelStars ?? this.hotelStars,
      totalPrice: totalPrice ?? this.totalPrice,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      reservationType: reservationType ?? this.reservationType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userEmail': userEmail,
      'roomType': roomType,
      'departureCity': departureCity,
      'destination': destination,
      'departureDate': departureDate,
      'returnDate': returnDate,
      'hotelName': hotelName,
      'hotelStars': hotelStars,
      'paymentMethod': paymentMethod,
      'totalPrice': totalPrice,
      'currency': currency,
      'createdAt': FieldValue.serverTimestamp(),
      'status': status,
      'reservationType': reservationType,
    };
  }

  factory Reservation.fromMap(Map<String, dynamic> map) {
    return Reservation(
      userEmail: map['userEmail'],
      roomType: map['roomType'],
      departureCity: map['departureCity'],
      destination: map['destination'],
      departureDate: (map['departureDate'] as Timestamp).toDate(),
      returnDate: (map['returnDate'] as Timestamp).toDate(),
      hotelName: map['hotelName'],
      hotelStars: (map['hotelStars'] as num?)?.toInt() ?? 0,
      paymentMethod: map['paymentMethod'],
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'],
      status: (map['status'] as String?) ?? 'unknown',
      reservationType: map['reservationType'] ?? 'trip',
    );
  }
}

class PaymentMethod {
  final String cardNumber;
  final String expiryDate;
  final String cvv;
  final String type;

  const PaymentMethod({
    required this.cardNumber,
    required this.expiryDate,
    required this.cvv,
    required this.type,
  });

  String get maskedNumber => '**** **** **** ${cardNumber.substring(15)}';

  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      cardNumber: map['cardNumber'],
      expiryDate: map['expiryDate'],
      cvv: map['cvv'],
      type: map['type'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cardNumber': cardNumber,
      'expiryDate': expiryDate,
      'cvv': cvv,
      'type': type,
    };
  }

  static String detectCardType(String number) {
    if (number.startsWith('4')) return 'Visa';
    if (number.startsWith(RegExp(r'5[1-5]'))) return 'Mastercard';
    return 'Autre';
  }
}

class Trip {
  final String id;
  final String departureCity;
  final DateTime departureDate;
  final TimeOfDay departureTime;
  final DateTime returnDate;
  final String destination;
  final int durationDays;
  final String description;
  final List<String> photos;
  final List<Hotel> hotels;
  final List<ExtraExcursion> extras;
  final int totalTickets;
  int remainingTickets;
  final String reservationType;

  Trip({
    required this.id,
    required this.departureCity,
    required this.departureDate,
    required this.departureTime,
    required this.destination,
    required this.durationDays,
    required this.description,
    required this.photos,
    required this.hotels,
    required this.extras,
    required this.totalTickets,
    required this.remainingTickets,
    required this.returnDate,
    required this.reservationType,
  });
  Trip copyWith({
    String? id,
    String? departureCity,
    DateTime? departureDate,
    DateTime? returnDate,
    TimeOfDay? departureTime,
    String? destination,
    int? durationDays,
    String? description,
    List<String>? photos,
    List<Hotel>? hotels,
    List<ExtraExcursion>? extras,
    int? totalTickets,
    int? remainingTickets,
    String? reservationType,
  }) {
    return Trip(
      id: id ?? this.id,
      departureCity: departureCity ?? this.departureCity,
      departureDate: departureDate ?? this.departureDate,
      departureTime: departureTime ?? this.departureTime,
      returnDate: returnDate ?? this.returnDate,
      destination: destination ?? this.destination,
      durationDays: durationDays ?? this.durationDays,
      description: description ?? this.description,
      photos: photos ?? this.photos,
      hotels: hotels ?? this.hotels,
      extras: extras ?? this.extras,
      totalTickets: totalTickets ?? this.totalTickets,
      remainingTickets: remainingTickets ?? this.remainingTickets,
      reservationType: reservationType ?? this.reservationType,
    );
  }

  static Trip placeholder() => Trip(
      id: 'placeholder',
      departureCity: 'Ville inconnue',
      departureDate: DateTime.now(),
      returnDate: DateTime.now(),
      departureTime: TimeOfDay.now(),
      destination: 'Destination inconnue',
      durationDays: 0,
      description: 'Description temporaire',
      photos: [],
      hotels: [],
      extras: [],
      totalTickets: 0,
      remainingTickets: 0,
      reservationType: 'trip');
}

class Hotel {
  final String id;
  final String name;
  final int stars;
  final List<String> photos;
  final String address;
  final Map<String, double> roomPrices;
  final Map<String, int> availableRooms;
  final List<String> services;
  final Location location;
  final List<PointOfInterest> nearbyPlaces;

  Hotel({
    required this.id,
    this.name = '',
    this.stars = 0,
    this.photos = const [],
    this.address = '',
    this.roomPrices = const {},
    this.availableRooms = const {},
    this.services = const [],
    this.location = const Location(lat: 0.0, lng: 0.0),
    this.nearbyPlaces = const [],
  });

  Hotel copyWith({
    Map<String, int>? availableRooms,
  }) {
    return Hotel(
      id: id,
      name: name,
      stars: stars,
      photos: photos,
      address: address,
      roomPrices: roomPrices,
      availableRooms: availableRooms ?? this.availableRooms,
      services: services,
      location: location,
      nearbyPlaces: nearbyPlaces,
    );
  }

  factory Hotel.fromMap(Map<String, dynamic> map) {
    return Hotel(
      id: map['id'] ?? '',
      name: map['name'] as String? ?? '',
      stars: (map['stars'] as num?)?.toInt() ?? 0,
      photos: List<String>.from(map['photos'] ?? []),
      address: map['address'] as String? ?? '',
      roomPrices: _parseRoomPrices(map['roomPrices']),
      availableRooms: _parseAvailableRooms(map['availableRooms']),
      services: List<String>.from(map['services'] ?? []),
      location: Location.fromMap(map['location'] ?? {}),
      nearbyPlaces: _parseNearbyPlaces(map['nearbyPlaces']),
    );
  }
  static Map<String, double> _parseRoomPrices(dynamic data) {
    final result = <String, double>{};
    if (data is Map) {
      data.forEach((key, value) {
        final k = key.toString();
        final v = (value is num ? value.toDouble() : 0.0);
        result[k] = v;
      });
    }
    return result;
  }

  static Map<String, int> _parseAvailableRooms(dynamic data) {
    final result = <String, int>{};
    if (data is Map) {
      data.forEach((key, value) {
        final k = key.toString();
        final v = (value is num ? value.toInt() : 0);
        result[k] = v;
      });
    }
    return result;
  }

  static List<PointOfInterest> _parseNearbyPlaces(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => PointOfInterest.fromMap(e))
          .toList();
    }
    return [];
  }
}

class ExtraExcursion {
  final String name;
  final double adultPrice;
  final double childPrice;
  final String description;
  final List<String> imageUrl;

  ExtraExcursion({
    required this.name,
    required this.adultPrice,
    required this.childPrice,
    required this.description,
    this.imageUrl = const [],
  });
}

class Location {
  final double lat;
  final double lng;

  const Location({required this.lat, required this.lng});
  factory Location.fromMap(Map<String, dynamic> map) {
    return Location(
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PointOfInterest {
  final String name;
  final double distance;
  final IconData icon;

  PointOfInterest({
    required this.name,
    required this.distance,
    this.icon = Icons.place,
  });
  factory PointOfInterest.fromMap(Map<String, dynamic> map) {
    return PointOfInterest(
      name: map['name'] as String? ?? '',
      distance: (map['distance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

extension TripExtensions on Trip {
  double get minPrice {
    if (hotels.isEmpty) return 0;
    return MinDoubleList(
        hotels.map((h) => MinDoubleList(h.roomPrices.values).min)).min;
  }
}

// Dans votre classe Hotel (trip.dart), ajoutez :
extension HotelExtensions on Hotel {
  double get minRoomPrice => roomPrices.values.reduce((a, b) => a < b ? a : b);
}

// Extension pour les listes de doubles
extension MinDoubleList on Iterable<double> {
  double get min => reduce((a, b) => a < b ? a : b);
}
