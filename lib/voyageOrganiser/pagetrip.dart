import 'package:agencedevoyage/voyageOrganiser/personalInfo.dart';
import 'package:agencedevoyage/voyageOrganiser/ripository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Importations des fichiers locaux
import 'package:agencedevoyage/currency_provider.dart';
import 'package:agencedevoyage/voyageOrganiser/trip.dart';
import 'package:agencedevoyage/voyageOrganiser/trip_notifier.dart';

class TripDetailPage extends ConsumerStatefulWidget {
  const TripDetailPage({super.key});
  @override
  ConsumerState<TripDetailPage> createState() => TripDetailPageState();
}

class TripDetailPageState extends ConsumerState<TripDetailPage> {
  Hotel _selectedHotel = Hotel(id: ''); // Ajoutez un constructeur par défaut
  final int _adults = 1;
  final int _children = 0;
  final reservationRepositoryProvider =
      Provider((ref) => ReservationRepository());

  @override
  Widget build(BuildContext context) {
    final trip = ref.read(tripProvider);
    final currencyNotifier = ref.watch(currencyProvider.notifier);
    // Remplacer partout où vous utilisez currencyNotifier.currentCurrency par :
// final currentCurrency = ref.read(currencyProvider).currency;
    final theme = Theme.of(context);
    if (trip.hotels.isNotEmpty) {
      _selectedHotel = trip.hotels.first;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('no_hotels_available'.tr())),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('organized_trips'.tr()),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildPhotoCarousel(trip),
          ),

          // Section informations principales
          _buildTripHeader(context, trip),

          // Informations principales
          SliverList(
            delegate: SliverChildListDelegate([
              _buildTripInfo(context, trip),
            ]),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: _buildHotelsSection(currencyNotifier, trip),
          ),
          // nearplaces

          SliverToBoxAdapter(
              child: _buildNearbyPlaces(_selectedHotel.nearbyPlaces)),

          // Section Extras
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: _buildExtrasSection(currencyNotifier, trip),
          ),

          // Section Carte
          SliverToBoxAdapter(
            child: _buildMapSection(),
          ),
        ],
      ),
    );
  }

  // Section Carrousel d'images
  Widget _buildPhotoCarousel(Trip trip) {
    return SizedBox(
      height: 250,
      child: PageView.builder(
        itemCount: trip.photos.length,
        itemBuilder: (context, index) => Image.asset(
          trip.photos[index],
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // Section Informations principales
  SliverList _buildTripHeader(BuildContext context, Trip trip) {
    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                trip.destination,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.blue[900],
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 20),
              _buildInfoGrid(trip),
              // const SizedBox(height: 20),
              // Text(
              // trip.description,
              // style: Theme.of(context).textTheme.bodyLarge,
              // ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildTripInfo(BuildContext contextTrip, Trip trip) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Details'.tr(),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 16),
          Text(trip.description.tr()),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue[800]),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Grille d'informations
  Widget _buildInfoGrid(Trip trip) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 300 ? 2 : 1;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: constraints.maxWidth > 300 ? 2.3 : 5,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _buildInfoItem(
              Icons.flight_takeoff,
              'departure'.tr(),
              trip.departureCity,
            ),
            _buildInfoItem(
              Icons.calendar_today,
              'departure_date'.tr(),
              DateFormat('dd MMM yyyy').format(trip.departureDate),
            ),
            _buildInfoItem(
              Icons.calendar_today,
              'return_date'.tr(),
              DateFormat('dd MMM yyyy').format(trip.returnDate),
            ),
            _buildInfoItem(
              Icons.access_time,
              'departure_time'.tr(),
              trip.departureTime.format(context),
            ),
            _buildInfoItem(
              Icons.timer,
              'duration'.tr(),
              '${trip.durationDays} ${'days'.tr()}',
            ),
            _buildInfoItem(
              Icons.confirmation_number,
              'tickets'.tr(),
              trip.remainingTickets.toString(),
            ),
          ],
        );
      },
    );
  }

  // Élément d'information
  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue[800]),
          const SizedBox(width: 10),
          Expanded(
            // <-- Ajoutez Expanded ici
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis, // Optionnel
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis, // Optionnel
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Section Hébergements
  SliverList _buildHotelsSection(CurrencyNotifier currencyNotifier, Trip trip) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) =>
            _buildHotelCard(trip.hotels[index], currencyNotifier),
        childCount: trip.hotels.length,
      ),
    );
  }

  // Carte d'hôtel
  Widget _buildHotelCard(Hotel hotel, CurrencyNotifier currencyNotifier) {
    return Card(
      margin: const EdgeInsets.all(15),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHotelPhotos(hotel),
          _buildHotelHeader(hotel),
          _buildRoomOptions(hotel, currencyNotifier),
        ],
      ),
    );
  }

  // En-tête de l'hôtel
  Widget _buildHotelHeader(Hotel hotel) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  hotel.name.tr(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...List.generate(
                hotel.stars,
                (index) =>
                    const Icon(Icons.star, color: Colors.amber, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: hotel.services
                .map((service) => Chip(
                      label: Text(_getServiceTranslation(service)),
                      backgroundColor: Colors.blue[50],
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // Photos de l'hôtel
  Widget _buildHotelPhotos(Hotel hotel) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: hotel.photos.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(left: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              hotel.photos[index],
              width: 300,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  // Options de chambre
  Widget _buildRoomOptions(Hotel hotel, CurrencyNotifier currencyNotifier) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          ...hotel.roomPrices.entries
              .map((entry) => _buildRoomOption(entry, hotel, currencyNotifier)),
        ],
      ),
    );
  }

  // Option de chambre individuelle
  Widget _buildRoomOption(MapEntry<String, double> entry, Hotel hotel,
      CurrencyNotifier currencyNotifier) {
    final availableRooms = hotel.availableRooms[entry.key] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
        title: Text(
          _getRoomTypeTranslation(entry.key),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${'available_rooms'.tr()}: $availableRooms',
            style: TextStyle(
                color: availableRooms > 0 ? Colors.green : Colors.red,
                fontSize: 10)),
        trailing: SizedBox(
          width: 110, // Ajuste si nécessaire
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currencyNotifier.formatPrice(entry.value),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: Colors.blue[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () =>
                    _showReservationDialog(hotel, entry.key, currencyNotifier),
                child: Text(
                  'Réserver'.tr(),
                  style: const TextStyle(fontSize: 9, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Affichage de la section des excursions
  SliverList _buildExtrasSection(CurrencyNotifier currencyNotifier, Trip trip) {
    return SliverList(
      delegate: SliverChildListDelegate(
        [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'Excursions_pendant_le_voyage'.tr(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
          ),
          ...trip.extras.map(
            (extra) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildExtraCard(extra, currencyNotifier),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

// Carte individuelle stylée
  Widget _buildExtraCard(
    ExtraExcursion extra,
    CurrencyNotifier currencyNotifier,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          _getExcursionTitleTranslation(extra.name),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Icon(Icons.person, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '${'adult'.tr()}: ${currencyNotifier.formatPrice(extra.adultPrice)}',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 15),
              Icon(Icons.child_care, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '${'child'.tr()}: ${currencyNotifier.formatPrice(extra.childPrice)}',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        children: [
          if (extra.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: Image.asset(
                extra.imageUrl.first,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 180,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _getExcursionDescriptionTranslation(extra.name),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'location'.tr(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.blue[800],
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 15),
          Container(
            height: 250,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(
                    _selectedHotel.location.lat,
                    _selectedHotel.location.lng,
                  ),
                  initialZoom: 13.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.agencedevoyage.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 40.0,
                        height: 40.0,
                        point: LatLng(
                          _selectedHotel.location.lat,
                          _selectedHotel.location.lng,
                        ),
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildAddressRow(),
        ],
      ),
    );
  }

  Widget _buildNearbyPlaces(List<PointOfInterest> places) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 25.0, top: 10.0, bottom: 8.0),
          child: Text(
            'points_of_interest'.tr(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
              fontSize: 20,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Column(
          children: places.map((place) => _buildPlaceItem(place)).toList(),
        ),
      ],
    );
  }

  Widget _buildPlaceItem(PointOfInterest place) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      shadowColor: Colors.blueGrey.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(0.1),
              ),
              child: Icon(
                place.icon,
                size: 24,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${place.distance.toStringAsFixed(1)} km',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Icon(Icons.location_on, color: Colors.blue[800], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _selectedHotel.address,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReservationDialog(
      Hotel hotel, String roomType, CurrencyNotifier currencyNotifier) {
    int adults = 1;
    int children = 0;
    final roomPrice = hotel.roomPrices[roomType] ?? 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final totalPrice =
                (adults * roomPrice) + (children * roomPrice * 0.5);

            return AlertDialog(
              title: Text('make_reservation'.tr()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: roomType,
                    items: hotel.roomPrices.keys
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.tr()),
                            ))
                        .toList(),
                    onChanged: (value) {},
                    decoration: InputDecoration(labelText: 'room_type'.tr()),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: '1',
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: 'adults'.tr()),
                          onChanged: (value) =>
                              setState(() => adults = int.tryParse(value) ?? 1),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          initialValue: '0',
                          keyboardType: TextInputType.number,
                          decoration:
                              InputDecoration(labelText: 'children'.tr()),
                          onChanged: (value) => setState(
                              () => children = int.tryParse(value) ?? 0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${'total_price'.tr()}: ${currencyNotifier.formatPrice(totalPrice)}',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('cancel'.tr()),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('must_be_logged_in'.tr())),
                      );
                      return;
                    }

                    final trip = ref.read(tripProvider);

                    // Enregistrement initial
                    await FirebaseFirestore.instance
                        .collection('organized_trips_reservations')
                        .add({
                      'tripId': trip.id,
                      'userEmail': user.email,
                      'reservationDate': FieldValue.serverTimestamp(),

                      'hotel': {
                        'name': hotel.name,
                        'stars': hotel.stars,
                        'address': hotel.address,
                        'roomType': roomType,
                      },
                      'departureCity': trip.departureCity,
                      'destination': trip.destination,
                      'departureDate': Timestamp.fromDate(trip.departureDate),
                      'returnDate': Timestamp.fromDate(trip.returnDate),
                      // Prix et devise
                      'baseCurrency': 'DZD',
                      'totalPrice': totalPrice,
                      'currency': currencyNotifier.state.currency,
                      'conversionRate': currencyNotifier
                          .state.rates[currencyNotifier.state.currency],

                      'status': 'pending',
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HotelPersonalInfoPage(
                          tripId: trip.id,
                          userEmail: user.email!,
                          trip: trip,
                          hotel: hotel,
                          roomType: roomType,
                          adults: adults,
                          children: children,
                          hotelReservation: {
                            ' tripId': trip.id,
                            'totalPrice': totalPrice,
                            'currency': currencyNotifier.state
                                .currency, // Utilisez state.currency directement
                            'originalPrice': totalPrice /
                                currencyNotifier.state
                                    .rates[currencyNotifier.state.currency]!,
                          },
                        ),
                      ),
                    );
                  },
                  child: Text('confirm_reservation'.tr()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleReservation(
      Hotel hotel, String roomType, int guests) async {
    final tripNotifier = ref.read(tripProvider.notifier);
    final reservationRepo = ReservationRepository();
    final userEmail = reservationRepo.getCurrentUserEmail();

    if (userEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('must_be_logged_in'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Mettre à jour l'état local
      tripNotifier.makeReservation(
        hotelName: hotel.name,
        roomType: roomType,
        guests: guests,
      );

      // Récupérer les données du voyage
      final trip = ref.read(tripProvider);

      // Créer l'objet réservation
      // final reservation = Reservation(
      //   userEmail: userEmail,
      //   roomType: roomType,
      //   departureCity: trip.departureCity,
      //   destination: trip.destination,
      //   departureDate: trip.departureDate,
      //   returnDate: trip.returnDate,
      //   hotelName: hotel.name,
      //   hotelStars: hotel.stars,
      //   reservationDate: DateTime.now(),
      // );

      // Enregistrer dans Firebase
      // await reservationRepo.saveReservation(reservation);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HotelPersonalInfoPage(
            userEmail: userEmail,
            trip: trip,
            tripId: trip.id,
            hotel: hotel,
            roomType: roomType,
            adults: guests, // si 'guests' est le nombre total d'adultes
            // selectedHotel: hotel,
            hotelReservation: {},
            children: 0, // tu peux changer selon ton contexte
          ),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('reservation_success'.tr()),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'reservation_failed'.tr()}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

String _getExcursionDescriptionTranslation(String name) {
  switch (name) {
    case 'Balade en dromadaire':
      return 'extras.camel_ride_desc'.tr();
    case 'Randonnée en Quad':
      return 'extras.quad_ride_desc'.tr();
    case 'Soirée traditionnelle sous Khaima':
      return 'extras.khaima_evening_desc'.tr();
    case 'Croisière sur le Bosphore':
      return 'extras.bosphorus_cruise_desc'.tr();
    case 'Tour de ville en bus panoramique':
      return 'extras.city_bus_tour_desc'.tr();
    case 'Journée à la Princesse Island':
      return 'extras.princess_island_day_desc'.tr();
    default:
      return '';
  }
}

String _getExcursionTitleTranslation(String name) {
  switch (name) {
    case 'Balade en dromadaire':
      return 'extras.camel_ride'.tr();
    case 'Randonnée en Quad':
      return 'extras.quad_ride'.tr();
    case 'Soirée traditionnelle sous Khaima':
      return 'extras.khaima_evening'.tr();
    case 'Croisière sur le Bosphore':
      return 'extras.bosphorus_cruise'.tr();
    case 'Tour de ville en bus panoramique':
      return 'extras.city_bus_tour'.tr();
    case 'Journée à la Princesse Island':
      return 'extras.princess_island_day'.tr();
    default:
      return name;
  }
}

String _getRoomTypeTranslation(String roomType) {
  switch (roomType) {
    case 'Triple':
      return 'room_types.triple'.tr();
    case 'Double':
      return 'room_types.double'.tr();
    case 'Single':
      return 'room_types.single'.tr();
    case 'Suite':
      return 'room_types.suite'.tr();
    case 'Familiale':
      return 'room_types.family'.tr();
    case 'Non_smoking':
      return 'room_types.non_smoking'.tr();
    case 'Fumeurs':
      return 'room_types.smoking'.tr();
    default:
      return roomType;
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
