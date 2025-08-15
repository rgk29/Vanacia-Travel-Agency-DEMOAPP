import 'package:cloud_firestore/cloud_firestore.dart';

class ReservationData {
  final String type; // 'flight', 'car', 'organized_trip', 'error'
  final Map<String, dynamic> data;
  final DateTime createdDate;
  final String collection;

  const ReservationData({
    required this.type,
    required this.data,
    required this.createdDate,
    required this.collection,
  });

  factory ReservationData.fromFirestore(
      String collection, Map<String, dynamic> data) {
    try {
      String type;
      Map<String, dynamic> safeData = {};

      switch (collection) {
        case 'organized_trips_reservations':
          type = 'organized_trip';
          safeData = _sanitizeTripData(data);
          break;

        case 'reservations':
          if (data.containsKey('departureFlight')) {
            type = 'flight';
            safeData = _sanitizeFlightData(data);
          } else if (data.containsKey('carDetails')) {
            type = 'car';
            safeData = _sanitizeCarData(data);
          } else {
            type = 'unknown';
            safeData = data;
          }
          break;

        default:
          type = 'unknown';
          safeData = data;
      }

      return ReservationData(
        type: type,
        data: safeData,
        createdDate: _parseTimestamp(data),
        collection: collection,
      );
    } catch (e, stack) {
      print('Erreur de parsing ($collection): $e\n$stack');
      return ReservationData(
        type: 'error',
        data: {'raw_data': data, 'error': e.toString()},
        createdDate: DateTime.now(),
        collection: collection,
      );
    }
  }

  static Map<String, dynamic> _sanitizeFlightData(Map<String, dynamic> data) {
    return {
      'departureFlight': data['departureFlight'] ?? {},
      'seatNumber': data['seatNumber'] ?? 'N/A',
      'totalPrice': data['totalPrice']?.toDouble() ?? 0.0,
      'currency': data['currency'] ?? 'DA',
      'userDetails': data['userDetails'] ?? {},
    };
  }

  static Map<String, dynamic> _sanitizeCarData(Map<String, dynamic> data) {
    final carDetails = data['carDetails'] as Map<String, dynamic>? ?? {};
    return {
      'carDetails': {
        'name': carDetails['name'] ?? 'Voiture inconnue',
        'type': carDetails['type'] ?? 'Type inconnu',
        'pickupDate':
            carDetails['pickupDate'] ?? DateTime.now().toIso8601String(),
        'returnDate':
            carDetails['returnDate'] ?? DateTime.now().toIso8601String(),
        'pricePerDay': carDetails['pricePerDay']?.toDouble() ?? 0.0,
        'rentalAgency': carDetails['rentalAgency'] ?? 'Agence inconnue',
        'transmission': carDetails['transmission'] ?? 'N/A',
        'imageUrl': carDetails['imageUrl'] ?? '',
      },
      'userDetails': data['userDetails'] ?? {},
    };
  }

  static Map<String, dynamic> _sanitizeTripData(Map<String, dynamic> data) {
    return {
      'destination': data['destination'] ?? 'Destination inconnue',
      'durationDays': data['durationDays'] ?? 0,
      'hotelName': data['hotelName'] ?? 'Hôtel inconnu',
      'hotelStars': data['hotelStars'] ?? 0,
      'roomType': data['roomType'] ?? 'Standard',
      'departureDate': data['departureDate'] ?? Timestamp.now(),
      'returnDate': data['returnDate'] ?? Timestamp.now(),
      'totalPrice': data['totalPrice']?.toDouble() ?? 0.0,
      'currency': data['currency'] ?? 'DA',
      'userDetails': data['userDetails'] ?? {},
    };
  }

  static DateTime _parseTimestamp(Map<String, dynamic> data) {
    try {
      final timestamp = data['timestamp'];
      if (timestamp is Timestamp) return timestamp.toDate();
      if (timestamp is DateTime) return timestamp;
      return DateTime.now();
    } catch (e) {
      print('Erreur de conversion du timestamp: $e');
      return DateTime.now();
    }
  }
}
