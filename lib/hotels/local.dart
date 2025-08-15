import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

enum Facilities {
  wifi,
  tv,
  parking,
  pool,
  restaurant,
  spa,
  airportShuttle,
  nonSmokingRooms,
  frontDesk24h,
  heating,
  housekeeping,
  luggageStorage,
  airConditioning,
  roomService,
  familyRooms,
  breakfast,
  kitchen,
  garden,
  petsAllowed
}

enum RoomType { single, double, triple, family, suite }

enum PropertyType { hotel, apartment, vacationHome, villa }

class Hotells {
  final String id;
  final String name;
  final int stars;
  final double pricePerNight;
  final PropertyType propertyType;
  final Address address;
  final List<String> imageUrls;
  final String thumbnailUrl;
  final String description;
  final List<RoomType> availableRooms;
  final Map<String, List<String>> nearbyPoints;
  final List<Facilities> facilities;
  final Map<String, String> hotelRules;
  final List<String> paymentMethods;
  final DateTime arrivalDate;
  final DateTime departureDate;
  final int durationDays;
  final List<String> keywords;
  final bool hasPromotion;
  final double? originalPrice; // Prix avant promotion
  final int? discountPercentage; // Pourcentage de réduction

  Hotells({
    required this.id,
    required this.name,
    required this.stars,
    required this.pricePerNight,
    required this.propertyType,
    required this.address,
    required this.imageUrls,
    required this.thumbnailUrl,
    required this.description,
    required this.availableRooms,
    required this.nearbyPoints,
    required this.facilities,
    required this.hotelRules,
    required this.paymentMethods,
    required this.arrivalDate,
    required this.departureDate,
    required this.durationDays,
    required this.keywords,
    this.hasPromotion = false,
    this.originalPrice,
    this.discountPercentage,
  }) : assert(
            !hasPromotion ||
                (originalPrice != null && discountPercentage != null),
            'Les promotions nécessitent originalPrice et discountPercentage');
  double get discountedPrice {
    if (hasPromotion) {
      return originalPrice! * (1 - discountPercentage! / 100);
    }
    return pricePerNight;
  }

  double calculateTotal(int stayDuration) => pricePerNight * stayDuration;

  String get discountLabel => hasPromotion ? '-$discountPercentage%' : '';

  factory Hotells.fromMap(Map<String, dynamic> map) {
    return Hotells(
      id: map['id'] as String,
      name: map['name'] as String,
      stars: map['stars'] as int,
      pricePerNight: (map['pricePerNight'] as num).toDouble(),
      propertyType: _parsePropertyType(map['propertyType']),
      address: Address.fromMap(map['address']),
      imageUrls: List<String>.from(map['imageUrls']),
      thumbnailUrl: map['thumbnailUrl'] as String,
      description: map['description'] as String,
      availableRooms: _parseRoomTypes(map['availableRooms']),
      nearbyPoints: Map<String, List<String>>.from(map['nearbyPoints']),
      facilities: _parseFacilities(map['facilities']),
      hotelRules: Map<String, String>.from(map['hotelRules']),
      paymentMethods: List<String>.from(map['paymentMethods']),
      arrivalDate: DateTime.parse(map['arrivalDate']),
      departureDate: DateTime.parse(map['departureDate']),
      durationDays: map['durationDays'] as int,
      keywords: List<String>.from(map['keywords']),
      hasPromotion: map['hasPromotion'] ?? false,
      originalPrice: (map['originalPrice'] as num?)?.toDouble(),
      discountPercentage: map['discountPercentage'] as int?,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'stars': stars,
      'pricePerNight': pricePerNight,
      'propertyType': propertyType.toString().split('.').last,
      'address': address.toMap(),
      'imageUrls': imageUrls,
      'thumbnailUrl': thumbnailUrl,
      'description': description,
      'availableRooms':
          availableRooms.map((e) => e.toString().split('.').last).toList(),
      'nearbyPoints': nearbyPoints,
      'facilities':
          facilities.map((e) => e.toString().split('.').last).toList(),
      'hotelRules': hotelRules,
      'paymentMethods': paymentMethods,
      'arrivalDate': arrivalDate.toIso8601String(),
      'departureDate': departureDate.toIso8601String(),
      'durationDays': durationDays,
      'keywords': keywords,
      'hasPromotion': hasPromotion,
      'originalPrice': originalPrice,
      'discountPercentage': discountPercentage,
    };
  }

  static PropertyType _parsePropertyType(String type) {
    return PropertyType.values.firstWhere(
      (e) => e.toString().split('.').last == type,
      orElse: () => PropertyType.hotel,
    );
  }

  static List<RoomType> _parseRoomTypes(List<dynamic> types) {
    return types
        .map((type) => RoomType.values.firstWhere(
              (e) => e.toString().split('.').last == type,
            ))
        .toList();
  }

  static List<Facilities> _parseFacilities(List<dynamic> facilities) {
    return facilities
        .map((fac) => Facilities.values.firstWhere(
              (e) => e.toString().split('.').last == fac,
            ))
        .toList();
  }
}

class Review {
  final String id;
  final String userId;
  final String userName;
  final String text;
  final double rating;
  final DateTime date;
  final List<String> likedBy;
  final List<String> dislikedBy;

  Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    required this.rating,
    required this.date,
    this.likedBy = const [],
    this.dislikedBy = const [],
  }) {
    assert(rating >= 1 && rating <= 5, 'Rating must be between 1 and 5');
    assert(text.length <= 500, 'Review text too long');
  }

  factory Review.fromMap(Map<String, dynamic> map) {
    try {
      // Gestion du champ date qui peut être Timestamp ou String
      DateTime date;
      if (map['date'] is Timestamp) {
        date = (map['date'] as Timestamp).toDate();
      } else if (map['date'] is String) {
        date = DateTime.parse(map['date'] as String);
      } else {
        date = DateTime.now();
      }

      final likedBy = map['likedBy'] != null
          ? List<String>.from(map['likedBy'])
          : <String>[];

      final dislikedBy = map['dislikedBy'] != null
          ? List<String>.from(map['dislikedBy'])
          : <String>[];

      return Review(
        id: map['id'] as String? ?? '',
        userId: map['userId'] as String? ?? '',
        userName: map['userName'] as String? ?? '',
        text: map['text'] as String? ?? '',
        rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
        date: date,
        likedBy: likedBy,
        dislikedBy: dislikedBy,
      );
    } catch (e) {
      print('Error parsing Review: $e');
      print('Map data: $map');
      rethrow;
    }
  }

  // factory Review.fromMap(Map<String, dynamic> map) {
  //   return Review(
  //     id: map['id'],
  //     userId: map['userId'],
  //     userName: map['userName'],
  //     text: map['text'],
  //     rating: (map['rating'] as num).toDouble(),
  //     date: DateTime.parse(map['date']),
  //     likedBy: List<String>.from(map['likedBy'] ?? []),
  //     dislikedBy: List<String>.from(map['dislikedBy'] ?? []),
  //   );
  // }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'text': text,
      'rating': rating,
      'date': date.toIso8601String(),
      'likedBy': likedBy,
      'dislikedBy': dislikedBy,
    };
  }
}

class Locationn {
  final double lat;
  final double lng;

  Locationn({required this.lat, required this.lng});
  LatLng toLatLng() => LatLng(lat, lng); // Conversion explicite
  factory Locationn.fromMap(Map<String, dynamic> map) {
    return Locationn(
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
    );
  }
}

class Address {
  final String street;
  final String city;
  final String province; // ex: Paris
  final String country; // ex: France
  final Locationn location; // Utilisation ici

  Address({
    required this.street,
    required this.city,
    required this.province,
    required this.country,
    required this.location,
  });
  String get fullAddress => '$street, $city, $province, $country';
  Map<String, dynamic> toMap() {
    return {
      'street': street,
      'city': city,
      'province': province,
      'country': country,
      'location': {'lat': location.lat, 'lng': location.lng}
    };
  }

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      street: map['street'] as String,
      city: map['city'] as String,
      province: map['province'] as String,
      country: map['country'] as String,
      location: Locationn.fromMap(map['location']),
    );
  }
}

class HotelReservation {
  final String? id; // Nouveau champ pour stocker l'ID Firestore

  final String userId;
  final String hotelId;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int teens;
  final String roomType;
  final String paymentMethod;
  final String status;
  final double totalPrice;
  final DateTime createdAt;
  final String userEmail; // Ajouté
  final Map<String, dynamic>? paymentDetails; // Ajouté
  final Map<String, dynamic> hotelDetails;

  HotelReservation({
    this.id,
    required this.userId,
    required this.hotelId,
    required this.checkInDate,
    required this.checkOutDate,
    required this.teens,
    required this.roomType,
    required this.paymentMethod,
    required this.status,
    required this.totalPrice,
    required this.createdAt,
    required this.userEmail, // Ajouté au constructeur
    this.paymentDetails, // Ajouté au constructeur (optionnel)
    required this.hotelDetails,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'hotelId': hotelId,
      'checkInDate': checkInDate,
      'checkOutDate': checkOutDate,
      'teens': teens,
      'roomType': roomType,
      'paymentMethod': paymentMethod,
      'status': status,
      'totalPrice': totalPrice,
      'createdAt': createdAt.toIso8601String(),
      'userEmail': userEmail, // Maintenant défini
      'paymentDetails': paymentDetails, // Maintenant défini
      // ... autres champs
      'hotelDetails': hotelDetails,
    };
  }

  factory HotelReservation.fromMap(Map<String, dynamic> map) {
    // Conversion sécurisée des dates
    DateTime parseDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.parse(date);
      throw FormatException('Format de date invalide: $date');
    }

    return HotelReservation(
      id: map['id'] as String?,
      userId: map['userId'] as String,
      hotelId: map['hotelId'] as String,
      checkInDate: parseDate(map['checkInDate']),
      checkOutDate: parseDate(map['checkOutDate']),
      teens: map['teens'] as int,
      roomType: map['roomType'] as String,
      paymentMethod: map['paymentMethod'] as String,
      status: map['status'] as String,
      totalPrice: (map['totalPrice'] as num).toDouble(),
      createdAt: DateTime.parse(map['createdAt'] as String),
      userEmail: map['userEmail'] as String, // Récupération depuis la map
      paymentDetails: map['paymentDetails'] as Map<String, dynamic>?,
      hotelDetails: map['hotelDetails']
          as Map<String, dynamic>, // Récupération optionnelle
    );
  }

  HotelReservation copyWith({
    String? userId,
    String? hotelId,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    int? teens,
    String? roomType,
    String? paymentMethod,
    String? status,
    double? totalPrice,
    DateTime? createdAt,
    String? userEmail,
    Map<String, dynamic>? paymentDetails,
    String? id,
    Map<String, dynamic>? hotelDetails,
  }) {
    return HotelReservation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      hotelId: hotelId ?? this.hotelId,
      checkInDate: checkInDate ?? this.checkInDate,
      checkOutDate: checkOutDate ?? this.checkOutDate,
      teens: teens ?? this.teens,
      roomType: roomType ?? this.roomType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      totalPrice: totalPrice ?? this.totalPrice,
      createdAt: createdAt ?? this.createdAt,
      userEmail: userEmail ?? this.userEmail, // Ajouté
      paymentDetails: paymentDetails ?? this.paymentDetails, // Ajouté
      hotelDetails: hotelDetails ?? this.hotelDetails,
    ); // Ajoutez cette ligne );
  }
}

class PaymentMethod {
  final String cardType; // ex: "Visa", "MasterCard", "CIB"
  final String cardNumber; // dernieres 4 chiffres ou tout si stocké crypté
  final String expiryDate;

  PaymentMethod({
    required this.cardType,
    required this.cardNumber,
    required this.expiryDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'card_type': cardType,
      'card_number': cardNumber,
      'expiry_date': expiryDate,
    };
  }

  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      cardType: map['card_type'] ?? '',
      cardNumber: map['card_number'] ?? '',
      expiryDate: map['expiry_date'] ?? '',
    );
  }
}
