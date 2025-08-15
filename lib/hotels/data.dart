import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'local.dart';

String getTranslatedRoomType(RoomType roomType, BuildContext context) {
  switch (roomType) {
    case RoomType.double:
      return 'roomTypes.double'.tr();
    case RoomType.single:
      return 'roomTypes.single'.tr();
    case RoomType.triple:
      return 'roomTypes.triple'.tr();
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

final List<Hotells> localHotels = [
  Hotells(
    id: 'htl1',
    name: 'Montparnasse_Daguerre',
    stars: 3,
    pricePerNight: 18000, // À ajuster selon la devise réelle
    hasPromotion: true,
    originalPrice: 20000, // Prix original
    discountPercentage: 10,
    propertyType: PropertyType.hotel,
    address: Address(
      street: '94_Rue_Daguerre',
      city: 'Paris',
      province: 'Ile_de_France',
      country: 'France',
      location:
          Locationn(lat: 48.8337, lng: 2.3293), // Coordonnées approximatives
    ),
    imageUrls: [
      'assets/parish/hotel1/1.jpg',
      'assets/parish/hotel1/3.jpg',
      'assets/parish/hotel1/4.jpg',
      'assets/parish/hotel1/5.jpg',
      'assets/parish/hotel1/6.jpg',
      'assets/parish/hotel1/7.jpg',
    ],
    thumbnailUrl: 'assets/parish/hotel1/1.jpg',
    description: 'description1',
    availableRooms: [
      // Sans guillemets
      RoomType.double,
      RoomType.single,
      RoomType.triple,
    ],
    nearbyPoints: {
      'gardens': [
        'garden_of_the_3_cornets_mill_150m',
        'françoise_heritier_garden_500m',
        'denfert_rochereau_square_600m'
      ],
      'restaurants': ['reunion_island_50m', 'aasman_50m', 'sl_sushi_50m']
    },
    facilities: [
      Facilities.nonSmokingRooms,
      Facilities.wifi,
      Facilities.frontDesk24h,
      Facilities.heating,
      Facilities.housekeeping,
      Facilities.luggageStorage,
      Facilities.airConditioning
    ],
    hotelRules: {
      'Check_in': '15:00',
      'Check_out': '12:00',
    },
    paymentMethods: ['Carte bancaire', 'Espèces'],
    arrivalDate: DateTime(2025, 07, 15),
    departureDate: DateTime(2025, 07, 22), // Date d'exemple
    durationDays: 7, // Calculé automatiquement
    keywords: [
      'paris'.tr(),
      'hotel'.tr(),
      'france'.tr(),
      '14th_arrondissement'.tr(),
      'wifi_gratuit'.tr(),
      'non-fumeur'.tr(),
      'climatisation'.tr(),
      'montparnassedaguerre'.tr()
    ],
  ),
  Hotells(
    id: 'htl2',
    name: 'Hotel_Monceau_Wagram',
    stars: 3,
    pricePerNight: 13500, // Prix indicatif en centimes
    originalPrice: 20000,
    hasPromotion: false,
    propertyType: PropertyType.hotel,
    address: Address(
      street: 'address_street',
      city: 'Paris', // Ajoutez 'Paris' dans les fichiers de traduction
      province: 'Paris',
      country: 'France',
      location:
          Locationn(lat: 48.8794, lng: 2.3005), // Coordonnées approximatives
    ),
    imageUrls: [
      'assets/parish/hotel2/1.jpg',
      'assets/parish/hotel2/2.jpg',
      'assets/parish/hotel2/3.jpg',
      'assets/parish/hotel2/4.jpg',
      'assets/parish/hotel2/5.jpg',
      'assets/parish/hotel2/7.jpg',
    ],
    thumbnailUrl: 'assets/parish/hotel2/1.jpg',
    description: 'description12',
    availableRooms: [
      // Sans guillemets
      RoomType.double,
      RoomType.single,
      RoomType.triple,
    ],
    nearbyPoints: {
      'nearby_Monuments': [
        'Arc_de_Triomphe',
        'Parc_Monceau',
        'Place_Charles_de_Gaulle'
      ],
      'nearby_Restaurants': ['Kurry_Up', 'Jem_XVII', 'En_Cas_dEncas']
    },
    facilities: [
      Facilities.airportShuttle,
      Facilities.nonSmokingRooms,
      Facilities.wifi,
      Facilities.roomService,
      Facilities.parking,
    ],
    hotelRules: {
      'Check_in': '14:00',
      'Check_out': '12:00',
      'Animaux': 'Non_acceptés',
    },
    paymentMethods: ['Carte bancaire', 'Espèces'],
    arrivalDate: DateTime(2025, 07, 15),
    departureDate: DateTime(2025, 07, 22),
    durationDays: 7,
    keywords: [
      'keywords_17ème'.tr(),
      'wifi_gratuit'.tr(),
      'petit_déjeuner_bio'.tr(),
      'navette_aéroport'.tr(),
      'chambres_familiales'.tr()
    ],
  ),
  Hotells(
    id: 'htl3',
    name: 'Hôtel_Elysées_Paris',
    stars: 4,
    pricePerNight: 20000, // 200€ en centimes
    hasPromotion: false,
    propertyType: PropertyType.hotel,
    address: Address(
      street: '1 Rue Brey',
      city: 'Paris',
      province: 'Ile_de_France',
      country: 'France',
      location: Locationn(lat: 48.8745, lng: 2.2960),
    ),
    imageUrls: [
      'assets/parish/hotel3/1.jpg', // Photo principale
      'assets/parish/hotel3/2.jpg', // Chambre
      'assets/parish/hotel3/3.jpg', // Cuisine
      'assets/parish/hotel3/4.jpg', // Salle de bain
      'assets/parish/hotel3/5.jpg',
      'assets/parish/hotel3/6.jpg',
    ],
    thumbnailUrl: 'assets/parish/hotel3/1.jpg',
    description: "description13",
    availableRooms: [
      // Sans guillemets
      RoomType.double,
      RoomType.single,
      RoomType.triple,
    ],
    nearbyPoints: {
      'Monuments': [
        'Arc_de_Triomphe_300m',
        'Palais_des_Congrès_1km',
        'Louvre_metro'
      ],
      'Transport': ['Metro_Charles_de_Gaulle', 'RER_A_CDG_Etoile'],
      'Restaurants': ['Cambridge', 'Zenzan', 'Sarl_les_Etoiles']
    },
    facilities: [
      Facilities.airportShuttle,
      Facilities.nonSmokingRooms,
      Facilities.wifi,
      Facilities.roomService,
      Facilities.parking,
      Facilities.airConditioning,
      Facilities.breakfast
    ],
    hotelRules: {
      'Check-in': '14:00',
      'Check-out': '12:00',
      'Animaux': 'Non acceptés',
    },
    paymentMethods: ['Carte bancaire', 'Espèces'],
    arrivalDate: DateTime(2025, 07, 15),
    departureDate: DateTime(2025, 07, 22),
    durationDays: 7,
    keywords: [
      'paris',
      'champs-élysées',
      'arc de triomphe',
      'wifi gratuit',
      'navette aéroport',
      'station métro proche',
      'chambres familiales'
    ],
  ),
  Hotells(
    id: 'htl4',
    name: 'Apartment_Matignon_St_Honore_by_Studio_Prestige',
    stars: 4, // À ajuster selon la classification réelle
    pricePerNight: 80000, // 180€ en centimes
    hasPromotion: false,
    propertyType: PropertyType.apartment,
    address: Address(
      street: 'street',
      city: 'Paris',
      province: 'Île_de_France',
      country: 'France',
      location:
          Locationn(lat: 48.8723, lng: 2.3087), // Coordonnées approximatives
    ),
    imageUrls: [
      'assets/parish/hotel4/1.jpg', // Photo principale
      'assets/parish/hotel4/2.jpg', // Chambre
      'assets/parish/hotel4/3.jpg', // Cuisine
      'assets/parish/hotel4/4.jpg', // Salle de bain
      'assets/parish/hotel4/5.jpg',
      'assets/parish/hotel4/6.jpg',
      'assets/parish/hotel4/7.jpg',
    ],
    thumbnailUrl: 'assets/parish/hotel4/1.jpg',
    description: "description4",
    availableRooms: [RoomType.family], // Type adapté pour appartement
    nearbyPoints: {
      'Culture': [
        'Musée_Jacquemart_André_400m',
        'Église_Saint_Philippe_du_Roule_350m',
        'Parc_Monceau_900m'
      ],
      'Transport': ['Gare_Saint_Lazare_1km', 'Métro_Miromesnil_5min']
    },
    facilities: [
      Facilities.wifi,
      Facilities.heating,
      Facilities.airConditioning,
      Facilities.kitchen, // Nécessite l'ajout dans l'enum
    ],
    hotelRules: {
      'Check-in': '16:00',
      'Check-out': '10:00',
      'Fumeurs': 'Interdit',
      'Animaux': 'Interdit',
      'Fêtes': 'Interdites',
      'Âge_minimum': '18_ans'
    },
    paymentMethods: ['Carte bancaire', 'Espèces'],
    arrivalDate: DateTime(2025, 07, 15),
    departureDate: DateTime(2025, 07, 22),
    durationDays: 7,
    keywords: [
      'paris',
      'appartement',
      'centre-ville',
      'wifi gratuit',
      'climatisation',
      'kitchenette',
      'matignon st honore'
    ],
  ),
  Hotells(
    id: 'htl5',
    name: 'Résidence_Avalon',
    stars: 3,
    pricePerNight: 95000, // 95€ en centimes
    hasPromotion: false,
    propertyType: PropertyType.apartment,
    address: Address(
      street: 'street_avalon',
      city: 'Paris',
      province: 'Paris',
      country: 'France',
      location: Locationn(lat: 48.8800, lng: 2.3553), // Proche Gare du Nord
    ),
    imageUrls: [
      'assets/parish/hotel5/1.jpg',
      'assets/parish/hotel5/2.jpg',
      'assets/parish/hotel5/3.jpg',
      'assets/parish/hotel5/4.jpg',
      'assets/parish/hotel5/5.jpg',
      'assets/parish/hotel5/6.jpg',
    ],
    thumbnailUrl: 'assets/parish/hotel5/1.jpg',
    description: "description_htl5",
    availableRooms: [
      RoomType.family,
      RoomType.suite, // Pour les appartements
      RoomType.double
    ],
    nearbyPoints: {
      'Monuments': [
        'Gare_du_Nord_(5min_à_pied)',
        'Sacré-Cœur_(15min_à_pied)',
        'Galeries_Lafayette_(accès_direct_métro)'
      ],
      'Transport': ['Métro_Poissonnière_(550m)', 'RER_B_(2min)_-_CDG_Connecté']
    },
    facilities: [
      Facilities.nonSmokingRooms,
      Facilities.wifi,
      Facilities.frontDesk24h,
      Facilities.heating,
      Facilities.luggageStorage,
      Facilities.kitchen
    ],
    hotelRules: {
      'Check-in': '15:00 - 00:00',
      'Check-out': '12:00',
      'Animaux': 'Sur_demande_(supplément)',
      'Fêtes': 'Interdites',
      'Couvre_feu': '23h-8h',
      'Âge_minimum': '18 ans'
    },
    paymentMethods: ['Carte bancaire', 'Espèces'],
    arrivalDate: DateTime(2025, 07, 15),
    departureDate: DateTime(2025, 07, 22),
    durationDays: 7,
    keywords: [
      'paris',
      'gare du nord',
      'appartement',
      'studio',
      'wifi gratuit',
      'réception 24/24',
      'résidence avalon'
    ],
  ),
  Hotells(
    id: 'htl6',
    name: 'PARIS_AUTHENTIC_HOUSE_-_Villa_1920',
    stars: 4,
    pricePerNight: 30000, // 3000€/nuit en centimes
    hasPromotion: false,
    propertyType: PropertyType.villa,
    address: Address(
      street: 'street_authentic_villa',
      city: 'Ivry-sur-Seine',
      province: 'Île_de_France',
      country: 'France',
      location:
          Locationn(lat: 48.8146, lng: 2.3870), // Coordonnées Ivry-sur-Seine
    ),
    imageUrls: [
      'assets/parish/hotel6/1.jpg', // Vue extérieure
      'assets/parish/hotel6/2.jpg', // Salon vintage
      'assets/parish/hotel6/3.jpg', // Jardin
      'assets/parish/hotel6/4.JPG', // Terrasse
      'assets/parish/hotel6/5.jpg', // Cuisine équipée
      'assets/parish/hotel6/6.jpg',
    ],
    thumbnailUrl: 'assets/parish/hotel6/1.jpg',
    description: "description_htl6",
    availableRooms: [RoomType.family], // Capacité groupe
    nearbyPoints: {
      'Culture': [
        'Sainte-Chapelle_(6km)',
        'Jardin_du_Luxembourg_(7km)',
        'Métro_ligne_7_(accès_direct)'
      ],
      'Nature': ['Parc_de_Choisy_(1km)', 'Jardin_Berthe_Morisot_(1.3km)']
    },
    facilities: [
      Facilities.garden,
      Facilities.wifi,
      Facilities.nonSmokingRooms,
      Facilities.familyRooms,
      Facilities.parking,
      Facilities.heating,
      Facilities.kitchen,
    ],
    hotelRules: {
      'Check-in': '16:00-00:00',
      'Check-out': '07:00-10:00',
      'Silence': '21h-9h',
      'Animaux': 'Interdit',
      'Fêtes': 'Interdites',
      'Capacité_max': 'Sur_demande'
    },
    paymentMethods: ['Carte bancaire', 'Virement'],
    arrivalDate: DateTime(2025, 07, 15),
    departureDate: DateTime(2025, 07, 22),
    durationDays: 7,
    keywords: [
      'villa',
      'historique',
      'jardin',
      'terrasse',
      'groupe',
      'station électrique',
      'métro ligne 7'
    ],
  ),
  Hotells(
    id: 'htl7',
    name: 'Room_S_-_Louvre_Museum_(Shared_Bathroom)',
    stars: 3, // Classement typique pour une chambre partagée
    pricePerNight: 30000, // 45€ en centimes
    hasPromotion: false,
    propertyType: PropertyType.vacationHome,
    address: Address(
      street: 'street_louvre_room',
      city: 'Paris',
      province: 'Paris',
      country: 'France',
      location: Locationn(lat: 48.8590, lng: 2.3390), // Proche entrée Louvre
    ),
    imageUrls: [
      'assets/parish/hotel7/1.jpg', // Chambre
      'assets/parish/hotel7/2.jpg', // Salle de bain partagée
      'assets/parish/hotel7/3.jpg',
      'assets/parish/hotel7/4.jpg',
      'assets/parish/hotel7/5.jpg', // Espace commun
    ],
    thumbnailUrl: 'assets/parish/hotel7/1.jpg',
    description: 'description_htl7',
    availableRooms: [RoomType.single],
    nearbyPoints: {
      'Culture': [
        'Musée_du_Louvre_(5min_à_pied)',
        'Centre_Pompidou_(1km)',
        'Notre-Dame_(18min_à_pied)'
      ],
      'Loisirs': ['Patinoire_saisonnière', 'Location_de_bateaux']
    },
    facilities: [
      Facilities.wifi,
      Facilities.heating,
      Facilities.luggageStorage
    ],
    hotelRules: {
      'Check-in': '16:00-00:00',
      'Check-out': '00:00-11:00',
      'Silence': '22h-9h',
      'Salle_de_bain': 'Partagée_avec_hôte'
    },
    paymentMethods: ['Carte bancaire', 'Espèces'],
    arrivalDate: DateTime(2025, 07, 15),
    departureDate: DateTime(2025, 07, 22),
    durationDays: 7,
    keywords: [
      'paris',
      'louvre',
      'chambre chez l\'habitant',
      'salle de bain partagée',
      'centre-ville',
      'wifi gratuit',
      'budget'
    ],
  ),
  Hotells(
    id: 'htl11',
    name: 'Catalonia_Park_Putxet',
    stars: 4,
    pricePerNight: 24000, // 145€ en centimes
    hasPromotion: false,
    propertyType: PropertyType.hotel,
    address: Address(
      street: 'street_catalonia_park_putxet',
      city: 'Barcelone',
      province: 'Barcelone-Sarrià-Sant Gervasi',
      country: 'Espagne',
      location:
          Locationn(lat: 41.4115, lng: 2.1450), // Coordonnées approximatives
    ),
    imageUrls: [
      'assets/spain/barcelone/hotel11/1.jpg',
      'assets/spain/barcelone/hotel11/2.jpg',
      'assets/spain/barcelone/hotel11/3.jpg',
      'assets/spain/barcelone/hotel11/4.jpg',
      'assets/spain/barcelone/hotel11/5.jpg',
    ],
    thumbnailUrl: 'assets/spain/barcelone/hotel11/1.jpg',
    description: 'description_htl11',
    availableRooms: [RoomType.family, RoomType.double, RoomType.suite],
    nearbyPoints: {
      'Culture': [
        'Park_Güell_(600m)',
        'Casa_Vicens_(950m)',
        'Métro_Lesseps_(600m)'
      ],
      'Loisirs': [
        'Zone_gastronomique_Gràcia_(15min)',
        'Jardines_de_Mercè_Rodoreda_(650m)'
      ]
    },
    facilities: [
      Facilities.pool,
      Facilities.wifi,
      Facilities.familyRooms,
      Facilities.nonSmokingRooms,
      Facilities.frontDesk24h,
      Facilities.heating,
      Facilities.roomService,
      Facilities.breakfast,
      Facilities.petsAllowed
    ],
    hotelRules: {
      'Check-in': '15:00',
      'Check-out': '12:00',
      'Animaux': 'Sur_demande',
      'Âge_minimum': '18_ans',
    },
    paymentMethods: ['Carte bancaire', 'Espèces'],
    arrivalDate: DateTime(2025, 8, 15),
    departureDate: DateTime(2025, 8, 22),
    durationDays: 7,
    keywords: [
      'barcelone',
      'espagne',
      'piscine',
      'vue panoramique',
      'gaudi',
      'wifi gratuit',
      'terrasse'
    ],
  ),
  Hotells(
    id: 'htl12',
    name: 'Vincci_Maritimo',
    stars: 4,
    pricePerNight: 24000, // Prix APRÈS réduction (145€ -> 14500 centimes)
    hasPromotion: true, // Activation de la promotion
    originalPrice: 28235, // Prix AVANT réduction (≈169.41€)
    discountPercentage: 15, // 15% de réduction
    propertyType: PropertyType.hotel,
    address: Address(
      street: 'Llull_340',
      city: 'Barcelone',
      province: 'Sant_Martí',
      country: 'Espagne',
      location: Locationn(lat: 41.4075, lng: 2.2160), // Proche plage Mar Bella
    ),
    imageUrls: [
      'assets/spain/barcelone/hotel12/1.jpg', // Chambre moderne
      'assets/spain/barcelone/hotel12/2.jpg', // Jardin zen
      'assets/spain/barcelone/hotel12/3.jpg', // Restaurant
      'assets/spain/barcelone/hotel12/4.jpg', // Terrasse
      'assets/spain/barcelone/hotel12/5.jpg',
      'assets/spain/barcelone/hotel12/6.jpg', // Plage proche
    ],
    thumbnailUrl: 'assets/spain/barcelone/hotel12/1.jpg',
    description: 'Hôtel_design_à_500m_de_la_plage',
    availableRooms: [RoomType.family, RoomType.double, RoomType.suite],
    nearbyPoints: {
      'Nature': [
        'Plage_Mar_Bella_500m',
        'Parc_Diagonal_Mar_10min',
        'Jardin_zen_sur_place'
      ],
      'Transport': ['Métro_Selva_de_Mar_2min', 'CCIB_10min'],
      'Restaurants': ['Restaurant_Sol_150m', 'Los_Toneles_200m']
    },
    facilities: [
      Facilities.familyRooms,
      Facilities.parking,
      Facilities.nonSmokingRooms,
      Facilities.wifi,
      Facilities.restaurant,
      Facilities.roomService,
      Facilities.garden,
    ],
    hotelRules: {
      'Check_in': '15:00',
      'Check_out': '12:00',
      'Animaux': 'Acceptés_supplément',
    },
    paymentMethods: ['Carte bancaire', 'Espèces'],
    arrivalDate: DateTime(2025, 8, 15),
    departureDate: DateTime(2025, 8, 22),
    durationDays: 7,
    keywords: [
      'barcelone',
      'plage',
      'jardin zen',
      'restaurant méditerranéen',
      'métro',
      'design',
      'vincci maritimo'
    ],
  ),
  Hotells(
    id: 'htl13',
    name: 'Paseo_de_Gracia_Apartments',
    stars: 4,
    pricePerNight: 35000, // 175€ en centimes
    hasPromotion: false,
    propertyType: PropertyType.apartment,
    address: Address(
      street: 'street_paseo_de_gracia_apartments',
      city: 'Barcelone',
      province: 'L\'Eixample',
      country: 'Espagne',
      location: Locationn(lat: 41.3915, lng: 2.1650), // Proche Casa Batlló
    ),
    imageUrls: [
      'assets/spain/barcelone/hotel13/1.jpg', // Appartement vue intérieure
      'assets/spain/barcelone/hotel13/2.jpg', // Balcon urbain
      'assets/spain/barcelone/hotel13/3.jpg', // Cuisine équipée
      'assets/spain/barcelone/hotel13/4.jpg', // Salon avec canapé-lit
      'assets/spain/barcelone/hotel13/5.jpg', // Vue sur Passeig de Gràcia
    ],
    thumbnailUrl: 'assets/spain/barcelone/hotel13/1.jpg',
    description: 'description_htl13',
    availableRooms: [RoomType.family, RoomType.double],
    nearbyPoints: {
      'Culture': [
        'Casa_Lleó_Morera_(400m)',
        'Casa_Calvet_(400m)',
        'Passeig_de_Gràcia_(sur_place)'
      ],
      'Restaurants': ['Tapas_&_Beer_(10m)', 'Sabor_Sichuan_(50m)']
    },
    facilities: [
      Facilities.wifi,
      Facilities.airConditioning,
      Facilities.kitchen,
      Facilities.familyRooms,
      Facilities.parking,
      Facilities.nonSmokingRooms,
      Facilities.heating
    ],
    hotelRules: {
      'Check-in': '14:00-21:00',
      'Check-out': '06:30-11:00',
      'Balcon': 'Disponible selon appartement',
    },
    paymentMethods: ['Carte bancaire', 'Espèces'],
    arrivalDate: DateTime(2025, 8, 15),
    departureDate: DateTime(2025, 8, 22),
    durationDays: 7,
    keywords: [
      'barcelone',
      'gaudi',
      'appartement',
      'centre-ville',
      'cuisine équipée',
      'terrasse',
      'passeig de gracia'
    ],
  ),
  Hotells(
    id: 'htl14',
    name: 'hotel_name_htl14',
    stars: 4,
    pricePerNight: 36000, // 160€ en centimes
    hasPromotion: false,
    propertyType: PropertyType.apartment,
    address: Address(
      street: 'street_oasis_apartments',
      city: 'Barcelone',
      province: 'L\'Eixample',
      country: 'Espagne',
      location: Locationn(lat: 41.3874, lng: 2.1686), // Centre-ville Barcelone
    ),
    imageUrls: [
      'assets/spain/barcelone/hotel14/1.jpg', // Studio moderne
      'assets/spain/barcelone/hotel14/2.jpg', // Vue sur la ville
      'assets/spain/barcelone/hotel14/3.jpg', // Cuisine équipée
      'assets/spain/barcelone/hotel14/4.jpg', // Salle de bains privative
      'assets/spain/barcelone/hotel14/5.jpg',
      'assets/spain/barcelone/hotel14/6.jpg', // Espace détente
    ],
    thumbnailUrl: 'assets/spain/barcelone/hotel14/1.jpg',
    description: 'description_htl14a',
    availableRooms: [RoomType.single, RoomType.family],
    nearbyPoints: {
      'Culture': [
        'nearby_palais_musique',
        'nearby_casa_batllo',
        'nearby_metro_urquinaona'
      ],
      'Commerces': ['nearby_rambla_catalunya', 'nearby_boutiques_passeig']
    },
    facilities: [
      Facilities.wifi,
      Facilities.airConditioning,
      Facilities.kitchen,
      Facilities.tv,
      Facilities.heating,
    ],
    hotelRules: {
      'Check-in': '15:00-23:00',
      'Check-out': '00:00-11:00',
      'rule_silence': '20h-9h',
      'rule_equipements"': 'rule_equipements_value'
    },
    paymentMethods: ['Carte bancaire', 'Espèces'],
    arrivalDate: DateTime(2025, 8, 15),
    departureDate: DateTime(2025, 8, 22),
    durationDays: 7,
    keywords: [
      'barcelone',
      'centre-ville',
      'appartement neuf',
      'machine à café',
      'lave-linge',
      'métro',
      'oasis apartments'
    ],
  ),
  Hotells(
    id: 'htl15',
    name: 'hotel_name_htl15',
    stars: 4,
    pricePerNight: 32000, // 180€ en centimes
    hasPromotion: false,
    propertyType: PropertyType.apartment,
    address: Address(
      street: 'street_barcelona_republica',
      city: 'Barcelone',
      province: 'Sant Martí',
      country: 'Espagne',
      location: Locationn(lat: 41.4025, lng: 2.1960), // Proche métro Llacuna
    ),
    imageUrls: [
      'assets/spain/barcelone/hotel15/1.jpg', // Loft style brique
      'assets/spain/barcelone/hotel15/2.jpg', // Piscine rooftop
      'assets/spain/barcelone/hotel15/3.jpg', // Cuisine équipée
      'assets/spain/barcelone/hotel15/4.jpg', // Terrasse urbaine
      'assets/spain/barcelone/hotel15/5.jpg',
      'assets/spain/barcelone/hotel15/6.jpg', // Service conciergerie
    ],
    thumbnailUrl: 'assets/spain/barcelone/hotel15/1.jpg',
    description: 'description_htl15',
    availableRooms: [RoomType.family, RoomType.single, RoomType.suite],
    nearbyPoints: {
      'Loisirs': ['nearby_tour_agbar', 'nearby_glories', 'nearby_plage'],
      'Culture': ['nearby_musee_egyptien', 'nearby_parc_poblenou']
    },
    facilities: [
      Facilities.pool,
      Facilities.wifi,
      Facilities.familyRooms,
      Facilities.parking,
      Facilities.nonSmokingRooms,
      Facilities.frontDesk24h,
      Facilities.airConditioning,
      Facilities.heating,
      Facilities.kitchen,
    ],
    hotelRules: {
      'Check-in': '15:00',
      'Check-out': '11:00',
      'rule_bonus': 'rule_bonus_value',
      'rule_service': 'rule_service_value'
    },
    paymentMethods: ['Carte bancaire', 'Espèces'],
    arrivalDate: DateTime(2025, 8, 15),
    departureDate: DateTime(2025, 8, 22),
    durationDays: 7,
    keywords: [
      'barcelone',
      'loft',
      'piscine rooftop',
      'métro',
      'plage',
      'shopping',
      'apartment republica'
    ],
  ),
  Hotells(
    id: 'htl16',
    name: 'hotel_name_htl16',
    stars: 4,
    pricePerNight: 130000, // 130€ en centimes
    hasPromotion: false,
    propertyType: PropertyType.hotel,
    address: Address(
      street: 'street_derby"',
      city: 'Barcelone',
      province: 'Les Corts',
      country: 'Espagne',
      location: Locationn(lat: 41.3840, lng: 2.1315), // Proche Camp Nou
    ),
    imageUrls: [
      'assets/spain/barcelone/hotel16/1.jpg', // Collection d'art catalan
      'assets/spain/barcelone/hotel16/2.jpg', // Chambre avec parquet
      'assets/spain/barcelone/hotel16/3.jpg', // Pizzeria Santa Napoli
      'assets/spain/barcelone/hotel16/4.jpg', // Bar Lima Bruja
      'assets/spain/barcelone/hotel16/5.jpg',
      'assets/spain/barcelone/hotel16/6.jpg', // Accès piscine Gran Derby
    ],
    thumbnailUrl: 'assets/spain/barcelone/hotel16/1.jpg',
    description: 'description_htl16',
    availableRooms: [RoomType.double, RoomType.family, RoomType.suite],
    nearbyPoints: {
      'Sport': ['nearby_camp_nou', 'nearby_gran_derby'],
      'Art': ['nearby_collection_miro', 'nearby_fira']
    },
    facilities: [
      Facilities.pool,
      Facilities.restaurant,
      Facilities.wifi,
      Facilities.nonSmokingRooms,
      Facilities.parking,
      Facilities.frontDesk24h,
      Facilities.roomService,
      Facilities.airConditioning
    ],
    hotelRules: {
      'Check-in': '14:00-22:00',
      'Check-out': '08:00-12:00',
      'rule_installations': 'rule_installations_value',
      'rule_art': 'rule_art_value'
    },
    paymentMethods: ['Carte bancaire', 'Espèces'],
    arrivalDate: DateTime(2025, 8, 15),
    departureDate: DateTime(2025, 8, 22),
    durationDays: 7,
    keywords: [
      'barcelone',
      'camp nou',
      'art catalan',
      'pizzeria',
      'bar péruvien',
      'complexe sportif',
      'hotel derby'
    ],
  ),
  Hotells(
    id: 'htl17',
    name: 'hotel_name_htl17',
    stars: 3,
    pricePerNight: 110000, // 110€ en centimes
    hasPromotion: false,
    propertyType: PropertyType.villa,
    address: Address(
      street: 'street_alcam',
      city: 'Barcelone',
      province: 'Les Corts',
      country: 'Espagne',
      location: Locationn(lat: 41.3806, lng: 2.1228), // Proche Camp Nou
    ),
    imageUrls: [
      'assets/spain/barcelone/hotel17/1.jpg', // Extérieur villa
      'assets/spain/barcelone/hotel17/2.jpg', // Salon spacieux
      'assets/spain/barcelone/hotel17/3.jpg', // Cuisine équipée
      'assets/spain/barcelone/hotel17/4.jpg', // Chambre double
      'assets/spain/barcelone/hotel17/5.jpg',
      'assets/spain/barcelone/hotel17/6.jpg', // Jardin privatif
    ],
    thumbnailUrl: 'assets/spain/barcelone/hotel17/1.jpg',
    description: 'description_htl17',
    availableRooms: [RoomType.family],
    nearbyPoints: {
      'Foot': ['nearby_camp_nou', 'nearby_fcb'],
      'Ville': ['nearby_fontaine', 'nearby_place_espagne']
    },
    facilities: [
      Facilities.wifi,
      Facilities.airConditioning,
      Facilities.parking,
      Facilities.kitchen,
      Facilities.luggageStorage,
      Facilities.garden
    ],
    hotelRules: {
      'Check-in': '16:00',
      'Check-out': '12:00',
      'rule_parking': '15€/jour',
      'rule_animaux': 'rule_animaux_value',
      'rule_capacite': 'rule_capacite_value'
    },
    paymentMethods: ['Carte bancaire', 'Espèces'],
    arrivalDate: DateTime(2025, 8, 15),
    departureDate: DateTime(2025, 8, 22),
    durationDays: 7,
    keywords: [
      'barcelone',
      'camp nou',
      'villa',
      'jardin',
      'famille',
      'football',
      'alcam futbol'
    ],
  ),
  Hotells(
    id: 'htl18',
    name: 'hotel_name_htl18',
    stars: 4,
    pricePerNight: 150000, // 150€ en centimes
    hasPromotion: false,
    propertyType: PropertyType.vacationHome,
    address: Address(
      street: 'street_bertran',
      city: 'Barcelone',
      province: 'Sarrià-Sant Gervasi',
      country: 'Espagne',
      location: Locationn(
          lat: 41.4167, lng: 2.1333), // Zone résidentielle haut de gamme
    ),
    imageUrls: [
      'assets/spain/barcelone/hotel18/1.jpg', // Piscine extérieure
      'assets/spain/barcelone/hotel18/2.jpg', // Appartement moderne
      'assets/spain/barcelone/hotel18/3.jpg', // Salle de sport
      'assets/spain/barcelone/hotel18/4.jpg', // Kitchenette équipée
      'assets/spain/barcelone/hotel18/5.jpg',
      'assets/spain/barcelone/hotel18/6.jpg', // Terrasse commune
    ],
    thumbnailUrl: 'assets/spain/barcelone/hotel18/1.jpg',
    description: 'description_htl18',
    availableRooms: [RoomType.family, RoomType.single, RoomType.suite],
    nearbyPoints: {
      'Nature': ['nearby_tamarita', 'nearby_collserola'],
      'Restaurants': ['nearby_bells_coffee', 'nearby_luciano']
    },
    facilities: [
      Facilities.pool,
      Facilities.wifi,
      Facilities.kitchen,
      Facilities.parking,
      Facilities.nonSmokingRooms,
      Facilities.frontDesk24h,
      Facilities.airConditioning,
      Facilities.heating
    ],
    hotelRules: {
      'Check-in': '14:00-00:00',
      'Check-out': '05:00-12:00',
      'rule_equipements': 'rule_equipements_value"',
      'rule_animaux': 'rule_animaux_value'
    },
    paymentMethods: ['Carte bancaire', 'Espèces'],
    arrivalDate: DateTime(2025, 8, 15),
    departureDate: DateTime(2025, 8, 22),
    durationDays: 7,
    keywords: [
      'barcelone',
      'aparthotel',
      'tibidabo',
      'piscine',
      'salle de sport',
      'transport',
      'bertran'
    ],
  ),
  Hotells(
    id: 'htl21',
    name: 'hotel_name_htl21',
    stars: 4,
    pricePerNight: 34000, // Prix après réduction (40.000 - 15%)
    originalPrice: 40000, // Prix avant réduction
    hasPromotion: true,
    discountPercentage: 15,
    propertyType: PropertyType.hotel,
    address: Address(
      street: 'street_ain_benian',
      city: 'Alger',
      province: 'Alger',
      country: 'Algérie',
      location:
          Locationn(lat: 36.7538, lng: 3.0588), // Coordonnées approximatives
    ),
    imageUrls: [
      'assets/alger/hotel12/1.jpg',
      'assets/alger/hotel12/2.jpg',
      'assets/alger/hotel12/3.jpg',
      'assets/alger/hotel12/4.jpg',
      'assets/alger/hotel12/5.jpg',
      'assets/alger/hotel12/6.jpg',
    ],
    thumbnailUrl: 'assets/alger/hotel12/1.jpg',
    description: 'description_htl21',
    availableRooms: [
      RoomType.double,
      RoomType.single,
      RoomType.family,
      RoomType.suite,
    ],
    nearbyPoints: {
      'Restaurants': ['nearby_cafe_1', 'nearby_cafe_2', 'nearby_cafe_3'],
      'Plages': [
        'nearby_plage_djamila',
        'nearby_plage_bahdja',
        'nearby_plage_dunes'
      ]
    },
    facilities: [
      Facilities.pool,
      Facilities.wifi,
      Facilities.restaurant,
      Facilities.familyRooms,
      Facilities.nonSmokingRooms,
      Facilities.parking,
      Facilities.roomService,
      Facilities.breakfast,
    ],
    hotelRules: {
      'Check-in': '11:30 - 12:00',
      'Check-out': '09:00 - 10:00',
      'rule_annulation': 'rule_annulation_value',
      'rule_langues': 'rule_langues_value',
    },
    paymentMethods: ['Carte bancaire', 'Espèces'],
    arrivalDate: DateTime(2025, 06, 15),
    departureDate: DateTime(2025, 06, 22),
    durationDays: 7,
    keywords: [
      'alger',
      'algérie',
      'hammamet',
      'piscine',
      'plage',
      'vue mer',
      'petit-déjeuner',
      'restaurant',
      'parking gratuit',
      'wifi gratuit',
    ],
  ),
  Hotells(
    id: 'htl22',
    name: 'hotel_name_htl22',
    stars: 3,
    pricePerNight:
        22000, // Prix en centimes (22000 = 2200 DZD ou 220€ selon votre devise)
    hasPromotion: false,
    propertyType: PropertyType.hotel,
    address: Address(
      street: 'street_mikideche',
      city: 'Alger',
      province: 'Alger',
      country: 'Algérie',
      location:
          Locationn(lat: 36.7754, lng: 3.0589), // Coordonnées approximatives
    ),
    imageUrls: [
      'assets/alger/hotel22/1.jpg', // Photo principale
      'assets/alger/hotel22/2.jpg', // Chambre
      'assets/alger/hotel22/3.jpg', // Restaurant
      'assets/alger/hotel22/4.jpg', // Bar
      'assets/alger/hotel22/5.jpg', // Salle de bain
      'assets/alger/hotel22/6.jpg', // Petit-déjeuner
    ],
    thumbnailUrl: 'assets/alger/hotel22/1.jpg',
    description: 'description_htl22',
    availableRooms: [
      RoomType.single,
      RoomType.double,
    ],
    nearbyPoints: {
      'Loisirs': ['nearby_kids_park', 'nearby_fatma_nsoumer'],
      'Restaurants': [
        'nearby_cafe_11',
        'nearby_tea_timimoun',
        'nearby_cafeteria_andalous'
      ]
    },
    facilities: [
      Facilities.restaurant,
      Facilities.wifi,
      Facilities.nonSmokingRooms,
      Facilities.parking,
      Facilities.frontDesk24h,
      Facilities.airConditioning,
    ],
    hotelRules: {
      'Check-in': '12:00',
      'Check-out': '11:00',
      'Animaux': 'Non admis',
      'rule_petit_dejeuner': 'rule_petit_dejeuner_value',
    },
    paymentMethods: ['Carte bancaire', 'Espèces'],
    arrivalDate: DateTime(2025, 06, 15),
    departureDate: DateTime(2025, 06, 22),
    durationDays: 7,
    keywords: [
      'alger',
      'algérie',
      'audin',
      'wifi gratuit',
      'parking gratuit',
      'bar',
      'restaurant',
      'climatisation',
      'petit-déjeuner',
      'centre-ville',
    ],
  ),
  Hotells(
    id: 'htl23',
    name: 'hotel_name_htl23',
    stars: 4,
    pricePerNight:
        45000, // Prix en centimes (45000 = 4500 DZD ou 450€ selon votre devise)
    hasPromotion: false,
    propertyType: PropertyType.hotel,
    address: Address(
      street: 'street_djenane_boursas',
      city: 'Alger',
      province: 'Alger',
      country: 'Algérie',
      location:
          Locationn(lat: 36.7525, lng: 3.0278), // Coordonnées approximatives
    ),
    imageUrls: [
      'assets/alger/hotel23/1.jpg', // Vue extérieure
      'assets/alger/hotel23/2.jpg', // Piscine intérieure
      'assets/alger/hotel23/3.jpg', // Spa
      'assets/alger/hotel23/4.jpg', // Chambre
      'assets/alger/hotel23/5.jpg', // Restaurant
      'assets/alger/hotel23/6.jpg', // Salle de bain
      'assets/alger/hotel23/7.jpg', // Hammam
    ],
    thumbnailUrl: 'assets/alger/hotel23/1.jpg',
    description: 'description_htl23',
    availableRooms: [
      RoomType.double,
      RoomType.suite,
      RoomType.family,
    ],
    nearbyPoints: {
      'Loisirs': ['nearbyy_kids_park'],
      'Restaurants': [
        'nearby_coffee_box',
        'nearby_signature_restaurant',
        'nearby_cafe_salam'
      ]
    },
    facilities: [
      Facilities.pool,
      Facilities.spa,
      Facilities.airportShuttle,
      Facilities.familyRooms,
      Facilities.wifi,
      Facilities.restaurant,
      Facilities.roomService,
      Facilities.airConditioning,
    ],
    hotelRules: {
      'Check-in': '15:00 - 00:00',
      'Check-out': '12:00 - 13:00',
      'rule_petit_dejeuner': 'rule_petitt_dejeuner_value',
      'rule_spa': 'rule_spa_value',
      'rule_navette': 'rule_navette_value',
    },
    paymentMethods: ['Carte bancaire', 'Espèces'],
    arrivalDate: DateTime(2025, 06, 15),
    departureDate: DateTime(2025, 06, 22),
    durationDays: 7,
    keywords: [
      'alger',
      'hydra',
      'spa',
      'piscine intérieure',
      'hammam',
      'centre de remise en forme',
      'restaurant',
      'bar',
      'navette aéroport',
      'chambres familiales',
      'petit-déjeuner buffet',
    ],
  ),
  Hotells(
    id: 'htl24',
    name: 'hotel_name_htl24',
    stars: 4,
    pricePerNight: 40500, // Prix après réduction de 10% (45000 - 10%)
    originalPrice: 45000, // Prix avant réduction
    hasPromotion: true,
    discountPercentage: 10,
    propertyType: PropertyType.hotel,
    address: Address(
      street: 'street_route_falaises',
      city: 'Oran',
      province: 'Oran',
      country: 'Algérie',
      location:
          Locationn(lat: 35.6997, lng: -0.6333), // Coordonnées approximatives
    ),
    imageUrls: [
      'assets/oran/hotel24/1.jpg', // Vue extérieure
      'assets/oran/hotel24/2.jpg', // Salle de sport
      'assets/oran/hotel24/3.jpg', // Chambre
      'assets/oran/hotel24/4.jpg', // Restaurant
      'assets/oran/hotel24/5.jpg', // Bar
      'assets/oran/hotel24/6.jpg', // Sauna
    ],
    thumbnailUrl: 'assets/oran/hotel24/1.jpg',
    description: 'description_htl24',
    availableRooms: [
      RoomType.double,
      RoomType.suite,
      RoomType.family,
    ],
    nearbyPoints: {
      'Monuments': ['nearby_santa_cruz'],
      'Restaurants': [
        'nearby_bar_rendezvous',
        'nearby_diplomate',
        'nearby_netbox'
      ]
    },
    facilities: [
      Facilities.airportShuttle,
      Facilities.nonSmokingRooms,
      Facilities.roomService,
      Facilities.wifi,
      Facilities.restaurant,
      Facilities.breakfast,
      Facilities.frontDesk24h,
      Facilities.airConditioning,
    ],
    hotelRules: {
      'Check-in': 'rule_checkin_valuee',
      'Check-out': '12:00',
      'rule_enfants': 'rule_enfants_value',
      'rule_lits_bebe': 'rule_lits_bebe_value',
      'rule_navette': 'rule_navette_valuee',
      'rule_pre_enregistrement': 'rule_pre_enregistrement_value',
    },
    paymentMethods: ['Carte bancaire', 'Espèces'],
    arrivalDate: DateTime(2025, 05, 15),
    departureDate: DateTime(2025, 05, 22),
    durationDays: 7,
    keywords: [
      'oran',
      'sheraton',
      '4 étoiles',
      'navette gratuite',
      'sauna',
      'salle de sport',
      'wifi gratuit',
      'restaurant',
      'bar',
      'petit-déjeuner buffet',
      'service 24/24',
    ],
  ),
  Hotells(
    id: 'htl25',
    name: 'hotel_name_htl25',
    stars: 4,
    pricePerNight:
        38000, // Prix standard en centimes (38000 = 3800 DZD ou 380€ selon votre devise)
    hasPromotion: false,
    propertyType: PropertyType.hotel,
    address: Address(
      street: 'street_usto',
      city: 'Oran',
      province: 'Oran',
      country: 'Algérie',
      location:
          Locationn(lat: 35.6965, lng: -0.6229), // Coordonnées approximatives
    ),
    imageUrls: [
      'assets/oran/hotel25/1.jpg', // Vue extérieure
      'assets/oran/hotel25/2.jpg', // Piscine
      'assets/oran/hotel25/3.jpg', // Spa
      'assets/oran/hotel25/4.jpg', // Chambre (vue ville)
      'assets/oran/hotel25/5.jpg', // Restaurant
      'assets/oran/hotel25/6.jpg', // Salle de bain
      'assets/oran/hotel25/7.jpg', // Petit-déjeuner
    ],
    thumbnailUrl: 'assets/oran/hotel25/1.jpg',
    description: 'description_htl25',
    availableRooms: [
      RoomType.double,
      RoomType.family,
      RoomType.suite,
    ],
    nearbyPoints: {
      'Monuments': ['nearby_santa_cruz_8km'],
      'Restaurants': ['nearby_mistral', 'nearby_lebanon', 'nearby_sable_dor'],
    },
    facilities: [
      Facilities.pool,
      Facilities.spa,
      Facilities.airportShuttle,
      Facilities.familyRooms,
      Facilities.nonSmokingRooms,
      Facilities.parking,
      Facilities.wifi,
      Facilities.restaurant,
      Facilities.breakfast,
      Facilities.airConditioning,
    ],
    hotelRules: {
      'Check-in': '15:00 - 00:00 ',
      'Check-out': '12:00 - 12:30',
      'rule_langues': 'rule_langues_value',
      'rule_navette': 'rule_navette_valueee',
      'rule_animaux': 'rule_animaux_valueee',
    },
    paymentMethods: ['Carte bancaire', 'Espèces'],
    arrivalDate: DateTime(2025, 05, 15),
    departureDate: DateTime(2025, 05, 22),
    durationDays: 7,
    keywords: [
      'oran',
      'liberté hotels',
      'spa',
      'piscine',
      'vue sur ville',
      'navette gratuite',
      'petit-déjeuner buffet',
      'minibar',
      'wifi gratuit',
      '4 étoiles',
    ],
  ),
  Hotells(
    id: 'htl26',
    name: 'hotel_name_htl26',
    stars: 3,
    pricePerNight: 25000, // Prix en centimes (25000 = 2500 DZD ou ~170€)
    hasPromotion: false,
    propertyType: PropertyType.hotel,
    address: Address(
      street: 'street_66_maktaa',
      city: 'Oran',
      province: 'Oran',
      country: 'Algérie',
      location:
          Locationn(lat: 35.7032, lng: -0.6509), // Coordonnées approximatives
    ),
    imageUrls: [
      'assets/oran/hotel26/1.jpg', // Façade
      'assets/oran/hotel26/2.jpg', // Lobby
      'assets/oran/hotel26/3.jpg', // Chambre
      'assets/oran/hotel26/4.jpg', // Restaurant
      'assets/oran/hotel26/5.jpg', // Terrasse
      'assets/oran/hotel26/6.jpg', // Salon commun
    ],
    thumbnailUrl: 'assets/oran/hotel26/1.jpg',
    description: 'description_htl26',
    availableRooms: [
      RoomType.double,
      RoomType.single,
      RoomType.family,
    ],
    nearbyPoints: {
      'Monuments': ['nearby_santa_cruz'],
      'Commerces': ['nearby_netbox', 'nearby_diplomate', 'nearby_eden']
    },
    facilities: [
      Facilities.airportShuttle,
      Facilities.frontDesk24h,
      Facilities.wifi,
      Facilities.restaurant,
      Facilities.nonSmokingRooms,
      Facilities.parking,
      Facilities.roomService,
      Facilities.luggageStorage,
    ],
    hotelRules: {
      'Check-in': '14:00 - 15:00',
      'Check-out': '12:00 - 12:30',
      'Annulation': 'rule_annulation_value',
      'rule_concierge': 'rule_concierge_value',
      'rule_bagagerie': 'rule_bagagerie_value',
    },
    paymentMethods: ['Carte bancaire', 'Espèces'],
    arrivalDate: DateTime(2025, 07, 15),
    departureDate: DateTime(2025, 07, 22),
    durationDays: 7,
    keywords: [
      'oran',
      'ibiris',
      'centre-ville',
      'wifi gratuit',
      'navette aéroport',
      'parking gratuit',
      'réception 24/24',
      'terrasse',
      'restaurant',
    ],
  ),
];

// Ajoutez cette extension pour mapper les équipements aux icônes
extension FacilitiesIcons on Facilities {
  IconData get icon {
    switch (this) {
      case Facilities.wifi:
        return Icons.wifi;
      case Facilities.tv:
        return Icons.tv;
      case Facilities.parking:
        return Icons.local_parking;
      case Facilities.pool:
        return Icons.pool;
      case Facilities.restaurant:
        return Icons.restaurant;
      case Facilities.spa:
        return Icons.spa;
      case Facilities.airportShuttle:
        return Icons.directions_bus;
      case Facilities.nonSmokingRooms:
        return Icons.smoke_free;
      case Facilities.frontDesk24h:
        return Icons.access_time;
      case Facilities.heating:
        return Icons.thermostat;
      case Facilities.housekeeping:
        return Icons.cleaning_services;
      case Facilities.luggageStorage:
        return Icons.luggage;
      case Facilities.airConditioning:
        return Icons.ac_unit;
      case Facilities.roomService:
        return Icons.room_service;
      case Facilities.familyRooms:
        return Icons.family_restroom;
      case Facilities.breakfast:
        return Icons.free_breakfast;
      case Facilities.kitchen:
        return Icons.kitchen;
      case Facilities.garden:
        return Icons.yard;
      default:
        return Icons.hotel;
    }
  }

  String get name {
    return toString().split('.').last;
  }
}

// Liste des provinces disponibles
List<String> get provincesDisponibles =>
    localHotels.map((h) => h.address.province.trim()).toSet().toList();

// Liste des noms de province normalisés
List<String> get provincesNormalisees =>
    provincesDisponibles.map((p) => p.toLowerCase()).toList();
