import 'package:agencedevoyage/favorie.dart';
import 'package:agencedevoyage/hotels/data.dart';
import 'package:agencedevoyage/hotels/details.dart';
import 'package:agencedevoyage/signin_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'local.dart';
import 'package:agencedevoyage/currency_provider.dart'; // Remplace par ton import correct

class HotelResultsPage extends ConsumerStatefulWidget {
  final DateTime checkInDate;
  final DateTime checkOutDate;

  const HotelResultsPage({
    super.key,
    required this.checkInDate,
    required this.checkOutDate,
  });

  @override
  ConsumerState<HotelResultsPage> createState() => HotelResultsPageState();
}

class HotelResultsPageState extends ConsumerState<HotelResultsPage> {
  // Filtres
  String? selectedProvince;
  RangeValues priceRange = const RangeValues(5000, 200000);
  Set<PropertyType> selectedPropertyTypes = {};
  Set<Facilities> selectedFacilities = {};
  Set<RoomType> selectedRoomTypes = {};

  void resetFilters() {
    setState(() {
      selectedProvince = null;
      priceRange = const RangeValues(5000, 200000);
      selectedPropertyTypes.clear();
      selectedFacilities.clear();
      selectedRoomTypes.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final nights = widget.checkOutDate.difference(widget.checkInDate).inDays;
    final currencyNotifier = ref.read(currencyProvider.notifier);

    final filteredHotels = localHotels.where((hotel) {
      final isInDateRange = widget.checkInDate
              .isAfter(hotel.arrivalDate.subtract(const Duration(days: 1))) &&
          widget.checkOutDate
              .isBefore(hotel.departureDate.add(const Duration(days: 1)));

      final isInProvince = selectedProvince == null ||
          hotel.address.province == selectedProvince;

      final isInPriceRange = hotel.pricePerNight >= priceRange.start &&
          hotel.pricePerNight <= priceRange.end;

      final matchesPropertyType = selectedPropertyTypes.isEmpty ||
          selectedPropertyTypes.contains(hotel.propertyType);

      final matchesFacilities = selectedFacilities.isEmpty ||
          selectedFacilities.every((f) => hotel.facilities.contains(f));

      final matchesRoomTypes = selectedRoomTypes.isEmpty ||
          selectedRoomTypes.any((type) => hotel.availableRooms.contains(type));

      return isInDateRange &&
          isInProvince &&
          isInPriceRange &&
          matchesPropertyType &&
          matchesFacilities &&
          matchesRoomTypes;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
            'results_count'
                .tr(namedArgs: {'count': filteredHotels.length.toString()}),
            style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2A5C82),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFiltersBottomSheet(context),
          ),
        ],
      ),
      body: filteredHotels.isEmpty
          ? _buildNoResults()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredHotels.length,
              itemBuilder: (context, index) => HotelCard(
                hotel: filteredHotels[index],
                nights: nights,
              ),
            ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hotel_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text('Aucun_hôtel_trouve_pour_ces_filtres'.tr(),
              style: TextStyle(fontSize: 18, color: Colors.grey[600])),
        ],
      ),
    );
  }

  void _showFiltersBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text('Filtres_avancés'.tr(),
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text(
                    'price_per_night_range'.tr(namedArgs: {
                      'min': priceRange.start.toInt().toString(),
                      'max': priceRange.end.toInt().toString(),
                    }),
                  ),
                  RangeSlider(
                    min: 5000,
                    max: 200000,
                    divisions: 20,
                    values: priceRange,
                    onChanged: (values) {
                      setState(() => priceRange = values);
                      setModalState(() {});
                    },
                  ),
                  ExpansionTile(
                    title: Text('Type_de_logement'.tr()),
                    children: PropertyType.values.map((type) {
                      return CheckboxListTile(
                        title: Text(_getPropertyTypeTranslation(type)),
                        value: selectedPropertyTypes.contains(type),
                        onChanged: (bool? selected) {
                          setState(() {
                            selected!
                                ? selectedPropertyTypes.add(type)
                                : selectedPropertyTypes.remove(type);
                          });
                          setModalState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  ExpansionTile(
                    title: Text('Équipements'.tr()),
                    children: Facilities.values.map((facility) {
                      return CheckboxListTile(
                        title: Text(_getFacilityTranslation(facility)),
                        value: selectedFacilities.contains(facility),
                        onChanged: (bool? selected) {
                          setState(() {
                            selected!
                                ? selectedFacilities.add(facility)
                                : selectedFacilities.remove(facility);
                          });
                          setModalState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  ExpansionTile(
                    title: Text('Types_de_chambre'.tr()),
                    children: RoomType.values.map((room) {
                      final roomName = room
                          .toString()
                          .split('.')
                          .last; // Conversion enum -> string
                      return CheckboxListTile(
                        title: Text(
                            _getRoomTypeTranslation(room)), // Formatage du nom
                        value: selectedRoomTypes.contains(room),
                        onChanged: (bool? selected) {
                          setState(() {
                            selected!
                                ? selectedRoomTypes.add(room)
                                : selectedRoomTypes.remove(room);
                          });
                          setModalState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: Text("Réinitialiser".tr()),
                        onPressed: () {
                          setState(() => resetFilters());
                          Navigator.pop(context);
                        },
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: Text("Appliquer".tr()),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}

String _getPropertyTypeTranslation(PropertyType propertyType) {
  switch (propertyType) {
    case PropertyType.hotel:
      return 'propertyTypes.hotel'.tr(); // traduction pour hôtel
    case PropertyType.apartment:
      return 'propertyTypes.apartment'.tr(); // traduction pour appartement
    case PropertyType.vacationHome:
      return 'propertyTypes.vacationHome'
          .tr(); // traduction pour maison de vacances
    case PropertyType.villa:
      return 'propertyTypes.villa'.tr(); // traduction pour villa
    default:
      return '';
  }
}

String _getRoomTypeTranslation(RoomType roomType) {
  switch (roomType) {
    case RoomType.single:
      return 'roomTypes.single'.tr();
    case RoomType.double:
      return 'roomTypes.double'.tr();
    case RoomType.triple:
      return 'roomTypes.triple'.tr();
    case RoomType.family:
      return 'roomTypes.family'.tr();
    case RoomType.suite:
      return 'roomTypes.suite'.tr();
    default:
      return '';
  }
}

String _getFacilityTranslation(Facilities facility) {
  switch (facility) {
    case Facilities.wifi:
      return 'facilities.wifi'.tr(); // traduction pour wifi
    case Facilities.tv:
      return 'facilities.tv'.tr(); // traduction pour tv
    case Facilities.parking:
      return 'facilities.parking'.tr(); // traduction pour parking
    case Facilities.pool:
      return 'facilities.pool'.tr(); // traduction pour piscine
    case Facilities.restaurant:
      return 'facilities.restaurant'.tr(); // traduction pour restaurant
    case Facilities.spa:
      return 'facilities.spa'.tr(); // traduction pour spa
    case Facilities.airportShuttle:
      return 'facilities.airportShuttle'
          .tr(); // traduction pour navette aéroport
    case Facilities.nonSmokingRooms:
      return 'facilities.nonSmokingRooms'
          .tr(); // traduction pour chambres non fumeur
    case Facilities.frontDesk24h:
      return 'facilities.frontDesk24h'.tr(); // traduction pour réception 24h
    case Facilities.heating:
      return 'facilities.heating'.tr(); // traduction pour chauffage
    case Facilities.housekeeping:
      return 'facilities.housekeeping'.tr(); // traduction pour ménage
    case Facilities.luggageStorage:
      return 'facilities.luggageStorage'
          .tr(); // traduction pour consigne à bagages
    case Facilities.airConditioning:
      return 'facilities.airConditioning'.tr(); // traduction pour climatisation
    case Facilities.roomService:
      return 'facilities.roomService'.tr(); // traduction pour service d'étage
    case Facilities.familyRooms:
      return 'facilities.familyRooms'
          .tr(); // traduction pour chambres familiales
    case Facilities.breakfast:
      return 'facilities.breakfast'.tr(); // traduction pour petit-déjeuner
    case Facilities.kitchen:
      return 'facilities.kitchen'.tr(); // traduction pour cuisine
    case Facilities.garden:
      return 'facilities.garden'.tr(); // traduction pour jardin
    case Facilities.petsAllowed:
      return 'facilities.petsAllowed'.tr(); // traduction pour animaux acceptés
    default:
      return '';
  }
}

class HotelCard extends ConsumerWidget {
  final Hotells hotel;
  final int nights;

  const HotelCard({
    super.key,
    required this.hotel,
    required this.nights,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final isFavorite = favorites.contains(hotel.id);
    final user = ref.watch(authProvider);
    final totalPrice = hotel.discountedPrice * nights;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.asset(
                  hotel.thumbnailUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.white,
                    size: 30,
                  ),
                  onPressed: () {
                    if (user == null) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Connexion_requise'.tr()),
                          content: Text(
                              'Connectez_vous_pour_ajouter_aux_favoris'.tr()),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Annuler'.tr()),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                // Redirection vers votre écran d'authentification existant
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const AuthPage()),
                                );
                              },
                              child: Text('Se_connecter'.tr()),
                            ),
                          ],
                        ),
                      );
                      return;
                    }
                    ref
                        .read(favoritesProvider.notifier)
                        .toggleFavorite(hotel.id);
                  },
                ),
              ),
              if (hotel.hasPromotion)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      hotel.discountLabel,
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(height: 10),
                    Expanded(
                      child: Text(
                        hotel.name.tr(),
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ...List.generate(
                      hotel.stars,
                      (index) =>
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${hotel.address.city.tr()}, ${hotel.address.province.tr()}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 8),
                // Affichage du PropertyType avec traduction
                Chip(
                  label: Text(
                    _getPropertyTypeTranslation(hotel
                        .propertyType), // Utilisation de la méthode de traduction
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 12),
                // Équipements
                Wrap(
                  spacing: 8,
                  children: hotel.facilities
                      .map((facility) => Tooltip(
                            message: _getFacilityTranslation(
                                facility), // Utilisation de la traduction ici
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(facility.icon,
                                      size: 18, color: Colors.blue[800]),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getFacilityTranslation(
                                        facility), // Utilisation de la traduction ici
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue[800],
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                ),

                const SizedBox(height: 16),
                Consumer(
                  builder: (context, ref, _) {
                    final currencyNotifier =
                        ref.watch(currencyProvider.notifier);
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hotel.hasPromotion)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        currencyNotifier.formatPrice(
                                            hotel.originalPrice ??
                                                hotel.pricePerNight),
                                        style: TextStyle(
                                            decoration:
                                                TextDecoration.lineThrough,
                                            color: Color.fromARGB(
                                                255, 138, 124, 124),
                                            fontSize: 14),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                            color: Colors.red[100],
                                            borderRadius:
                                                BorderRadius.circular(4)),
                                        child: Text(
                                          hotel.discountLabel,
                                          style: TextStyle(
                                              color: Colors.red[900],
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                ],
                              ),
                            Text(
                              currencyNotifier
                                  .formatPrice(hotel.discountedPrice),
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: hotel.hasPromotion
                                      ? Colors.green
                                      : Color(0xFF2A5C82)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${currencyNotifier.formatPrice(totalPrice)} ${'price_for_nights'.tr(namedArgs: {
                                    // 'price': currencyNotifier
                                    //     .formatPrice(totalPrice),
                                    'nights': nights.toString()
                                  })}',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Color.fromARGB(255, 64, 48, 48)),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3AB795),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    HotelDetailsScreen(hotel: hotel),
                              ),
                            );
                          },
                          child: Text('Voir_details'.tr(),
                              style: TextStyle(color: Colors.white)),
                        )
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getFacilityTranslation(Facilities facility) {
    switch (facility) {
      case Facilities.wifi:
        return 'facilities.wifi'.tr(); // traduction pour wifi
      case Facilities.tv:
        return 'facilities.tv'.tr(); // traduction pour tv
      case Facilities.parking:
        return 'facilities.parking'.tr(); // traduction pour parking
      case Facilities.pool:
        return 'facilities.pool'.tr(); // traduction pour piscine
      case Facilities.restaurant:
        return 'facilities.restaurant'.tr(); // traduction pour restaurant
      case Facilities.spa:
        return 'facilities.spa'.tr(); // traduction pour spa
      case Facilities.airportShuttle:
        return 'facilities.airportShuttle'
            .tr(); // traduction pour navette aéroport
      case Facilities.nonSmokingRooms:
        return 'facilities.nonSmokingRooms'
            .tr(); // traduction pour chambres non fumeur
      case Facilities.frontDesk24h:
        return 'facilities.frontDesk24h'.tr(); // traduction pour réception 24h
      case Facilities.heating:
        return 'facilities.heating'.tr(); // traduction pour chauffage
      case Facilities.housekeeping:
        return 'facilities.housekeeping'.tr(); // traduction pour ménage
      case Facilities.luggageStorage:
        return 'facilities.luggageStorage'
            .tr(); // traduction pour consigne à bagages
      case Facilities.airConditioning:
        return 'facilities.airConditioning'
            .tr(); // traduction pour climatisation
      case Facilities.roomService:
        return 'facilities.roomService'.tr(); // traduction pour service d'étage
      case Facilities.familyRooms:
        return 'facilities.familyRooms'
            .tr(); // traduction pour chambres familiales
      case Facilities.breakfast:
        return 'facilities.breakfast'.tr(); // traduction pour petit-déjeuner
      case Facilities.kitchen:
        return 'facilities.kitchen'.tr(); // traduction pour cuisine
      case Facilities.garden:
        return 'facilities.garden'.tr(); // traduction pour jardin
      case Facilities.petsAllowed:
        return 'facilities.petsAllowed'
            .tr(); // traduction pour animaux acceptés
      default:
        return '';
    }
  }

  String _getPropertyTypeTranslation(PropertyType propertyType) {
    switch (propertyType) {
      case PropertyType.hotel:
        return 'propertyTypes.hotel'.tr(); // traduction pour hôtel
      case PropertyType.apartment:
        return 'propertyTypes.apartment'.tr(); // traduction pour appartement
      case PropertyType.vacationHome:
        return 'propertyTypes.vacationHome'
            .tr(); // traduction pour maison de vacances
      case PropertyType.villa:
        return 'propertyTypes.villa'.tr(); // traduction pour villa
      default:
        return '';
    }
  }
}
