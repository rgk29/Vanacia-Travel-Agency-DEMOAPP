import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CarModel {
  final String name;
  final String type;
  final String transmission;
  final int doors;
  final bool hasAC;
  final String cancellationPolicy;
  final double pricePerDay;
  final String pickupLocation;
  final String returnLocation;
  final DateTime pickupDate;
  final DateTime returnDate;
  final TimeOfDay pickupTime;
  final String rentalAgency;
  final String terms;
  final double securityDeposit;
  final String imageUrl;
  int get rentalDays => returnDate.difference(pickupDate).inDays;
  final String reservationType; // Nouveau champ

  CarModel({
    required this.name,
    required this.type,
    required this.transmission,
    required this.doors,
    required this.hasAC,
    required this.cancellationPolicy,
    required this.pricePerDay,
    required this.pickupLocation,
    required this.returnLocation,
    required this.pickupDate,
    required this.returnDate,
    required this.pickupTime,
    required this.rentalAgency,
    required this.terms,
    required this.securityDeposit,
    required this.imageUrl,
    required this.reservationType, // Ajouter ce paramètre
  });

  String get formattedPickupTime =>
      "${pickupTime.hour.toString().padLeft(2, '0')}:${pickupTime.minute.toString().padLeft(2, '0')}";

  String get formattedPickupDate => DateFormat('dd/MM/yyyy').format(pickupDate);
  String get formattedReturnDate => DateFormat('dd/MM/yyyy').format(returnDate);
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'transmission': transmission,
      'doors': doors,
      'hasAC': hasAC,
      'cancellationPolicy': cancellationPolicy,
      'pricePerDay': pricePerDay,
      'pickupLocation': pickupLocation,
      'returnLocation': returnLocation,
      'pickupDate': pickupDate.toIso8601String(),
      'returnDate': returnDate.toIso8601String(),
      'pickupTime': '${pickupTime.hour}:${pickupTime.minute}',
      'rentalAgency': rentalAgency,
      'terms': terms,
      'securityDeposit': securityDeposit,
      'imageUrl': imageUrl,
      'reservationType': reservationType, // Ajouter ce champ
    };
  }

  factory CarModel.fromMap(Map<String, dynamic> map) {
    // Gestion des dates
    final pickupDate = map['pickupDate'] is Timestamp
        ? (map['pickupDate'] as Timestamp).toDate()
        : DateTime.tryParse(map['pickupDate']?.toString() ?? '') ??
            DateTime.now();

    final returnDate = map['returnDate'] is Timestamp
        ? (map['returnDate'] as Timestamp).toDate()
        : DateTime.tryParse(map['returnDate']?.toString() ?? '') ??
            pickupDate.add(const Duration(days: 1));

    // Gestion du temps
    TimeOfDay parseTime(dynamic timeData) {
      if (timeData is TimeOfDay) return timeData;
      final timeString = timeData?.toString() ?? '00:00';
      final parts = timeString.split(':');
      return TimeOfDay(
        hour: int.tryParse(parts.first) ?? 0,
        minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
      );
    }

    return CarModel(
      name: map['name']?.toString() ??
          map['carDetails']?['name']?.toString() ??
          'sans nom', // Ajout de cette ligne

      type: map['type']?.toString() ?? 'Standard',
      transmission: map['transmission']?.toString() ?? 'Manuelle',
      doors: (map['doors'] as num?)?.toInt() ?? 4,
      hasAC: map['hasAC'] as bool? ?? false,
      cancellationPolicy: map['cancellationPolicy']?.toString() ?? 'Flexible',
      pricePerDay: (map['pricePerDay'] as num?)?.toDouble() ?? 0.0,
      pickupLocation: map['pickupLocation']?.toString() ?? 'Non spécifié',
      returnLocation: map['returnLocation']?.toString() ??
          map['pickupLocation']?.toString() ??
          'Non spécifié',
      pickupDate: pickupDate,
      returnDate: returnDate,
      pickupTime: parseTime(map['pickupTime']),
      rentalAgency: map['rentalAgency']?.toString() ?? 'Agence inconnue',
      terms: map['terms']?.toString() ?? '',
      securityDeposit: (map['securityDeposit'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['imageUrl']?.toString() ?? 'assets/default_car.png',
      reservationType: map['reservationType'] ?? 'car', // Valeur par défaut
    );
  }

  // ... initialiser toutes les propriétés
}

class CarSearchDetails {
  final String pickupAirport;
  final String returnAirport;
  final DateTime pickupDate;
  final DateTime returnDate;
  final TimeOfDay pickupTime;
  final int numberOfAdults;

  CarSearchDetails({
    required this.pickupAirport,
    required this.returnAirport,
    required this.pickupDate,
    required this.returnDate,
    required this.pickupTime,
    required this.numberOfAdults,
  });

  String get formattedPickupDate => DateFormat('dd/MM/yyyy').format(pickupDate);
  String get formattedReturnDate => DateFormat('dd/MM/yyyy').format(returnDate);
  String get formattedPickupTime =>
      "${pickupTime.hour.toString().padLeft(2, '0')}:${pickupTime.minute.toString().padLeft(2, '0')}";
}

class AirportModel {
  final String name;
  final String code;
  final String city;
  final String country;
  final List<String> keywords;

  AirportModel({
    required this.name,
    required this.code,
    required this.city,
    required this.country,
    required this.keywords,
  });
}

// Ajoutez cette classe pour gérer les filtres
class CarFilters {
  double minPrice;
  double maxPrice;
  double minDeposit;
  double maxDeposit;
  Set<String> selectedTypes;
  Set<int> selectedDoors;
  Set<String> selectedTransmissions;
  Set<String> selectedAgencies;
  bool? hasAC;

  CarFilters({
    required this.minPrice,
    required this.maxPrice,
    required this.minDeposit,
    required this.maxDeposit,
    required this.selectedTypes,
    required this.selectedDoors,
    required this.selectedTransmissions,
    required this.selectedAgencies,
    this.hasAC,
  });
  // Ajout de la méthode copyWith
  CarFilters copyWith({
    double? minPrice,
    double? maxPrice,
    double? minDeposit,
    double? maxDeposit,
    Set<String>? selectedTypes,
    Set<int>? selectedDoors,
    Set<String>? selectedTransmissions,
    Set<String>? selectedAgencies,
    bool? hasAC,
  }) {
    return CarFilters(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minDeposit: minDeposit ?? this.minDeposit,
      maxDeposit: maxDeposit ?? this.maxDeposit,
      selectedTypes: selectedTypes ?? this.selectedTypes,
      selectedDoors: selectedDoors ?? this.selectedDoors,
      selectedTransmissions:
          selectedTransmissions ?? this.selectedTransmissions,
      selectedAgencies: selectedAgencies ?? this.selectedAgencies,
      hasAC: hasAC ?? this.hasAC,
    );
  }
}

List<AirportModel> airportList = [
  AirportModel(
    name: "Aéroport de Barcelone El Prat",
    code: "BCN",
    city: "Barcelone",
    country: "Espagne",
    keywords: ["Barcelone", "BCN", "El Prat", "Espagne", "Aéroport Barcelone"],
  ),
  AirportModel(
    name: "Aéroport d'Alger Houari Boumédiène",
    code: "ALG",
    city: "Alger",
    country: "Algérie",
    keywords: [
      "Alger",
      "ALG",
      "Houari Boumédiène",
      "Algérie",
      "Aéroport Alger"
    ],
  ),
];

final carSearchDetails = CarSearchDetails(
  pickupAirport: "Aéroport de Barcelone El Prat",
  returnAirport: "Aéroport de Barcelone El Prat",
  pickupDate: DateTime(2025, 8, 15),
  returnDate: DateTime(2025, 8, 22),
  pickupTime: TimeOfDay(hour: 10, minute: 0),
  numberOfAdults: 1,
);

List<CarModel> carList = [
  CarModel(
      name: "Audi A1",
      type: "SUV intermédiaire",
      transmission: "Automatique",
      doors: 5,
      hasAC: true,
      cancellationPolicy:
          "Annulation gratuite jusqu’à 6h avant la prise en charge",
      pricePerDay: 4000,
      pickupDate: DateTime(2025, 8, 15),
      returnDate: DateTime(2025, 8, 22),
      pickupTime: TimeOfDay(hour: 10, minute: 0),
      rentalAgency: "Budget",
      terms:
          "Politique d’annulation et de non-présentation : remboursement 100% si annulé 6h avant.",
      securityDeposit: 1800,
      imageUrl: "assets/voiture/audiA1.jpg",
      pickupLocation: ' Aéroport de Barcelone El Prat',
      returnLocation: 'Aéroport de Barcelone El Prat',
      reservationType: 'car'),
  CarModel(
      name: "Renault Clio ",
      type: "Citadine",
      transmission: "Manuelle",
      doors: 5,
      hasAC: true,
      cancellationPolicy:
          "Annulation gratuite jusqu’à 6h avant la prise en charge",
      pricePerDay: 3500,
      pickupLocation: "Aéroport de Barcelone El Prat",
      returnLocation: "Aéroport de Barcelone El Prat",
      pickupDate: DateTime(2025, 8, 15),
      returnDate: DateTime(2025, 8, 22),
      pickupTime: TimeOfDay(hour: 10, minute: 0),
      rentalAgency: "Hertz",
      terms:
          "Politique d’annulation et de non-présentation : remboursement 100% si annulé 6h avant.",
      securityDeposit: 1000,
      imageUrl: "assets/voiture/clio.jpg",
      reservationType: 'car'),
  CarModel(
      name: "BMW ",
      type: "Compacte",
      transmission: "Automatique",
      doors: 5,
      hasAC: true,
      cancellationPolicy:
          "Annulation gratuite jusqu’à 6h avant la prise en charge",
      pricePerDay: 5000,
      pickupLocation: "Aéroport de Barcelone El Prat",
      returnLocation: "Aéroport de Barcelone El Prat",
      pickupDate: DateTime(2025, 8, 15),
      returnDate: DateTime(2025, 8, 22),
      pickupTime: TimeOfDay(hour: 10, minute: 0),
      rentalAgency: "Sixt",
      terms: "Politique d’annulation flexible avec remboursement intégral.",
      securityDeposit: 2000,
      imageUrl: "assets/voiture/BMW.jpg",
      reservationType: 'car'),
  CarModel(
      name: "Ford",
      type: "SUV",
      transmission: "Manuelle",
      doors: 5,
      hasAC: true,
      cancellationPolicy:
          "Annulation gratuite jusqu’à 24h avant la prise en charge",
      pricePerDay: 4500,
      pickupLocation: "Aéroport de Barcelone El Prat",
      returnLocation: "Aéroport de Barcelone El Prat",
      pickupDate: DateTime(2025, 8, 15),
      returnDate: DateTime(2025, 8, 22),
      pickupTime: TimeOfDay(hour: 10, minute: 0),
      rentalAgency: "Avis",
      terms: "Des frais d’annulation peuvent s’appliquer après 24h.",
      securityDeposit: 1500,
      imageUrl: "assets/voiture/ford.jpg",
      reservationType: 'car'),
  CarModel(
      name: "Mercedes Classe A 2015",
      type: "Premium",
      transmission: "Automatique",
      doors: 5,
      hasAC: true,
      cancellationPolicy:
          "Annulation gratuite jusqu’à 12h avant la prise en charge",
      pricePerDay: 6000,
      pickupLocation: "Aéroport de Barcelone El Prat",
      returnLocation: "Aéroport de Barcelone El Prat",
      pickupDate: DateTime(2025, 8, 15),
      returnDate: DateTime(2025, 8, 22),
      pickupTime: TimeOfDay(hour: 10, minute: 0),
      rentalAgency: "Europcar",
      terms: "Remboursement total si annulé avant 12h.",
      securityDeposit: 2000,
      imageUrl: "assets/voiture/mercedes2015.jpg",
      reservationType: 'car'),
  CarModel(
      name: "Fiat 500 ",
      type: "Mini",
      transmission: "Manuelle",
      doors: 3,
      hasAC: true,
      cancellationPolicy:
          "Annulation gratuite jusqu’à 6h avant la prise en charge",
      pricePerDay: 3000,
      pickupLocation: "Aéroport de Barcelone El Prat",
      returnLocation: "Aéroport de Barcelone El Prat",
      pickupDate: DateTime(2025, 8, 15),
      returnDate: DateTime(2025, 8, 22),
      pickupTime: TimeOfDay(hour: 10, minute: 0),
      rentalAgency: "Goldcar",
      terms: "Remboursement total jusqu’à 6h avant la prise en charge.",
      securityDeposit: 1000,
      imageUrl: "assets/voiture/fiat500.jpg",
      reservationType: 'car'),
];
