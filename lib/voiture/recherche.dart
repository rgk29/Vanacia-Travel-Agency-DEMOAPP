import 'package:agencedevoyage/voiture/local.dart';
import 'package:agencedevoyage/voiture/resultatvoiture.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Couleurs personnalisées
const Color primaryColor = Color(0xFF2A5C82);
const Color secondaryColor = Color(0xFF3AB795);
const Color accentColor = Color(0xFFFF7F50);
const TextStyle labelStyle = TextStyle(
  fontSize: 16,
  color: Color(0xFF4A4A4A),
  fontWeight: FontWeight.w500,
);

class CarPage extends StatefulWidget {
  const CarPage({super.key});

  @override
  CarPageState createState() => CarPageState();
}

class CarPageState extends State<CarPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();

  List<AirportModel> filteredAirports = [];
  String? pickupLocation;
  String? dropoffLocation;
  DateTime? pickupDate;
  DateTime? returnDate;
  TimeOfDay? pickupTime;

  String formatDate(DateTime? date) {
    return date != null
        ? DateFormat('dd/MM/yyyy').format(date)
        : 'Sélectionner'.tr();
  }

  void _searchAirports(String query, TextEditingController controller) {
    setState(() {
      filteredAirports = airportList.where((airport) {
        final lowerQuery = query.toLowerCase().trim();
        return airport.name.toLowerCase().contains(lowerQuery) ||
            airport.code.toLowerCase().contains(lowerQuery) ||
            airport.city.toLowerCase().contains(lowerQuery) ||
            airport.country.toLowerCase().contains(lowerQuery) ||
            airport.keywords
                .any((keyword) => keyword.toLowerCase().contains(lowerQuery));
      }).toList();
    });
  }

  Future<void> _selectDate({required bool isDeparture}) async {
    DateTime initialDate = isDeparture
        ? pickupDate ?? DateTime.now()
        : (returnDate ?? (pickupDate ?? DateTime.now()));

    DateTime firstDate =
        isDeparture ? DateTime.now() : (pickupDate ?? DateTime.now());
    DateTime lastDate = DateTime.now().add(const Duration(days: 365));

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              surface: Colors.white,
            ),
            dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isDeparture) {
          pickupDate = picked;
          if (returnDate != null && returnDate!.isBefore(pickupDate!)) {
            returnDate = pickupDate;
          }
        } else {
          returnDate = picked;
        }
      });
    }
  }

  String formatTime(TimeOfDay? time) {
    return time != null ? time.format(context) : 'Sélectionner'.tr();
  }

  Future<void> _selectTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (selected != null) {
      setState(() {
        pickupTime = selected;
      });
    }
  }

  void _searchCars() async {
    if (_formKey.currentState!.validate()) {
      if (pickupLocation == null || dropoffLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Veuillez_sélectionner_des_lieux_valides".tr())),
        );
        return;
      }

      if (pickupDate == null || returnDate == null || pickupTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Veuillez_sélectionner_les_dates_et_heures".tr())),
        );
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Veuillez_vous_connecter".tr())),
        );
        return;
      }

      final bookingData = {
        'userId': user.uid,
        'userEmail': user.email,
        'pickupLocation': pickupLocation,
        'returnLocation': dropoffLocation,
        'pickupDateTime': DateTime(
          pickupDate!.year,
          pickupDate!.month,
          pickupDate!.day,
          pickupTime!.hour,
          pickupTime!.minute,
        ).toIso8601String(),
        'returnDateTime': returnDate!.toIso8601String(),
        'timestamp': FieldValue.serverTimestamp(),
      };

      try {
        final testDate = DateTime.parse(pickupDate!.toIso8601String());
        final testTime =
            TimeOfDay(hour: pickupTime!.hour, minute: pickupTime!.minute);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Format_de_date_heure_invalide".tr())),
        );
        return;
      }

      try {
        await FirebaseFirestore.instance
            .collection('car_searches')
            .add(bookingData);
        final rentalDays = returnDate!.difference(pickupDate!).inDays;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CarSearchResultsPage(
              carList: carList,
              rentalDays: rentalDays,
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: ${e.toString()}")),
        );
      }
    }
  }

  Widget _buildAirportSuggestions(TextEditingController controller) {
    return filteredAirports.isEmpty
        ? const SizedBox.shrink()
        : Column(
            children: filteredAirports
                .map((airport) => ListTile(
                      title: Text(airport.name),
                      subtitle: Text(
                          "${airport.city}, ${airport.country} (${airport.code})"),
                      onTap: () {
                        setState(() {
                          if (controller == _pickupController) {
                            pickupLocation = airport.name;
                          } else {
                            dropoffLocation = airport.name;
                          }
                          controller.text = airport.name;
                          filteredAirports.clear();
                        });
                      },
                    ))
                .toList(),
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Location_de_voiture".tr(),
            style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                _buildLocationField(_pickupController,
                    "Lieu_de_prise_en_charge".tr(), Icons.location_on),
                _buildAirportSuggestions(_pickupController),
                const SizedBox(height: 20),
                _buildLocationField(_dropoffController,
                    "Lieu_de_restitution".tr(), Icons.location_on_outlined),
                _buildAirportSuggestions(_dropoffController),
                const SizedBox(height: 25),
                _buildDateTile("Date_de_location".tr(), pickupDate, true),
                const SizedBox(height: 15),
                _buildDateTile("Date_de_retour".tr(), returnDate, false),
                const SizedBox(height: 15),
                _buildTimeTile(),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _searchCars,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text("Rechercher".tr(),
                      style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationField(
      TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: labelStyle,
        prefixIcon: Icon(icon, color: primaryColor),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.grey)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: primaryColor, width: 2)),
        filled: true,
        fillColor: Colors.white,
      ),
      onChanged: (value) => _searchAirports(value, controller),
      validator: (value) => value!.isEmpty ? 'Champ_obligatoire'.tr() : null,
    );
  }

  Widget _buildDateTile(String title, DateTime? date, bool isDeparture) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      title: Text(title, style: labelStyle),
      subtitle: Text(formatDate(date),
          style: TextStyle(
              color: date == null ? Colors.grey.shade600 : Colors.black87,
              fontSize: 16)),
      trailing: const Icon(Icons.calendar_today, color: primaryColor),
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Colors.grey, width: 0.5)),
      onTap: () => _selectDate(isDeparture: isDeparture),
    );
  }

  Widget _buildTimeTile() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      title: Text('Heure_de_prise_en_charge'.tr(), style: labelStyle),
      subtitle: Text(formatTime(pickupTime),
          style: TextStyle(
              color: pickupTime == null ? Colors.grey.shade600 : Colors.black87,
              fontSize: 16)),
      trailing: const Icon(Icons.access_time, color: primaryColor),
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Colors.grey, width: 0.5)),
      onTap: _selectTime,
    );
  }
}
