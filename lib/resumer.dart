import 'package:agencedevoyage/currency_provider.dart';
import 'package:agencedevoyage/homepage.dart';
import 'package:agencedevoyage/hotels/data.dart';
import 'package:agencedevoyage/hotels/local.dart';
import 'package:agencedevoyage/voiture/local.dart';
import 'package:agencedevoyage/vol/model.dart';
import 'package:agencedevoyage/voyageOrganiser/trip.dart';
import 'package:agencedevoyage/voyageOrganiser/trip_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

class MesReservationsPage extends ConsumerWidget {
  const MesReservationsPage({super.key});

  Stream<List<QueryDocumentSnapshot>> _getCombinedReservations(String userId) {
    final carStream = FirebaseFirestore.instance
        .collection('reservations')
        .where('userId', isEqualTo: userId)
        .snapshots();

    final flightStream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('flight_reservations')
        .snapshots();

    final tripStream = FirebaseFirestore.instance
        .collection('organized_trips_reservations')
        .where('userId', isEqualTo: userId)
        .snapshots();

    final hotelStream = FirebaseFirestore.instance
        .collection('hotel_reservations')
        .where('userId', isEqualTo: userId)
        .snapshots();

    return Rx.combineLatest4(
      carStream,
      flightStream,
      tripStream,
      hotelStream,
      (QuerySnapshot cars, QuerySnapshot flights, QuerySnapshot trips,
          QuerySnapshot hotels) {
        final all = [
          ...cars.docs,
          ...flights.docs,
          ...trips.docs,
          ...hotels.docs
        ];
        all.sort((a, b) => _getTimestamp(b).compareTo(_getTimestamp(a)));
        return all;
      },
    );
  }

  DateTime _getTimestamp(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final timestamp =
        data['timestamp'] ?? data['reservationDate'] ?? data['departureDate'];

    try {
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      } else if (timestamp is String) {
        return DateTime.tryParse(timestamp) ?? DateTime.now();
      }
    } catch (_) {}
    return DateTime.now();
  }

  Stream<List<Booking>> getFlightReservations(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('flight_reservations')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              // Injecte l'ID Firestore dans les données
              data['id'] = doc.id;
              return Booking.fromMap(data);
            }).toList());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final currencyNotifier = ref.watch(currencyProvider.notifier);

    if (user == null) {
      return Center(child: Text("connect_to_view_reservations".tr()));
    }

    return WillPopScope(
      onWillPop: () async {
        // Navigue vers la HomePage au lieu de revenir
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
          (route) => false,
        );
        return false; // Empêche le pop par défaut
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("my_reservations".tr()),
          elevation: 4,
        ),
        body: StreamBuilder<List<QueryDocumentSnapshot>>(
          stream: _getCombinedReservations(user.uid),
          builder: (context, snapshot) {
            if (snapshot.hasError) return _buildErrorWidget(snapshot.error);
            if (!snapshot.hasData) return _buildLoadingWidget();

            final reservations = snapshot.data!;
            if (reservations.isEmpty) return _buildEmptyState();

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reservations.length,
              itemBuilder: (context, index) {
                final doc = reservations[index];
                final data = doc.data() as Map<String, dynamic>;
                final type = _determineTypeFromPath(doc.reference.path);

                return _ReservationCard(
                  data: data,
                  type: type,
                  docRef: doc.reference,
                  onDelete: () => _confirmDelete(context, doc.reference),
                  onTap: () => _handleTap(context, type, data),
                  localHotels: localHotels,
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _determineTypeFromPath(String path) {
    if (path.contains('organized_trips_reservations')) return 'trip';
    if (path.contains('hotel_reservations')) return 'hotel';
    if (path.contains('flight_reservations')) {
      return 'flight'; // Modification clé
    }
    return 'car';
  }

  Future<void> _handleTap(
    BuildContext context,
    String type,
    Map<String, dynamic> data,
  ) async {
    try {
      switch (type) {
        case 'car':
          final carData = data['car'] ?? data;
          final car = CarModel.fromMap(carData);
          final total = (carData['totalPrice'])?.toString() ??
              car.pricePerDay * car.rentalDays;

          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => CarReservationCard(
              car: car,
              totalPrice: total as String,
              imageUrl: data['carDetails']?['imageUrl'] ?? ' ',
            ),
          );
          break;
        case 'hotel':
          final hotelId = data['hotelId'] as String?;
          if (hotelId == null) {
            throw Exception('Hotel_ID_manquant'.tr());
          }

          final hotel = localHotels.firstWhere(
            (h) => h.id == hotelId,
            orElse: () => throw Exception('Hôtel_non_trouvé'.tr()),
          );

          _showHotelDetails(context, data, hotel);
          break;

        case 'trip':
          if (data['status'] != 'confirmed') return;

          // 1. Convertir les données Firestore en Reservation
          final reservation = Reservation.fromMap(data);

          // 2. Récupérer le trip local correspondant à destination + hôtel
          final trip = getOrganizedTrips().firstWhere(
            (t) =>
                t.destination.toLowerCase().trim() ==
                    reservation.destination.toLowerCase().trim() &&
                t.hotels.any((h) =>
                    h.name.toLowerCase().trim() ==
                    reservation.hotelName.toLowerCase().trim()),
            orElse: () => Trip.placeholder(),
          );

          // 3. Récupérer l'hôtel dans ce voyage
          final hotel = trip.hotels.firstWhere(
            (h) =>
                h.name.toLowerCase().trim() ==
                reservation.hotelName.toLowerCase().trim(),
            orElse: () => Hotel(id: '', name: 'Inconnu'),
          );

          // 4. Afficher le bottom sheet
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => TripReservationCard(
              reservation: reservation,
              trip: trip,
              hotel: hotel,
            ),
          );
          break;
      }
    } catch (e) {
      _showErrorDialog(context, "Erreur : ${e.toString()}");
    }
  }
}

void _showHotelDetails(
    BuildContext context, Map<String, dynamic> data, Hotells hotel) {
  try {
    final reservation = HotelReservation.fromMap(data);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _HotelReservationDetails(
        reservation: reservation,
        hotel: hotel, // Passer l'objet Hotells complet
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur: ${e.toString()}')),
    );
  }
}

class FirestoreConverters {
  static dynamic convertTimestamps(dynamic item) {
    if (item is Timestamp) {
      return item.toDate();
    }
    if (item is Map) {
      return item.map((key, value) => MapEntry(key, convertTimestamps(value)));
    }
    if (item is List) {
      return item.map((e) => convertTimestamps(e)).toList();
    }
    return item;
  }
}

class _HotelReservationDetails extends ConsumerWidget {
  final HotelReservation reservation;
  final Hotells hotel;
  const _HotelReservationDetails({
    required this.reservation,
    required this.hotel,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyNotifier = ref.watch(currencyProvider.notifier);
    final hotelDetails = reservation.hotelDetails ?? {};

    final address = (hotelDetails['address'] as Map<String, dynamic>?) ?? {};
    final fullAddress = _getFullAddress(address);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildHotelImages(hotel.imageUrls), // Utilisez imageUrls ici
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Hôtel', hotel.name.tr()),
          _buildDetailRow('Adresse', fullAddress),
          _buildDetailRow('Type_de_chambre'.tr(),
              _getRoomTypeTranslation(reservation.roomType)),
          _buildDetailRow('Dates', _formatDateRange()),
          const Divider(),
          _buildPriceRow(currencyNotifier, reservation.totalPrice),
        ],
      ),
    );
  }

  Widget _buildHotelImages(List<String> imageUrls) {
    final validUrls = imageUrls.where((url) => url.isNotEmpty == true).toList();

    if (validUrls.isEmpty) {
      return _buildErrorImage();
    }

    return SizedBox(
      height: 200,
      child: PageView.builder(
        itemCount: validUrls.length,
        itemBuilder: (context, index) => ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            imageUrls[index],
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildErrorImage(),
          ),
        ),
      ),
    );
  }

  String _getFullAddress(Map<String, dynamic> address) {
    final street = address['street']?.toString().tr() ?? '';
    final city = address['city']?.toString() ?? '';
    final province = address['province']?.toString() ?? '';
    final country = address['country']?.toString() ?? '';

    if ([street, city, province, country].every((e) => e.isEmpty)) {
      return 'Adresse_non_disponible'.tr();
    }

    return '$street, $city\n$province, $country';
  }

  String _formatDateRange() {
    try {
      final checkIn = DateFormat('dd/MM/yyyy').format(reservation.checkInDate);
      final checkOut =
          DateFormat('dd/MM/yyyy').format(reservation.checkOutDate);
      return '$checkIn - $checkOut';
    } catch (e) {
      return 'Dates_non_disponibles';
    }
  }

  Widget _buildPriceRow(CurrencyNotifier notifier, double price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Total'.tr()),
        Text(
          notifier.formatPrice(price),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label :',
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ), // <- Virgule ajoutée ici
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

String _getRoomTypeTranslation(String roomType) {
  switch (roomType.toLowerCase().replaceAll(' ', '_')) {
    case 'triple':
      return 'room_types.triple'.tr();
    case 'double':
      return 'room_types.double'.tr();
    case 'single':
      return 'room_types.single'.tr();
    case 'suite':
      return 'room_types.suite'.tr();
    case 'familiale':
      return 'room_types.family'.tr();
    case 'non_smoking':
      return 'room_types.non_smoking'.tr();
    case 'fumeurs':
    case 'smoking':
      return 'room_types.smoking'.tr();
    default:
      return roomType; // fallback sans traduction
  }
}

Widget _buildErrorWidget(Object? error) {
  return Center(child: Text("error_occurred".tr()));
}

Widget _buildLoadingWidget() {
  return const Center(child: CircularProgressIndicator());
}

Widget _buildEmptyState() {
  return Center(
    child: Text("no_reservations_found".tr()),
  );
}

void _showErrorDialog(BuildContext context, String error) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text("erreur_technique".tr()),
      content: Text(error),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text("OK".tr()))
      ],
    ),
  );
}

class _ReservationCard extends ConsumerWidget {
  final Map<String, dynamic> data;
  final String type;
  final DocumentReference docRef;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final List<Hotells> localHotels;

  const _ReservationCard({
    required this.data,
    required this.type,
    required this.docRef,
    required this.onDelete,
    required this.onTap,
    required this.localHotels,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Écoute les changements d'état pour déclencher les rebuilds
    final currencyState = ref.watch(currencyProvider);
    // Accède au notifier pour formater les prix
    final currencyNotifier = ref.read(currencyProvider.notifier);

    final details = _getDetails(currencyNotifier, data, type);

    // Si la réservation n'est pas "confirmed", on ignore l'affichage
    if (details == null) return const SizedBox.shrink();

    final (icon, title, subtitle) = details;
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: Icon(icon, size: 32, color: Colors.blue[800]),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: onDelete,
        ),
        onTap: onTap,
      ),
    );
  }

  (IconData, String, String)? _getDetails(
    CurrencyNotifier currencyNotifier,
    Map<String, dynamic> data,
    String type,
  ) {
    try {
      switch (type) {
        case 'car':
          final carData = data['car'] ?? data;
          final car = CarModel.fromMap(carData);
          final carName = data['carDetails']?['name'] ?? 'Unknown Car';

          final pickup =
              data['carDetails']?['pickupLocation'] ?? 'Unknown Location';
          final pickupDatest = data['carDetails']?['pickupDate'];

          DateTime? pickupDate;
          if (pickupDatest != null && pickupDatest is String) {
            pickupDate = DateTime.tryParse(pickupDatest);
          }
          final rental = data['carDetails']?['rentalAgency'] ?? 'Unknown';

          return (
            Icons.directions_car,
            carName,
            '${'car_agency'.tr()}: $rental\n'
                '$pickup •\n'
                '${'car_pickup_date'.tr()} : ${pickupDate != null ? DateFormat('dd/MM/yyyy').format(pickupDate) : ''}\n'
          );

        case 'hotel':
          try {
            final checkInDateRaw = data['checkInDate'];
            final checkOutDateRaw = data['checkOutDate'];

            final checkInDate = checkInDateRaw is Timestamp
                ? checkInDateRaw.toDate()
                : DateTime.tryParse(checkInDateRaw ?? '') ?? DateTime.now();

            final checkOutDate = checkOutDateRaw is Timestamp
                ? checkOutDateRaw.toDate()
                : DateTime.tryParse(checkOutDateRaw ?? '') ?? DateTime.now();

            final hotelId = data['hotelId'] as String?;

            if (hotelId == null || hotelId.isEmpty) {
              return (Icons.error, 'Erreur hôtel', 'ID hôtel manquant');
            }

            final matchedHotel =
                localHotels.firstWhereOrNull((h) => h.id == hotelId);

            if (matchedHotel == null) {
              return (Icons.error, 'Erreur hôtel', 'Hôtel introuvable');
            }

            final address = '${matchedHotel.address.street.tr()}, '
                '${matchedHotel.address.city}, '
                '${matchedHotel.address.province}, '
                '${matchedHotel.address.country}';

            return (Icons.hotel, matchedHotel.name.tr(), address);
          } catch (e) {
            return (
              Icons.error,
              'Erreur hôtel',
              'Erreur lors de la récupération'
            );
          }
        case 'flight':
          final departureFlight =
              data['departureFlight'] as Map<String, dynamic>?;
          final returnFlight = data['returnFlight'] as Map<String, dynamic>?;

          String formatFlight(Map<String, dynamic>? flight) {
            if (flight == null) return '';

            final buffer = StringBuffer();

            final departure = flight['departure']?['city'];
            final arrival = flight['arrival']?['city'];
            if (departure != null && arrival != null) {
              buffer.writeln('$departure → $arrival');
            }

            final dateRaw = flight['departureTime'];
            DateTime? flightDate;
            if (dateRaw is Timestamp) {
              flightDate = dateRaw.toDate();
            } else if (dateRaw is String) {
              flightDate = DateTime.tryParse(dateRaw);
            }
            if (flightDate != null) {
              buffer.writeln(
                  '${'flight_date'.tr()} : ${DateFormat('dd/MM/yyyy – HH:mm').format(flightDate)}');
            }

            final company = flight['company'];
            if (company != null) {
              buffer.writeln('${'flight_company'.tr()} : $company');
            }

            final classe = flight['classe'];
            if (classe != null) {
              buffer.writeln('${'flight_class'.tr()} : $classe');
            }

            final stops = flight['stops'] as List<dynamic>?;
            if (stops != null && stops.length > 1) {
              final stopsCount = stops.length - 1;
              // Ici on remplace {} dans la clé par stopsCount
              buffer.writeln(
                  'flight_stop_count'.tr(args: [stopsCount.toString()]));
            } else if (stops != null) {
              buffer.writeln('flight_direct'.tr());
            }

            return buffer.toString().trim();
          }

          final allerText = formatFlight(departureFlight);
          final retourText = formatFlight(returnFlight);

          // Si aucun vol n'est dispo, ne rien afficher
          if (allerText.isEmpty && retourText.isEmpty) return null;

          final detailText = [
            if (allerText.isNotEmpty) '${'flight_go'.tr()}\n$allerText',
            if (retourText.isNotEmpty) '${'flight_return'.tr()}\n$retourText',
          ].join('\n\n');

          return (Icons.flight, 'Vol_aller_retour'.tr(), detailText);

        case 'trip':
          if (data['status'] != 'confirmed') return null;

          final hotelN = data['hotelName'] ?? 'Unknown Hotel';
          final destination = data['destination'] ?? 'Unknown';
          final hotelstar = data['hotelStars'] ?? 'Unknown';
          final roomTypeRaw = data['roomType']?.toString() ?? 'unknown';
          final translatedRoomType = _getRoomTypeTranslation(roomTypeRaw);

          final prix = (data['totalPrice'] as num?)?.toDouble() ?? 0.0;

          return (
            Icons.card_travel,
            hotelN,
            '${'hotel_destination'.tr()}: $destination\n'
                '${'hotel_stars'.tr()}: $hotelstar\n'
                '${'room_type'.tr()}: $translatedRoomType\n'
                '${'price'.tr()}: ${currencyNotifier.formatPrice(prix)}'
          );

        default:
          return (Icons.error, "Réservation invalide", 'Type non géré: $type');
      }
    } catch (e) {
      return (
        Icons.warning,
        "Erreur de données",
        'Échec d\'analyse: ${e.toString().split(':').first}'
      );
    }
  }
}

class CarReservationCard extends ConsumerWidget {
  final CarModel car;
  final String totalPrice;
  final String imageUrl;

  const CarReservationCard({
    super.key,
    required this.car,
    required this.totalPrice,
    required this.imageUrl,
  });

  double _parsePrice(String priceString) {
    // Nettoyer la chaîne : retirer les caractères non numériques
    final numericString = priceString.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(numericString) ?? car.pricePerDay * car.rentalDays;
  }

  Widget _buildCarImage(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        imageUrl,
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      height: 220,
      color: Colors.grey[200],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 40),
            SizedBox(height: 8),
            Text('Image non disponible', style: TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyNotifier = ref.watch(currencyProvider.notifier);
    final parsedPrice = _parsePrice(totalPrice);

    final screenHeight = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      child: Container(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.8),
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: _buildCarImage(
                    context), // Utilisation du widget conditionnel
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      car.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Divider(),
                    _buildDetailRow(
                      'Prix_total'.tr(),
                      currencyNotifier
                          .formatPrice(parsedPrice), // Utiliser le double parsé
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label :',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? Colors.green : Colors.black,
                fontSize: isTotal ? 16 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void showTripPhotoAndPriceDialog(
    BuildContext context, Map<String, dynamic> data, Trip trip) {
  final departureDate = (data['departureDate'] as Timestamp).toDate();
  final returnDate = (data['returnDate'] as Timestamp).toDate();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (context) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Modification clé ici : Boucle sur tous les hôtels
              ...trip.hotels.map((hotel) {
                final reservation = Reservation(
                  hotelName: hotel.name,
                  departureDate: departureDate,
                  returnDate: returnDate,
                  roomType: data['roomType'] ?? 'Type de Chambre Inconnu',
                  totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0.0,
                  currency: data['currency']?.toString() ?? '',
                  userEmail: '',
                  departureCity: data['departureCity'] ??
                      '', // Récupération depuis Firestore
                  destination: data['destination'] ??
                      '', // Récupération depuis Firestore
                  hotelStars: hotel.stars, // Utilisation directe de l'hôtel
                  paymentMethod: data['paymentMethod'] ?? '',
                  status: data['status'] ?? '',
                  reservationType: data['reservationType'] ?? '',
                );

                return Column(
                  children: [
                    _buildHotelSection(
                        hotel, reservation, departureDate, returnDate),
                    if (hotel != trip.hotels.last) // Ajout d'un séparateur
                      Divider(color: Colors.grey[300], height: 40),
                  ],
                );
              }),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildHotelSection(Hotel hotel, Reservation reservation,
    DateTime departureDate, DateTime returnDate) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(hotel.name,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo)),
          ),
          Row(
            children: List.generate(
                5,
                (index) => Icon(
                      Icons.star,
                      size: 20,
                      color: index < hotel.stars
                          ? Colors.amber[600]
                          : Colors.grey[300],
                    )),
          ),
        ],
      ),

      const SizedBox(height: 25),

      _buildHotelPhotos(hotel),

      const SizedBox(height: 25),

      _buildDetailRow(
        icon: Icons.calendar_today,
        label: 'Dates du Séjour',
        value:
            '${DateFormat('dd/MM/yyyy').format(departureDate)} - ${DateFormat('dd/MM/yyyy').format(returnDate)}',
      ),
      _buildDetailRow(
        icon: Icons.king_bed,
        label: 'Type_de_Chambre'.tr(),
        value: reservation.roomType,
      ),
      _buildDetailRow(
        icon: Icons.location_pin,
        label: 'Adresse'.tr(),
        value: hotel.address,
      ),
      SizedBox(height: 25),

      // Section Prix
      Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Consumer(
          builder: (context, ref, _) {
            final currencyNotifier = ref.watch(currencyProvider.notifier);
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total_à_Payer'.tr(),
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue[800],
                        fontWeight: FontWeight.w600)),
                Text(
                  currencyNotifier.formatPrice(reservation.totalPrice),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ],
  );
}

Widget _buildHotelPhotos(Hotel hotel) {
  // Debug crucial
  if (kDebugMode) {
    print("Tentative de chargement des photos: ${hotel.photos}");
  }

  return SizedBox(
    height: 200,
    child: hotel.photos.isEmpty // DÉCOMMENTER CETTE LIGNE
        ? _buildNoPhotosPlaceholder()
        : PageView.builder(
            itemCount: hotel.photos.length,
            itemBuilder: (context, index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  hotel.photos[index],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildErrorImage(),
                ),
              ),
            ),
          ),
  );
}

Widget _buildNoPhotosPlaceholder() {
  return Container(
    height: 200,
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(10),
    ),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_camera, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 10),
          Text(
            'Aucune photo disponible',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    ),
  );
}

Widget _buildErrorImage() {
  return Container(
    width: 300,
    color: Colors.grey[200],
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.broken_image, size: 40, color: Colors.grey),
        const SizedBox(height: 10),
        Text(
          'Échec du chargement',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    ),
  );
}

Widget _buildDetailRow({
  required IconData icon,
  required String label,
  required String value,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue[600], size: 24),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    ),
  );
}

Future<void> _confirmDelete(
    BuildContext context, DocumentReference docRef) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text("confirm_annulation".tr()),
      content: Text("annuler_reservation".tr()),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text("cancel".tr()),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child:
              Text("confirmer".tr(), style: const TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    try {
      await docRef.delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("reservation_annuler".tr())),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("delete_error".tr())),
        );
      }
    }
  }
}

class TripReservationCard extends ConsumerWidget {
  final Reservation reservation;
  final Trip trip;
  final Hotel hotel;

  const TripReservationCard({
    super.key,
    required this.reservation,
    required this.trip,
    required this.hotel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyNotifier = ref.watch(currencyProvider.notifier);
    final translatedRoomType =
        _getRoomTypeTranslation(reservation.roomType ?? 'unknown');

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image de l'hôtel
            // À placer dans TripReservationCard.build (remplace juste la section image actuelle)
            if (hotel.photos.isNotEmpty)
              SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: hotel.photos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final photo = hotel.photos[index];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        photo,
                        height: 200,
                        width: 300,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 16),

            // Nom de l'hôtel
            Text(
              hotel.name.tr(),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('${hotel.stars} étoiles - ${hotel.address}'),

            const SizedBox(height: 12),

            // Infos sur la réservation
            _infoLine("Destination".tr(), trip.destination),
            _infoLine("Ville_de_départ".tr(), reservation.departureCity),
            _infoLine(
              "Date".tr(),
              '${_formatDate(reservation.departureDate)} - ${_formatDate(reservation.returnDate)}',
            ),

            _infoLine("Type_de_chambre".tr(), translatedRoomType),

            _infoLine("Prix_total".tr(),
                currencyNotifier.formatPrice(reservation.totalPrice)),

            const SizedBox(height: 12),

            // Services
            _infoLine("Services_de_l_hôtel".tr(),
                hotel.services.map(_getServiceTranslation).join(', ')),

            const SizedBox(height: 12),

            // Description
            Text(
              'Description_du_voyage'.tr(),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(trip.description.tr()),
          ],
        ),
      ),
    );
  }

  Widget _infoLine(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          text: "$title : ",
          style: const TextStyle(fontWeight: FontWeight.bold),
          children: [
            TextSpan(
                text: value,
                style: const TextStyle(fontWeight: FontWeight.normal))
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

String _getServiceTranslation(String service) {
  switch (service) {
    case 'Parking gratuit':
      return 'hotel_services.free_parking'.tr();
    case 'WiFi':
      return 'hotel_services.wifi'.tr();
    case 'Salle de sport':
      return 'hotel_services.gym'.tr();
    case 'Piscine':
      return 'hotel_services.pool'.tr();
    case 'Petit-déjeuner':
      return 'hotel_services.breakfast'.tr();
    case 'Location de vélos':
      return 'hotel_services.bike_rental'.tr();
    case 'Navette aéroport':
      return 'hotel_services.airport_shuttle'.tr();
    case 'Climatisation':
      return 'hotel_services.air_conditioning'.tr();
    case 'Balcon privé':
      return 'hotel_services.private_balcony'.tr();
    case 'Restaurant':
      return 'hotel_services.restaurant'.tr();
    case 'Ascenseur':
      return 'hotel_services.elevator'.tr();
    default:
      return service;
  }
}
