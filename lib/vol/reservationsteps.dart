import 'package:agencedevoyage/api/firebase_api.dart';
import 'package:agencedevoyage/hotels/rechercher.dart';
import 'package:agencedevoyage/vol/baggage.dart';
import 'package:agencedevoyage/vol/model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Ajoutez 'hide User' à l'import de Firebase
import 'package:firebase_auth/firebase_auth.dart'
    as firebase_auth; // <-- Modification ici// <-- Modification ici

// Importez votre modèle User normalement

import 'package:shimmer/shimmer.dart';
import 'seat_selection.dart';
import 'paymentselectionstep.dart';
import 'flighttichetdetailspage.dart';
import '/homepage.dart';
import 'package:easy_localization/easy_localization.dart';

class ReservationStepsPage extends StatefulWidget {
  const ReservationStepsPage({super.key});

  @override
  State<ReservationStepsPage> createState() => ReservationStepsPageState();
}

class ReservationStepsPageState extends State<ReservationStepsPage> {
  int currentStep = 0;
  double totalPrice = 0.0;
  int totalPassengers = 1; // à adapter dynamiquement
  final List<Widget> forms = [];
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<LuggageOption> _selectedLuggage = [];

  // Contrôleurs
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passportController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String _selectedCountry = 'Algeria';
  String _selectedGender = 'Male';
  late Flight departureFlight; // <-- Ajoutez cette ligne
  Flight? returnFlight;
  Map<String, int> passengerCounts = {}; // <-- Ajoutez cette ligne

  final Map<String, String> _countries = {
    'Algeria': 'DZ',
    'France': 'FR',
    'USA': 'US',
    'Spain': 'ES',
    'Germany': 'DE',
    'Arab Emirates': 'AEU',
  };
  Map<String, dynamic>? args;
  List<String> passengerTypes = [];
  // Ajoute une variable pour stocker la carte choisie
  Map<String, dynamic>? selectedPaymentMethod;

  bool _userDataLoaded = false;
  double basePrice = 0.0;
  double seatPrice = 0.0;
  List<int> selectedSeats = []; // <-- Ajoutez cette ligne
  double luggagePrice = 0.0; // <-- Ajoutez cette ligne

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;

      if (args is Map<String, dynamic>) {
        setState(() {
          departureFlight = args['departureFlight'] as Flight;
          returnFlight = args['returnFlight'] as Flight?;
          passengerCounts =
              (args['passengerCounts'] as Map).cast<String, int>();
          totalPassengers = args['totalPassengers'] as int;
          basePrice = (args['basePrice'] as double?) ?? 0.0;
          seatPrice = (args['seatPrice'] as double?) ?? 0.0;
          selectedSeats = List<int>.from(args['selectedSeats'] as List? ?? []);
          luggagePrice = (args['luggagePrice'] as double?) ?? 0.0;
          totalPrice = basePrice + seatPrice + luggagePrice;
        });
      } else {
        // Gérer le cas où les arguments sont invalides
        print('Arguments invalides: ${args.runtimeType}');
        Navigator.pop(context);
      }

      _loadUserData();
    });

    // Dans la méthode initState ou lors de la confirmation de paiement
  }

  Future<void> _saveFullReservation() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final reservationData = {
      'type': 'flight',
      'totalPrice':
          totalPrice, // Inclut déjà basePrice + seatPrice + luggagePrice
      'departureFlight': departureFlight.toMap(),
      'returnFlight': returnFlight?.toMap(),
      'selectedSeats': selectedSeats,
      'selectedBaggage': _selectedLuggage.map((e) => e.title).toList(),
      'passengerCounts': passengerCounts,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('flight_reservations')
        .add(reservationData);
  }

  void _updateSeatPrice(List<int> seats) {
    setState(() {
      seatPrice = 2000.0 * seats.length;
      totalPrice = basePrice + seatPrice + luggagePrice;
    });
  }

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   final args =
  //       ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

  //   if (args != null && args.containsKey('selectedLuggage')) {
  //     _selectedLuggage = List<LuggageOption>.from(args['selectedLuggage']);
  //   }
  // }

  Future<List<LuggageOption>> _fetchSelectedLuggage() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final luggageList = (doc.data()?['luggage'] as List?) ?? [];

    return luggageList
        .map((e) => LuggageOption.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _userDataLoaded = true;
    });

    try {
      firebase_auth.User? user = _auth.currentUser;
      if (user == null) return;

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get(GetOptions(source: Source.server));

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          _emailController.text = data['email'] ?? '';
          _fullNameController.text = data['fullName'] ?? '';
          _passportController.text = data['passport'] ?? '';
          _addressController.text = data['address'] ?? '';
          _postalCodeController.text = data['postalCode'] ?? '';
          _selectedGender = data['gender'] ?? 'Male';
          _selectedCountry = _countries.containsKey(data['country'])
              ? data['country']
              : 'Algeria';
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("${'Erreur_de_chargement_dutilisateur'.tr()} $e");
      }
    }
  }

  // Future<void> _loadUserData() async {
  //   final user = FirebaseAuth.instance.currentUser;
  //   if (user == null) return;

  //   final doc = await FirebaseFirestore.instance
  //       .collection('users')
  //       .doc(user.uid)
  //       .get();

  //   // Définir l'email depuis Firebase Auth
  //   _emailController.text = user.email ?? '';

  //   if (doc.exists) {
  //     setState(() {
  //       _fullNameController.text = doc['fullName'] ?? '';
  //       _passportController.text = doc['passport'] ?? '';
  //       _phoneController.text = doc['phone'] ?? '';
  //       _addressController.text = doc['address'] ?? '';
  //       _selectedCountry = doc['country'] ?? 'Algeria';
  //       _selectedGender = doc['gender'] ?? 'Male';
  //     });
  //   } else {
  //     // Créer le document avec l'email de Firebase Auth
  //     await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
  //       'email': user.email ?? '',
  //       'createdAt': FieldValue.serverTimestamp(),
  //     }, SetOptions(merge: true));
  //   }
  // }

  Future<void> _saveUserData() async {
    bool isFirstPassenger =
        true; // Ce sera utile si tu permets plusieurs passagers ensuite

    try {
      firebase_auth.User? user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).set({
        if (isFirstPassenger) ...{
          'email': _emailController.text.trim(),
          'fullName': _fullNameController.text.trim(),
          'passport': _passportController.text.trim(),
          'phone': _phoneController.text.trim(),
          'country': _selectedCountry,
          'gender': _selectedGender,
          'address': _addressController.text.trim(),
          'postalCode': _postalCodeController.text.trim(),
        }
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Informations_enregistrées".tr())),
      );

      _nextStep();
    } catch (e) {
      print("${'Erreur_denregistrement'.tr()}: $e");
    }
  }

  void _nextStep() {
    if (currentStep < 3) {
      setState(() => currentStep++);
    } else {
      // Étape finale atteinte, rediriger vers la HomePage
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false, // supprime les anciennes pages de la pile
      );
    }
  }

  void _previousStep() {
    if (currentStep > 0) {
      setState(() => currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Réservation".tr())),
      body: !_userDataLoaded
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Stepper(
                controlsBuilder: (context, details) {
                  // Cache "Continue" sur l'étape de paiement (index 2)
                  if (details.stepIndex == 2) {
                    return Container();
                  }
                  return Row(
                    children: [
                      ElevatedButton(
                        onPressed: details.onStepContinue,
                        child: Text('Continuer'.tr()),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: details.onStepCancel,
                        child: Text('Retour'.tr()),
                      ),
                    ],
                  );
                },
                physics: const ClampingScrollPhysics(),
                type: StepperType.vertical,
                currentStep: currentStep,
                onStepContinue: () {
                  if (currentStep == 0) {
                    _saveUserData();
                  } else if (currentStep == 2) {
                    if (selectedPaymentMethod == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                "Veuillez_choisir_un_moyen_de_paiement".tr())),
                      );
                    } else {
                      _nextStep();
                    }
                  } else {
                    _nextStep();
                  }
                },
                onStepCancel: _previousStep,
                steps: [
                  Step(
                    title: Text("Infos_personnelles".tr()),
                    isActive: currentStep >= 0,
                    state: currentStep > 0
                        ? StepState.complete
                        : StepState.editing,
                    content: _buildForm(),
                  ),
                  Step(
                    title: Text("Choix_du_siège".tr()),
                    content: SeatSelectionWidget(
                      basePrice: basePrice,
                      onSeatsSaved: (seats) {
                        _updateSeatPrice(seats);
                      },
                    ),
                    isActive: currentStep >= 1,
                  ),

                  Step(
                    title: Text("Paiement".tr()),
                    content: PaymentSelectionStep(
                        onCardSelected: (card) =>
                            setState(() => selectedPaymentMethod = card),
                        // Dans votre code de paiement
                        onPaymentConfirmed: () async {
                          try {
                            await _saveFullReservation();
                            FirebaseApi().addLocalNotification(
                              title: 'Confirmation_de_réservation_du_vol'.tr(),
                              body: 'Votre_paiement_a_été_accepté'.tr(),
                              data: {'type': 'reservation', 'id': '12345'},
                            );
                            if (mounted) _nextStep();
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Erreur: ${e.toString()}')),
                              );
                            }
                          }
                        }),
                    isActive: currentStep >= 2,
                  ),

// Modifiez la dernière étape du Stepper
                  Step(
                    title: Text("Détails_Du_Vol_🛫".tr()),
                    isActive: currentStep >= 3,
                    content: FutureBuilder<List<LuggageOption>>(
                      future: _fetchSelectedLuggage(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (snapshot.hasError || !snapshot.hasData) {
                          return const Text(
                              "Erreur lors du chargement des bagages.");
                        }

                        final selectedBaggage = snapshot.data!
                            .map((baggage) => baggage.title)
                            .join(', ');

                        return Column(
                          children: [
                            FlightTicketWidget(
                              fullName: _fullNameController.text,
                              country: _selectedCountry,
                              email: _emailController.text,
                              passportNumber: _passportController.text,
                              totalPrice:
                                  totalPrice, // ← Utilisez la variable totalPrice
                              selectedBaggage: selectedBaggage,
                            ),
                            const SizedBox(height: 15),
                            _buildHotelBookingCard(context),
                            const SizedBox(height: 15),
                            _buildPromoText(),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHotelBookingCard(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutQuint,
      margin: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A5C82), Color(0xFF3AB795)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.3),
            spreadRadius: 3,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 700),
                pageBuilder: (_, __, ___) => HotelSearchScreen(),
                transitionsBuilder: (_, animation, __, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.fastEaseInToSlowEaseOut,
                    )),
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Clicker_ici_pour_Complétez_votre_voyage".tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Réservez_maintenant_votre_hôtel".tr(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Shimmer(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.8),
                      Colors.white,
                      Colors.white.withOpacity(0.8),
                    ],
                  ),
                  child: const Icon(
                    Icons.hotel_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPromoText() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 1000),
      opacity: 1,
      child: Transform.translate(
        offset: const Offset(0, 0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                color: Colors.blueGrey[700],
                fontStyle: FontStyle.italic,
                fontSize: 14,
              ),
              children: [
                TextSpan(
                  text: "🌟 ",
                  style: TextStyle(
                    color: Colors.amber[600],
                    fontSize: 16,
                  ),
                ),
                TextSpan(
                  text: "Offre_spéciale_voyageurs".tr(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2A5C82),
                  ),
                ),
                TextSpan(
                  text: "Découvrez_des_promotion_jusqu_a_15%_de_réduction".tr(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmationContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Votre_réservation _a_été_complétée_avec_succès".tr(),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FlightTicketWidget(
                  fullName: _fullNameController.text,
                  country: _selectedCountry,
                  email: _emailController.text,
                  passportNumber: _passportController.text,
                  totalPrice: totalPrice,
                  selectedBaggage: _selectedLuggage
                      .map((e) => e.title)
                      .join(', '), // ou base + extra si sièges premium
                ),
              ),
            );
          },
          child: Text("Voir_mon_billet".tr()),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      children: List.generate(totalPassengers, (index) {
        final isPrimaryPassenger = index == 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            Text(
              '${'Passager'.tr()}${index + 1} - ${passengerTypes.isNotEmpty ? passengerTypes[index] : "Adulte"}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (isPrimaryPassenger) ...[
              // Données préremplies depuis Firestore
              TextField(
                controller: _fullNameController,
                decoration: InputDecoration(labelText: 'Nom_complet'.tr()),
              ),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'.tr()),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: _passportController,
                decoration: InputDecoration(labelText: 'Passeport'.tr()),
              ),
              TextField(
                controller: _addressController,
                decoration: InputDecoration(labelText: 'Adresse'.tr()),
              ),
              TextField(
                controller: _postalCodeController,
                decoration: InputDecoration(labelText: 'Code_postal'.tr()),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _phoneController,
                decoration:
                    InputDecoration(labelText: 'Numéro_de_téléphone'.tr()),
                keyboardType: TextInputType.phone,
              ),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: InputDecoration(labelText: 'Genre'.tr()),
                items: ['Male', 'Female', 'Other'].map((String value) {
                  return DropdownMenuItem(
                      value: value, child: Text(value.tr()));
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedGender = value);
                },
              ),
              DropdownButtonFormField<String>(
                value: _selectedCountry,
                decoration: InputDecoration(labelText: 'Pays'.tr()),
                items: _countries.keys.map((String key) {
                  return DropdownMenuItem(value: key, child: Text(key));
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedCountry = value);
                },
              ),
            ] else ...[
              // Champs vides pour les autres passagers
              TextField(
                decoration: InputDecoration(labelText: 'Nom_complet'.tr()),
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Passeport'.tr()),
              ),
            ]
          ],
        );
      }),
    );
  }
}
