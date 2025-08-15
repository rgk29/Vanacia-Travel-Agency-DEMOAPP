// hotels_by_destination_screen.dart
import 'package:agencedevoyage/currency_provider.dart';
import 'package:agencedevoyage/hotels/local.dart';
import 'package:flutter/material.dart';
import 'package:agencedevoyage/hotels/details.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HotelsByDestinationScreen extends ConsumerWidget {
  final String city;
  final String country;
  final List<Hotells> hotels;

  const HotelsByDestinationScreen({
    super.key,
    required this.city,
    required this.country,
    required this.hotels,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${'Hotels_a'.tr()} ${city.tr()}, ${country.tr()}'),
      ),
      body: hotels.isEmpty
          ? Center(
              child: Text('Aucun_hotel_disponible'.tr()),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: hotels.length,
              itemBuilder: (context, index) {
                final hotel = hotels[index];
                final currencyNotifier = ref.read(currencyProvider.notifier);
                final priceFormatted =
                    currencyNotifier.formatPrice(hotel.pricePerNight);

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HotelDetailsScreen(hotel: hotel),
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(15)),
                          child: Image.asset(
                            hotel.thumbnailUrl,
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hotel.name.tr(),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.star,
                                      color: Colors.amber, size: 20),
                                  Text(' ${hotel.stars}'),
                                  SizedBox(width: 16),
                                  Icon(Icons.location_on,
                                      color: Colors.blue, size: 20),
                                  Text(' ${hotel.address.street.tr()}'),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                '$priceFormatted / ${'par_nuit'.tr()}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
