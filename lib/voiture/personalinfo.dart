import 'package:agencedevoyage/voiture/local.dart';
import 'package:agencedevoyage/voiture/payment.dart';
import 'package:agencedevoyage/voiture/recherche.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PersonalInfoPage extends StatefulWidget {
  final CarModel car;
  final String totalPrice;

  const PersonalInfoPage({
    super.key,
    required this.car,
    required this.totalPrice,
  });

  @override
  State<PersonalInfoPage> createState() => PersonalInfoPageState();
}

class PersonalInfoPageState extends State<PersonalInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passportController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _selectedCountry = 'Algeria';
  String _selectedGender = 'Male';

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;

    _loadUserData();
  }

  Future<void> _saveUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'fullName': _fullNameController.text,
      'email': _emailController.text,
      'passport': _passportController.text,
      'phone': _phoneController.text,
      'country': _selectedCountry,
      'gender': _selectedGender,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    // Définir l'email depuis Firebase Auth
    _emailController.text = user.email ?? '';

    if (doc.exists) {
      setState(() {
        _fullNameController.text = doc['fullName'] ?? '';
        _passportController.text = doc['passport'] ?? '';
        _phoneController.text = doc['phone'] ?? '';
        _selectedCountry = doc['country'] ?? 'Algeria';
        _selectedGender = doc['gender'] ?? 'Male';
      });
    } else {
      // Créer le document avec l'email de Firebase Auth
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': user.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> _createInitialUserDocument(User user) async {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'fullName': '',
      'email': user.email ?? '',
      'passport': '',
      'phone': '',
      'country': 'Algeria',
      'gender': 'Male',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passportController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _navigateToPayment() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('utilisateur_non_connecte'.tr())),
          );
          return;
        }

        // Sauvegarde initiale si l'email n'existe pas
        if (_emailController.text.isEmpty) {
          _emailController.text = user.email ?? '';
        }

        await _saveUserData();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentPage(
              car: widget.car,
              totalPrice: widget.totalPrice,
              userData: {
                'fullName': _fullNameController.text,
                'email': _emailController.text,
                'passport': _passportController.text,
                'phone': _phoneController.text,
                'country': _selectedCountry,
                'gender': _selectedGender,
              },
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('erreur_sauvegarde'.tr(args: [e.toString()]))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('personal_information'.tr()),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
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
              _buildFormField(
                controller: _fullNameController,
                label: 'full_name'.tr(),
                validator: (value) =>
                    value!.isEmpty ? 'required_field'.tr() : null,
              ),
              const SizedBox(height: 20),
              _buildFormField(
                controller: _emailController,
                label: 'email'.tr(),
                readOnly: true,
                validator: (value) =>
                    value!.contains('@') ? null : 'invalid_email'.tr(),
              ),
              const SizedBox(height: 20),
              _buildFormField(
                controller: _passportController,
                label: 'passport_number'.tr(),
                validator: (value) =>
                    value!.length < 6 ? 'invalid_passport'.tr() : null,
              ),
              const SizedBox(height: 20),
              _buildFormField(
                controller: _phoneController,
                label: 'phone_number'.tr(),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value!.length < 8 ? 'invalid_phone'.tr() : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: InputDecoration(
                  labelText: 'genre'.tr(),
                  border: const OutlineInputBorder(),
                ),
                items: ['Male', 'Female', 'Other']
                    .map((gender) => DropdownMenuItem(
                          value: gender,
                          child: Text(gender.tr()),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedGender = value!),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedCountry,
                decoration: InputDecoration(
                  labelText: 'pays'.tr(),
                  border: const OutlineInputBorder(),
                ),
                items: const ['Algeria', 'France', 'USA', 'Spain', 'Germany']
                    .map((country) => DropdownMenuItem(
                          value: country,
                          child: Text(country),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedCountry = value!),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _navigateToPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor, // ou votre accentColor
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 100, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'next'.tr(),
                      style: TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.arrow_forward, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    bool readOnly = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          backgroundColor: const Color.fromARGB(0, 228, 228, 228),
          color: const Color.fromARGB(255, 24, 20, 20),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown({
    required String value,
    required String label,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          backgroundColor: Theme.of(context).primaryColor,
          color: Colors.white,
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: accentColor,
      ),
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item.tr()),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}
