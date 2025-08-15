import 'package:agencedevoyage/currency_provider.dart';
import 'package:agencedevoyage/voyageOrganiser/payment.dart';
import 'package:agencedevoyage/voyageOrganiser/trip.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HotelPersonalInfoPage extends ConsumerStatefulWidget {
  final String userEmail;
  final Trip trip;
  final Hotel hotel;
  final String roomType;
  final int adults;
  final int children;
  final Map<String, dynamic> hotelReservation;
  final String tripId;

  const HotelPersonalInfoPage({
    super.key,
    required this.userEmail,
    required this.trip,
    required this.hotel,
    required this.roomType,
    required this.adults,
    required this.children,
    required this.hotelReservation,
    required this.tripId,
  });

  @override
  HotelPersonalInfoPageState createState() => HotelPersonalInfoPageState();
}

class HotelPersonalInfoPageState extends ConsumerState<HotelPersonalInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passportController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _selectedCountry = 'Algeria';
  String _selectedGender = 'Male';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _emailController.text = widget.userEmail;
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      setState(() {
        _nameController.text = doc['fullName'] ?? '';
        _passportController.text = doc['passport'] ?? '';
        _phoneController.text = doc['phone'] ?? '';
        _selectedCountry = doc['country'] ?? 'Algeria';
        _selectedGender = doc['gender'] ?? 'Male';
      });
    }
  }

  Future<void> _saveUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'fullName': _nameController.text,
      'passport': _passportController.text,
      'phone': _phoneController.text,
      'country': _selectedCountry,
      'gender': _selectedGender,
      'lastUpdate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _saveReservation() async {
    final currencyState = ref.read(currencyProvider);
    final reservationData = {
      'userEmail': widget.userEmail,
      'tripId': widget.trip.id,
      'hotel': widget.hotel.name,
      'roomType': widget.roomType,
      'adults': widget.adults,
      'children': widget.children,
      'totalPrice':
          widget.hotelReservation['totalPrice'] * currencyState.currentRate,
      'baseCurrency': 'DZD',
      'basePrice': widget.hotelReservation['originalPrice'],
      'conversionRate': currencyState.currentRate,
      'conversionDate': FieldValue.serverTimestamp(),
      'personalInfo': {
        'fullName': _nameController.text,
        'passport': _passportController.text,
        'phone': _phoneController.text,
        'country': _selectedCountry,
        'gender': _selectedGender,
      },
      'reservationDate': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('organized_trips_reservations')
        .add(reservationData);
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _saveUserData();
        await _saveReservation();

        if (!mounted) return;

        final currencyNotifier = ref.read(currencyProvider.notifier);
        final currencyState = ref.read(currencyProvider);

        var userData = {
          'fullName': _nameController.text,
          'email': _emailController.text,
          'passport': _passportController.text,
          'phone': _phoneController.text,
        };

        final reservation = Reservation(
          userEmail: widget.userEmail,
          roomType: widget.roomType,
          departureCity: widget.trip.departureCity,
          destination: widget.trip.destination,
          departureDate: widget.trip.departureDate,
          returnDate: widget.trip.returnDate,
          hotelName: widget.hotel.name,
          hotelStars: widget.hotel.stars,
          totalPrice:
              widget.hotelReservation['totalPrice'] * currencyState.currentRate,
          currency: currencyState.currency,
          paymentMethod: '',
          status: 'pending',
          reservationType: 'trip',
        );

        final PaymentMethod? selectedMethod =
            await Navigator.push<PaymentMethod?>(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentPagee(
              reservation: reservation,
              totalPrice: currencyNotifier.formatPrice(reservation.totalPrice),
              userData: userData,
              hotel: widget.hotel, // ✅  userData: userData,
            ),
          ),
        );

        if (selectedMethod != null && mounted) {
          final updatedReservation = reservation.copyWith(
            paymentMethod: selectedMethod.maskedNumber,
            status: 'confirmed',
          );

          await FirebaseFirestore.instance
              .collection('organized_trips_reservations')
              .add(updatedReservation.toMap());

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('success'.tr()),
              content: Text('reservation_success'.tr()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('ok'.tr()),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('error_occurred'.tr())),
          );
        }
      }
    }
  }

  Widget _buildDropdown<T>({
    required String label,
    required List<DropdownMenuItem<T>> items,
    required T value,
    required Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label.tr(),
        border: const OutlineInputBorder(),
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('personal_information'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'full_name'.tr()),
                validator: (value) =>
                    value!.isEmpty ? 'required_field'.tr() : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'email'.tr()),
                enabled: false,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passportController,
                decoration: InputDecoration(labelText: 'passport_number'.tr()),
                validator: (value) =>
                    value!.length < 6 ? 'invalid_passport'.tr() : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'phone_number'.tr()),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value!.length < 8 ? 'invalid_phone'.tr() : null,
              ),
              const SizedBox(height: 20),
              _buildDropdown<String>(
                label: 'gender',
                value: _selectedGender,
                items: ['Male', 'Female', 'Other']
                    .map((g) => DropdownMenuItem(
                          value: g,
                          child: Text(g.tr()),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedGender = value!),
              ),
              const SizedBox(height: 20),
              _buildDropdown<String>(
                label: 'country',
                value: _selectedCountry,
                items: ['Algeria', 'France', 'USA', 'Spain', 'Germany']
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.tr()),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedCountry = value!),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: Text('confirm_reservation'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
