// trips_data.dart
import 'package:agencedevoyage/voyageOrganiser/trip.dart';
import 'package:flutter/material.dart';

List<Trip> getOrganizedTrips() {
  return [
    Trip(
      id: '1',
      departureCity: 'Alger',
      departureDate: DateTime(2025, 6, 13),
      departureTime: TimeOfDay(hour: 8, minute: 30),
      returnDate: DateTime(2025, 6, 27), // Ajout de la date de retour
      destination: 'Istanbul',
      durationDays: 14,
      description: 'description11', // Votre description complète
      photos: ['assets/trip/istanbul1.jpg', 'assets/trip/flagistanbul.jpg'],
      hotels: [
        Hotel(
          id: '1',
          name: 'NL Amsterdam ',
          stars: 3,
          photos: [
            'assets/trip/coverhotelNlamsterdam3.jpg',
            'assets/trip/chambre1.jpg',
            'assets/trip/chambre2.jpg',
            'assets/trip/resto.jpg',
            'assets/trip/sallebain.jpg'
          ],
          address: 'address_oued_el_alenda',
          roomPrices: {
            'Triple': 115000,
            'Double': 117000,
            'Single': 160000,
          },
          availableRooms: {
            'Triple': 5,
            'Double': 3,
            'Single': 2,
          },

          nearbyPlaces: [
            PointOfInterest(
              name: 'Bazar aux épices',
              distance: 3.1,
              icon: Icons.shopping_basket,
            ),
            PointOfInterest(
              name: 'Mosquée Süleymaniye',
              distance: 1.9,
              icon: Icons.account_balance,
            ),
            PointOfInterest(
              name: 'Tour de Galata',
              distance: 3.9,
              icon: Icons.tour,
            ),
            PointOfInterest(
              name: 'Firat Kebap',
              distance: 0.4,
              icon: Icons.restaurant_menu,
            ),
            PointOfInterest(
              name: 'Ali  Usta',
              distance: 0.1,
              icon: Icons.restaurant_menu,
            ),
            PointOfInterest(
              name: 'Banaz Prki',
              distance: 9.0,
              icon: Icons.forest,
            ),
          ],

          services: ['WiFi', 'Restaurant', 'Piscine', 'Ascenseur'],
          location: Location(lat: 41.0082, lng: 28.9784), // Coordonnées réelles
        ),
        // Ajouter d'autres hôtels...
      ],
      extras: [
        ExtraExcursion(
          name: 'Croisière sur le Bosphore',
          adultPrice: 4000,
          childPrice: 2000,
          imageUrl: ['assets/excturq/bosphore.jpg'],
          description:
              'Le 1er jour, profitez d’une croisière magique sur le Bosphore. Départ à 15h. Admirez les palais ottomans, les maisons en bois et les ponts emblématiques d’Istanbul.',
        ),
        ExtraExcursion(
          name: 'Tour de ville en bus panoramique',
          adultPrice: 8500,
          childPrice: 4000,
          imageUrl: ['assets/excturq/buss.jpg'],
          description:
              'Le 2e jour, embarquez à 8h du matin pour un tour de la ville d’Istanbul en bus touristique. Découvrez Sainte-Sophie, le Palais de Topkapi et la place Taksim.',
        ),
        ExtraExcursion(
          name: 'Journée à la Princesse Island',
          adultPrice: 12000,
          childPrice: 6000,
          imageUrl: ['assets/excturq/island.jpg'],
          description:
              'Le 3e jour, départ en bateau vers les îles des Princesses à 9h. Visite guidée, balade en calèche, déjeuner en bord de mer et retour à 17h.',
        ),
      ],

      totalTickets: 50,
      remainingTickets: 3,
      reservationType: 'trip',
    ),

    Trip(
      id: '2',
      departureCity: 'Oran',
      departureDate: DateTime(2025, 10, 10),
      departureTime: TimeOfDay(hour: 8, minute: 30),
      returnDate: DateTime(2025, 10, 24),
      destination: 'Oued El Alenda',
      durationDays: 14,
      description: 'description2',
      photos: ['assets/trip2/complexe.jpg', 'assets/trip2/entre.jpg'],
      hotels: [
        Hotel(
          id: '2',
          name: 'La Gazelle d' 'Or Resort et Spa',
          stars: 4,
          photos: [
            'assets/trip2/chambreini.jpg',
            'assets/trip2/complexe2.jpg',
            'assets/trip2/chambre1.jpg',
            'assets/trip2/chambre2.jpg',
            'assets/trip2/piscine.jpg',
            'assets/trip2/salledebain.jpg'
          ],
          address: 'N16 Route de Touggourt, Oued El Alenda 39069 Algérie',
          roomPrices: {
            'Suite': 85000,
            'Familiale': 110000,
            'Non_smoking': 70000,
            'Fumeurs': 68000,
          },
          availableRooms: {
            'Suite': 2,
            'Familiale': 4,
            'Non_smoking': 6,
            'Fumeurs': 3,
          },
          nearbyPlaces: [
            PointOfInterest(
              name: 'Dunes de sable',
              distance: 0.5,
              icon: Icons.landscape,
            ),
            PointOfInterest(
              name: 'Marché local',
              distance: 2.3,
              icon: Icons.shopping_basket,
            ),
            PointOfInterest(
              name: 'Oasis naturelle',
              distance: 4.7,
              icon: Icons.nature,
            ),
          ],
          services: [
            'Parking gratuit',
            'WiFi',
            'Salle de sport',
            'Piscine',
            'Petit-déjeuner',
            'Location de vélos',
            'Navette aéroport',
            'Climatisation',
            'Balcon privé'
          ],
          location:
              Location(lat: 34.6789, lng: 5.9123), // Coordonnées approximatives
        ),
      ],
      extras: [
        ExtraExcursion(
          name: 'Balade en dromadaire',
          adultPrice: 5000,
          childPrice: 2500,
          imageUrl: ['assets/trip2/balade1.jpg'],
          description:
              'Traversée des dunes au coucher du soleil avec des dromadaires accompagnés de guides locaux. Durée : 2h. Départ quotidien à 17h.',
        ),
        ExtraExcursion(
          name: 'Randonnée en Quad',
          adultPrice: 15000,
          childPrice: 8000,
          imageUrl: ['assets/trip2/quad.jpg'],
          description:
              'Aventure adrenaline dans le désert avec circuits adaptés à tous les niveaux. Equipement de protection fourni. Session matinale à 9h.',
        ),
        ExtraExcursion(
          name: 'Soirée traditionnelle sous Khaima',
          adultPrice: 8000,
          childPrice: 4000,
          imageUrl: ['assets/trip2/khaima.jpg'],
          description:
              'Dîner typique sous tente bédouine avec musique Chaabi en live. Dégustation de thé à la menthe et spectacle folklorique. Début à 19h30.',
        ),
      ],
      totalTickets: 50,
      remainingTickets: 11,
      reservationType: 'trip',
    ),
    // Ajouter d'autres voyages...
  ];
}
