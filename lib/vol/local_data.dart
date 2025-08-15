import 'package:agencedevoyage/vol/model.dart';
import 'package:easy_localization/easy_localization.dart';

class LocalData {
  static final List<Airport> airports = [
    Airport(
      code: 'ALG',
      name: 'Aéroport d\'Alger Houari Boumediene',
      city: 'Alger',
      keywords: ['alg', 'alger', 'algérie', 'daa', 'DZ'],
    ),
    Airport(
      code: 'ORN',
      name: 'Aéroport d\'Oran Ahmed Ben Bella',
      city: 'Oran',
      keywords: ['Oran', 'Ouahran', '31', 'Wahren'],
    ),
    Airport(
      code: 'CDG',
      name: 'Aéroport paris charle de gaulle',
      city: 'Paris',
      keywords: ['Paris', 'France', 'fr', 'FR'],
    ),
    Airport(
      code: 'BCN',
      name: 'Aéroport Barcelone - Josep Tarradellas Barcelona-El Prat ',
      city: 'Barcelone',
      keywords: ['Barcelone', 'barca'],
    ),
    Airport(
      code: 'ALC',
      name: ' Aéroport Alicante-Elche Miguel Hernández ',
      city: 'Alicante',
      keywords: ['Alicante', 'alic'],
    ),

    // Ajouter d'autres aéroports...
  ];

  static final List<Flight> flights = [
    //ALLER
    Flight(
      id: 'AL123',
      company: 'Air Algérie',
      departure: airports.firstWhere((a) => a.code == 'ALG'),

      arrival: airports.firstWhere((a) => a.code == 'CDG'),
      departureTime: DateTime(2025, 3, 22, 8, 30), // 22/03/2025 08:30
      arrivalTime: DateTime(2025, 3, 22, 12, 0),

      classe: 'Economique'.tr(),
      priceDZD: 25000,
      stops: ['ALG'],

      logoAsset: 'assets/AirAlgérie.jpg',
      reservationType: 'flight',
      // adults: 1,
      // teens: 0,
      // children: 0,
    ),

    Flight(
      id: 'AL123',
      company: 'Air Algérie',
      departure: airports.firstWhere((a) => a.code == 'CDG'),
      arrival: airports.firstWhere((a) => a.code == 'ALG'),
      departureTime: DateTime(2025, 3, 29, 15, 30), // 22/03/2025 08:30
      arrivalTime: DateTime(2025, 3, 29, 16, 30),
      classe: 'Economique'.tr(),
      priceDZD: 25000,
      stops: ['ALG'],

      logoAsset: 'assets/AirAlgérie.jpg',
      // adults: 1,
      // teens: 0,
      // children: 0,
      reservationType: 'flight',
    ),

    Flight(
      id: 'VUE',
      company: 'VUELING',
      departure: airports.firstWhere((a) => a.code == 'ALG'),

      arrival: airports.firstWhere((a) => a.code == 'CDG'),
      departureTime: DateTime(2025, 3, 22, 8, 30), // 22/03/2025 08:30
      arrivalTime: DateTime(2025, 3, 22, 12, 0),
      classe: 'Economique'.tr(),
      priceDZD: 27000,
      stops: ['VUE'],

      logoAsset: 'assets/Vuelinglogo.jpg',
      // adults: 1,
      // teens: 0,
      // children: 0,
      reservationType: 'flight',
    ),
// RETOUR
    Flight(
      id: 'AF123',
      company: 'Air France',
      departure: airports.firstWhere((a) => a.code == 'CDG'),
      arrival: airports.firstWhere((a) => a.code == 'ALG'),
      departureTime: DateTime(2025, 3, 29, 11, 30), // 22/03/2025 08:30
      arrivalTime: DateTime(2025, 3, 29, 13, 0),
      classe: 'Economique'.tr(),
      priceDZD: 27500,
      stops: ['FR'],
      logoAsset: 'assets/AirFranceLogo.jpg',
      // adults: 1,
      // teens: 0,
      // children: 0,
      reservationType: 'flight',
    ),

    Flight(
      id: 'Luf321',
      company: 'LUFTHANSA',
      departure: airports.firstWhere((a) => a.code == 'CDG'),
      arrival: airports.firstWhere((a) => a.code == 'ALG'),
      departureTime: DateTime(2025, 3, 29, 8, 30), // 22/03/2025 08:30
      arrivalTime: DateTime(2025, 3, 29, 10, 0),
      classe: 'Economique'.tr(),
      priceDZD: 30000,
      stops: ['LUF'],
      logoAsset: 'assets/Lufthansa.jpg',
      // adults: 1,
      // teens: 0,
      // children: 0,
      reservationType: 'flight',
    ),

    // /////////////////////////////////////////////////////////////////////////
//oran

    Flight(
      id: 'AL123',
      company: 'Air Algerie ',
      departure: airports.firstWhere((a) => a.code == 'ORN'),
      arrival: airports.firstWhere((a) => a.code == 'BCN'),
      departureTime: DateTime(2025, 8, 15, 8, 30), // 22/03/2025 08:30
      arrivalTime: DateTime(2025, 8, 15, 10, 0),
      classe: 'Economique'.tr(),
      priceDZD: 30000,
      stops: ['ALG'],
      logoAsset: 'assets/AirAlgérie.jpg',
      // adults: 1,
      // teens: 0,
      // children: 0,
      reservationType: 'flight',
    ),
    Flight(
      id: 'AL123',
      company: 'Air Algerie ',
      departure: airports.firstWhere((a) => a.code == 'BCN'),
      arrival: airports.firstWhere((a) => a.code == 'ORN'),
      departureTime: DateTime(2025, 8, 22, 10, 30), // 22/03/2025 08:30
      arrivalTime: DateTime(2025, 8, 22, 11, 20),
      classe: 'Economique'.tr(),
      priceDZD: 30000,
      stops: ['ALG'],
      logoAsset: 'assets/AirAlgérie.jpg',
      // adults: 1,
      // teens: 0,
      // children: 0,
      reservationType: 'flight',
    ),

    Flight(
      id: 'Luf321',
      company: 'LUFTHANSA',
      departure: airports.firstWhere((a) => a.code == 'ORN'),
      arrival: airports.firstWhere((a) => a.code == 'BCN'),
      departureTime: DateTime(2025, 8, 15, 8, 30), // 22/03/2025 08:30
      arrivalTime: DateTime(2025, 8, 15, 10, 0),
      classe: 'Economique'.tr(),
      priceDZD: 32000,
      stops: ['LUF'],
      logoAsset: 'assets/Lufthansa.jpg',
      // adults: 1,
      // teens: 0,
      // children: 0,
      reservationType: 'flight',
    ),
    Flight(
      id: 'Luf321',
      company: 'LUFTHANSA',
      departure: airports.firstWhere((a) => a.code == 'BCN'),
      arrival: airports.firstWhere((a) => a.code == 'ORN'),
      departureTime: DateTime(2025, 8, 22, 8, 30), // 22/03/2025 08:30
      arrivalTime: DateTime(2025, 8, 22, 10, 0),
      classe: 'Economique'.tr(),
      priceDZD: 35000,
      stops: ['LUF'],
      logoAsset: 'assets/Lufthansa.jpg',
      // adults: 1,
      // teens: 0,
      // children: 0,
      reservationType: 'flight',
    ),

    Flight(
      id: 'VUE',
      company: 'VUELING',
      departure: airports.firstWhere((a) => a.code == 'ORN'),
      arrival: airports.firstWhere((a) => a.code == 'BCN'),
      departureTime: DateTime(2025, 8, 15, 8, 30), // 22/03/2025 08:30
      arrivalTime: DateTime(2025, 8, 15, 10, 0),
      classe: 'Economique'.tr(),
      priceDZD: 34000,
      stops: ['VUE'],
      logoAsset: 'assets/Vuelinglogo.jpg',
      // adults: 1,
      // teens: 0,
      // children: 0,
      reservationType: 'flight',
    ),
    Flight(
      id: 'AF321',
      company: 'Air France',
      departure: airports.firstWhere((a) => a.code == 'BCN'),
      arrival: airports.firstWhere((a) => a.code == 'ORN'),
      departureTime: DateTime(2025, 8, 22, 8, 30), // 22/03/2025 08:30
      arrivalTime: DateTime(2025, 8, 22, 10, 0),
      classe: 'Economique'.tr(),
      priceDZD: 35000,
      stops: ['FR'],
      logoAsset: 'assets/AirFranceLogo.jpg',
      // adults: 1,
      // teens: 0,
      // children: 0,
      reservationType: 'flight',
    ), // Ajouter 19 autres vols...

    /////////////////////////////////////////////////////////////
    ///ALICANTE

    Flight(
      id: 'AL123',
      company: 'Air Algerie ',
      departure: airports.firstWhere((a) => a.code == 'ORN'),
      arrival: airports.firstWhere((a) => a.code == 'ALC'),
      departureTime: DateTime(2025, 6, 29, 8, 30), // 22/03/2025 08:30
      arrivalTime: DateTime(2025, 6, 29, 10, 0),
      classe: 'Economique'.tr(),
      priceDZD: 30000,
      stops: ['ALG'],
      logoAsset: 'assets/AirAlgérie.jpg',
      // adults: 1,
      // teens: 0,
      // children: 0,
      reservationType: 'flight',
    ),
    Flight(
      id: 'AL123',
      company: 'Air Algerie ',
      departure: airports.firstWhere((a) => a.code == 'ALC'),
      arrival: airports.firstWhere((a) => a.code == 'ORN'),
      departureTime: DateTime(2025, 7, 7, 10, 30), // 22/03/2025 08:30
      arrivalTime: DateTime(2025, 7, 7, 11, 20),
      classe: 'Economique'.tr(),
      priceDZD: 30000,
      stops: ['ALG'],
      logoAsset: 'assets/AirAlgérie.jpg',
      // adults: 1,
      // teens: 0,
      // children: 0,
      reservationType: 'flight',
    ),

    Flight(
      id: 'Luf321',
      company: 'LUFTHANSA',
      departure: airports.firstWhere((a) => a.code == 'ALG'),
      arrival: airports.firstWhere((a) => a.code == 'ALC'),
      departureTime: DateTime(2025, 7, 15, 8, 30), // 22/03/2025 08:30
      arrivalTime: DateTime(2025, 7, 15, 10, 0),
      classe: 'Economique'.tr(),
      priceDZD: 32000,
      stops: ['LUF'],
      logoAsset: 'assets/Lufthansa.jpg',
      // adults: 1,
      // teens: 0,
      // children: 0,
      reservationType: 'flight',
    ),
    Flight(
      id: 'Luf321',
      company: 'LUFTHANSA',
      departure: airports.firstWhere((a) => a.code == 'ALC'),
      arrival: airports.firstWhere((a) => a.code == 'ALG'),
      departureTime: DateTime(2025, 7, 21, 8, 30), // 22/03/2025 08:30
      arrivalTime: DateTime(2025, 7, 21, 10, 0),
      classe: 'Economique'.tr(),
      priceDZD: 35000,
      stops: ['LUF'],
      logoAsset: 'assets/Lufthansa.jpg',
      // adults: 1,
      // teens: 0,
      // children: 0,
      reservationType: 'flight',
    ),

    Flight(
      id: 'VUE',
      company: 'VUELING',
      departure: airports.firstWhere((a) => a.code == 'ORN'),
      arrival: airports.firstWhere((a) => a.code == 'ALC'),
      departureTime: DateTime(2025, 6, 29, 8, 30), // 22/03/2025 08:30
      arrivalTime: DateTime(2025, 6, 29, 10, 0),
      classe: 'Economique'.tr(),
      priceDZD: 34000,
      stops: ['VUE'],
      logoAsset: 'assets/Vuelinglogo.jpg',
      // adults: 1,
      // teens: 0,
      // children: 0,
      reservationType: 'flight',
    ),
    Flight(
      id: 'AF321',
      company: 'Air France',
      departure: airports.firstWhere((a) => a.code == 'ALC'),
      arrival: airports.firstWhere((a) => a.code == 'ORN'),
      departureTime: DateTime(2025, 7, 7, 8, 30), // 22/03/2025 08:30
      arrivalTime: DateTime(2025, 7, 7, 10, 0),
      classe: 'Economique'.tr(),
      priceDZD: 35000,
      stops: ['FR'],
      logoAsset: 'assets/AirFranceLogo.jpg',
      // adults: 1,
      // teens: 0,
      // children: 0,
      reservationType: 'flight',
    ), // Ajouter 19 autres vols...
  ];
}
