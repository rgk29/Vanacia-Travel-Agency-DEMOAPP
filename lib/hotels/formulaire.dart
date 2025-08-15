import 'package:agencedevoyage/currency_provider.dart';
import 'package:agencedevoyage/hotels/local.dart';
import 'package:agencedevoyage/hotels/payment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HotelPersonalInfoPage extends ConsumerStatefulWidget {
  // final String userEmail;
  final Hotells hotel;
  final String roomType;
  final Map<String, dynamic> hotelReservation;
  final HotelReservation reservation;

  const HotelPersonalInfoPage({
    super.key,
    // required this.userEmail,
    required this.hotel,
    required this.roomType,
    required this.hotelReservation,
    required this.reservation,
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

    // Récupérer l'email depuis Firebase Auth
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
    }
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

  // Future<void> _saveReservation() async {
  //   final user = FirebaseAuth.instance.currentUser;
  //   if (user == null) return;

  //   final currencyState = ref.read(currencyProvider);

  //   await FirebaseFirestore.instance.collection('hotel_reservations').add({
  //     'userEmail': user.email, // Récupérer l'email directement depuis Firebase
  //     'hotel': widget.hotel.name,
  //     'roomType': widget.roomType,

  //     //  'adults': widget.adults,
  //     //'children': widget.children,
  //     'totalPrice':
  //         widget.hotelReservation['totalPrice'] * currencyState.currentRate,
  //     'baseCurrency': 'DZD',
  //     'basePrice': widget.hotelReservation['originalPrice'],
  //     'conversionRate': currencyState.currentRate,
  //     'conversionDate': FieldValue.serverTimestamp(),
  //     'personalInfo': {
  //       'fullName': _nameController.text,
  //       'passport': _passportController.text,
  //       'phone': _phoneController.text,
  //       'country': _selectedCountry,
  //       'gender': _selectedGender,
  //     },
  //     'reservationDate': FieldValue.serverTimestamp(),
  //   });
  // }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _saveUserData();
        // await _saveReservation();

        if (!mounted) return;

        final currencyNotifier = ref.read(currencyProvider.notifier);
        final currencyState = ref.read(currencyProvider);

        var userData = {
          'fullName': _nameController.text,
          'email': _emailController.text,
          'passport': _passportController.text,
          'phone': _phoneController.text,
        };

        final totalPriceConverted =
            widget.hotelReservation['totalPrice'] * currencyState.currentRate;

        // Dans _submitForm, MODIFIER la navigation :
        final PaymentMethod? selectedMethod =
            await Navigator.push<PaymentMethod?>(
          context,
          // Dans l'appel MaterialPageRoute
          MaterialPageRoute(
            builder: (context) => HotelPaymentPage(
              hotel: widget.hotel,
              reservation: widget.reservation.copyWith(
                id: widget.reservation.id,
                totalPrice: totalPriceConverted,
                paymentDetails: {
                  'currency':
                      currencyNotifier.state.currency, // Accès via le state
                  'exchange_rate':
                      currencyNotifier.state.currentRate, // Getter du state
                  'original_price': widget.reservation.totalPrice,
                },
                hotelDetails: {
                  ...widget.reservation.hotelDetails,
                  'duration': widget.hotel.durationDays,
                },
              ),
              userData: userData,
              totalPrice: currencyNotifier.formatPrice(totalPriceConverted),
            ),
          ),
        );

        if (selectedMethod != null && mounted) {
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
                label: 'gender'.tr(),
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
