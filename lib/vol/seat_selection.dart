import 'package:agencedevoyage/currency_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Seat {
  final int number;
  final bool isOccupied;
  bool isSelected;

  Seat({
    required this.number,
    this.isOccupied = false,
    this.isSelected = false,
  });
}

class SeatSelectionWidget extends ConsumerStatefulWidget {
  final double basePrice;
  final Function(List<int>)? onSeatsSaved;

  const SeatSelectionWidget({
    super.key,
    required this.basePrice,
    this.onSeatsSaved,
  });

  @override
  ConsumerState<SeatSelectionWidget> createState() =>
      SeatSelectionWidgetState();
}

class SeatSelectionWidgetState extends ConsumerState<SeatSelectionWidget> {
  List<Seat> seats = List.generate(
    20,
    (index) => Seat(
      number: index + 1,
      isOccupied: [3, 7, 9, 14].contains(index + 1), // sièges occupés
    ),
  );
  List<int> selectedSeats = []; // Liste des numéros de sièges sélectionnés
  // int? selectedSeat;
  double totalPrice = 0;

  @override
  void initState() {
    super.initState();
    totalPrice = widget.basePrice;
  }

  void _selectSeat(int seatNumber) {
    setState(() {
      final seat = seats.firstWhere((s) => s.number == seatNumber);
      if (!seat.isOccupied) {
        seat.isSelected = !seat.isSelected;
        if (seat.isSelected) {
          selectedSeats.add(seatNumber);
        } else {
          selectedSeats.remove(seatNumber);
        }
        totalPrice = widget.basePrice + (2000 * selectedSeats.length);
        // Appeler onSeatsSaved immédiatement
        widget.onSeatsSaved?.call(selectedSeats);
      }
    });
  }

  // void _resetSelection() {
  //   setState(() {
  //     for (var seat in seats) {
  //       seat.isSelected = false;
  //     }
  //     selectedSeat = null;
  //     totalPrice = widget.basePrice;
  //   });
  // }

  Future<void> _saveSeatToFirestore(WidgetRef ref) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez vous connecter pour enregistrer.')),
      );
      return;
    }

    if (selectedSeats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez_sélectionner_un_siège'.tr())),
      );
      return;
    }

    final currency = ref.read(currencyProvider);
    final formatted =
        ref.read(currencyProvider.notifier).formatPrice(totalPrice);
    final userId = user.uid;

    final seatData = {
      'selectedSeats': selectedSeats, // Enregistrer la liste complète
      'price_dzd': totalPrice,
      'price_display': formatted,
      'currency': currency.currency,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('flight_reservations')
          .add({'seatSelection': seatData});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Siège_enregistré_avec_succès'.tr())),
      );
      if (widget.onSeatsSaved != null) {
        widget.onSeatsSaved!(selectedSeats);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text("'${'Erreur_Lors_De_La_Sélection_du_Siége'.tr()}  : $e")),
      );
    }
    // Navigator.pop(context, selectedSeats);
  }

  Widget _buildSeatBox(Seat seat) {
    Color seatColor;
    if (seat.isOccupied) {
      seatColor = Colors.grey.shade400;
    } else if (seat.isSelected) {
      seatColor = Colors.blueAccent;
    } else {
      seatColor = Colors.white;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.all(4),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: seatColor,
        border: Border.all(color: Colors.blueGrey),
        borderRadius: BorderRadius.circular(8),
        boxShadow: seat.isSelected
            ? [
                BoxShadow(
                  color: Colors.lightBlue.withValues(),
                  blurRadius: 8,
                )
              ]
            : [],
      ),
      child: InkWell(
        onTap: seat.isOccupied ? null : () => _selectSeat(seat.number),
        child: Center(
          child: Text(
            '${seat.number}',
            style: TextStyle(
              fontSize: 12,
              color: seat.isOccupied ? Colors.grey.shade700 : Colors.black,
              fontWeight: seat.isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeatRow(int startIndex) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (startIndex < seats.length) _buildSeatBox(seats[startIndex]),
        const SizedBox(width: 8),
        if (startIndex + 1 < seats.length) _buildSeatBox(seats[startIndex + 1]),
        const SizedBox(width: 24), // Allée centrale
        if (startIndex + 2 < seats.length) _buildSeatBox(seats[startIndex + 2]),
        const SizedBox(width: 8),
        if (startIndex + 3 < seats.length) _buildSeatBox(seats[startIndex + 3]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyNotifier = ref.read(currencyProvider.notifier);
    final seatPricePerUnit = 2000.0;
    final formattedSeatPrice = currencyNotifier.formatPrice(seatPricePerUnit);
    final seatCount = selectedSeats.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text("Sélectionnez_votre_siège".tr(),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),

        // ✅ Utilisation correcte de rangées
        Column(
          children: List.generate((seats.length / 4).ceil(), (rowIndex) {
            int startIndex = rowIndex * 4;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: _buildSeatRow(startIndex),
            );
          }),
        ),

        const SizedBox(height: 20),
        if (seatCount > 0)
          Text(
            '${'+'.tr()} $formattedSeatPrice × $seatCount',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        const SizedBox(height: 15),

        // ElevatedButton.icon(
        //   onPressed: _resetSelection,
        //   icon: const Icon(Icons.refresh, color: Colors.white),
        //   label: Text(
        //     "Réinitialiser".tr(),
        //     style: TextStyle(color: Colors.white),
        //   ),
        //   style: ElevatedButton.styleFrom(
        //       backgroundColor: const Color.fromARGB(156, 255, 64, 64)),
        // ),
        // const SizedBox(height: 10),

        ElevatedButton.icon(
          onPressed: () => _saveSeatToFirestore(ref),
          icon: const Icon(Icons.save, color: Colors.white),
          label: Text(
            "Enregistrer".tr(),
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(250, 102, 200, 106)),
        ),
      ],
    );
  }
}
