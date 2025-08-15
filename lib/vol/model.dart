import 'package:agencedevoyage/vol/baggage.dart';

class User {
  final String id;
  final String fullName;
  final String email;
  final String country;
  final String? passport;
  final String? address;
  final List<Booking> bookings;
  final String preferredCurrency;
  final String? gender; // Nouveau champ
  final String? phone; // Nouveau champ
  final List<LuggageOption> luggage; // Ajout du champ manquant

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.country,
    required this.passport,
    this.address,
    this.bookings = const [],
    this.luggage = const [], // Initialisation
    this.preferredCurrency = 'DZD',
    required this.gender, // Paramètre requis
    required this.phone, // Paramètre requis
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'country': country,
        'passport': passport,
        'address': address,
        'bookings': bookings.map((b) => b.toJson()).toList(),
        'preferredCurrency': preferredCurrency,
        'gender': gender, // Ajout dans le JSON
        'phone': phone, // Ajout dans le JSON
      };

  User copyWith({
    String? id,
    String? fullName,
    String? country,
    String? email,
    String? passport,
    String? address,
    List<Booking>? bookings,
    List<LuggageOption>? luggage,
    String? preferredCurrency,
    String? gender, // Type corrigé
    String? phone, // Nouveau paramètre
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      country: country ?? this.country,
      passport: passport ?? this.passport,
      address: address ?? this.address,
      bookings: bookings ?? this.bookings,
      luggage: luggage ?? this.luggage,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
    );
  }

  factory User.initial() => User(
        id: 'default',
        fullName: 'Invité',
        email: '',
        country: '',
        passport: '',
        address: '',
        bookings: [],
        preferredCurrency: 'DZD',
        gender: '',
        phone: '',
      );

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        fullName: json['fullName'] ?? 'Invité',
        email: json['email'],
        country: json['country'],
        passport: json['passport'],
        address: json['address'] ?? '',
        bookings: (json['bookings'] as List? ?? [])
            .map((b) => Booking.fromJson(b))
            .toList(),
        gender: json['gender'] ?? '', // Récupération depuis JSON
        phone: json['phone'] ?? '', // Récupération depuis JSON

        luggage: (json['luggage'] as List? ?? []) // Correction de l'accès
            .map((l) => LuggageOption.fromJson(l))
            .toList(),
      );

  /// Ce getter remplace le champ `isAuthenticated`
  bool get isAuthenticated => id != 'default';
}

class Booking {
  final String id;
  final String userId;
  final Flight departureFlight;
  final Flight? returnFlight;
  final PassengerCount passengers;
  final DateTime bookingDate;
  final String tripType;

  Booking(
      {required this.id,
      required this.userId,
      required this.departureFlight,
      this.returnFlight,
      required this.passengers,
      required this.bookingDate,
      required this.tripType});

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'departureFlight': departureFlight.toJson(),
        'returnFlight': returnFlight?.toJson(),
        'passengers': passengers.toJson(),
        'bookingDate': bookingDate.toIso8601String(),
        'tripType': tripType,
      };

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] ?? '',
        userId: json['userId'],
        departureFlight: Flight.fromJson(json['departureFlight']),
        returnFlight: json['returnFlight'] != null
            ? Flight.fromJson(json['returnFlight'])
            : null,
        passengers: PassengerCount.fromJson(json['passengers']),
        bookingDate: DateTime.parse(json['bookingDate']),
        tripType: json['tripType'],
      );
  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      departureFlight: Flight.fromMap(map['departureFlight']),
      returnFlight: map['returnFlight'] != null
          ? Flight.fromMap(map['returnFlight'])
          : null,
      passengers: PassengerCount.fromMap(map['passengers']),
      bookingDate: DateTime.parse(map['bookingDate']),
      tripType: map['tripType'] ?? '',
    );
  }
}

class PassengerCount {
  final int adults;
  final int teens;
  final int children;

  PassengerCount({
    required this.adults,
    required this.teens,
    required this.children,
  });

  Map<String, dynamic> toJson() => {
        'adults': adults,
        'teens': teens,
        'children': children,
      };

  factory PassengerCount.fromJson(Map<String, dynamic> json) => PassengerCount(
        adults: json['adults'],
        teens: json['teens'],
        children: json['children'],
      );
  factory PassengerCount.fromMap(Map<String, dynamic> map) => PassengerCount(
        adults: map['adults'],
        teens: map['teens'],
        children: map['children'],
      );
}

class Airport {
  final String code;
  final String name;
  final String city;
  final List<String> keywords;

  Airport({
    required this.code,
    required this.name,
    required this.city,
    required this.keywords,
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'city': city,
        'keywords': keywords,
      };

  Map<String, dynamic> toMap() => {
        'code': code,
        'name': name,
        'city': city,
        'keywords': keywords,
      };

  factory Airport.fromMap(Map<String, dynamic> map) => Airport(
        code: map['code'] as String,
        name: map['name'] as String,
        city: map['city'] as String,
        keywords: List<String>.from(map['keywords'] ?? []),
      );
}

class Flight {
  final String id;
  final String company;
  final Airport departure;
  final Airport arrival;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final String classe;
  final double priceDZD;
  final List<String> stops;
  final String logoAsset;
  final String reservationType;
  final List<Seat>? seats;

  Flight({
    required this.id,
    required this.company,
    required this.departure,
    required this.arrival,
    required this.departureTime,
    required this.arrivalTime,
    required this.classe,
    required this.priceDZD,
    required this.stops,
    required this.logoAsset,
    required this.reservationType,
    this.seats,
  });

  // Convertit l'objet en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company': company,
      'departure': departure.toMap(), // Nécessite Airport.toMap()
      'arrival': arrival.toMap(),
      'departureTime': departureTime.toIso8601String(),
      'arrivalTime': arrivalTime.toIso8601String(),
      'classe': classe,
      'priceDZD': priceDZD,
      'stops': stops,
      'logoAsset': logoAsset,
      'reservationType': reservationType,
      'seats': seats?.map((s) => s.toMap()).toList(),
    };
  }

  // Crée un Flight depuis une Map (Firestore)
  factory Flight.fromMap(Map<String, dynamic> map) {
    return Flight(
      id: map['id'] as String,
      company: map['company'] as String,
      departure: Airport.fromMap(map['departure'] as Map<String, dynamic>),
      arrival: Airport.fromMap(map['arrival'] as Map<String, dynamic>),
      departureTime: DateTime.parse(map['departureTime'] as String),
      arrivalTime: DateTime.parse(map['arrivalTime'] as String),
      classe: map['classe'] as String,
      priceDZD: (map['priceDZD'] as num).toDouble(),
      stops: List<String>.from(map['stops'] as List),
      logoAsset: map['logoAsset'] as String,
      reservationType: map['reservationType'] as String? ?? 'flight',
      seats: map['seats'] != null
          ? (map['seats'] as List).map((s) => Seat.fromMap(s)).toList()
          : null,
    );
  }

  // Pour la compatibilité JSON (optionnel)
  Map<String, dynamic> toJson() => toMap();
  factory Flight.fromJson(Map<String, dynamic> json) => Flight.fromMap(json);
}

class Seat {
  final int number;
  final bool isOccupied;
  bool isSelected;

  Seat({
    required this.number,
    this.isOccupied = false,
    this.isSelected = false,
  });
  Map<String, dynamic> toMap() => {
        'number': number,
        'isOccupied': isOccupied,
        'isSelected': isSelected,
      };
  factory Seat.fromMap(Map<String, dynamic> map) => Seat(
        number: map['number'],
        isOccupied: map['isOccupied'],
        isSelected: map['isSelected'],
      );

  Map<String, dynamic> toJson() => {
        'number': number,
        'isOccupied': isOccupied,
        'isSelected': isSelected,
      };

  factory Seat.fromJson(Map<String, dynamic> json) => Seat(
        number: json['number'],
        isOccupied: json['isOccupied'],
        isSelected: json['isSelected'],
      );
}
// ✅ Classe Seat
