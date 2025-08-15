import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agencedevoyage/voyageOrganiser/trip.dart';

class TripNotifier extends StateNotifier<Trip> {
  TripNotifier(super.initialTrip);

  void makeReservation({
    required String hotelName,
    required String roomType,
    required int guests,
  }) {
    // Copie profonde de la liste des hôtels
    final updatedHotels = state.hotels.map((hotel) {
      if (hotel.name == hotelName) {
        final updatedRooms = {...hotel.availableRooms};
        updatedRooms[roomType] = (updatedRooms[roomType] ?? 0) - 1;

        return hotel.copyWith(
          availableRooms: updatedRooms,
        );
      }
      return hotel;
    }).toList();

    // Mise à jour de l'état global
    state = state.copyWith(
      hotels: updatedHotels,
      remainingTickets: state.remainingTickets - guests,
    );
  }
}

// Après (correction)
final tripProvider = StateNotifierProvider.autoDispose<TripNotifier, Trip>(
  (ref) => TripNotifier(Trip.placeholder()), // Valeur par défaut sécurisée
);
