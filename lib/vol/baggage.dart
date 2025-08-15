import 'package:agencedevoyage/currency_provider.dart';
import 'package:agencedevoyage/vol/model.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class LuggageSelectionPage extends ConsumerStatefulWidget {
  const LuggageSelectionPage({super.key});

  @override
  ConsumerState<LuggageSelectionPage> createState() =>
      LuggageSelectionPageState();
}

class LuggageSelectionPageState extends ConsumerState<LuggageSelectionPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<LuggageOption> _selectedLuggage = [];
  double _totalPrice = 0;
  late Flight departureFlight;
  Flight? returnFlight;
  late Map<String, int> passengerCounts;
  late int totalPassengers;
  late double basePrice;
  late double seatPrice;
  late List<int> selectedSeats;

  // Dans la classe
  final Uuid _uuid = const Uuid(); // Ajouter cette variable de classe

  final List<LuggageOption> _luggageOptions = [
    LuggageOption(
      title: 'Bagage_Cabine'.tr(),
      price: 0, // Prix en DZD
      type: 'inclus',
      icon: Icons.work_outline,
      description: '10kg',
      isFree: true,
    ),
    LuggageOption(
      title: 'Bagage_en_Soute'.tr(),
      price: 4200, // 30€ → 4200 DZD (exemple de conversion)
      type: 'soute',
      icon: Icons.luggage,
      description: '+23kg',
    ),
    LuggageOption(
      title: 'Bagage_Premium'.tr(),
      price: 7000, // 50€ → 7000 DZD
      type: 'premium',
      icon: Icons.business_center,
      description: '+32kg',
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map;

    // Initialiser avec des valeurs par défaut
    departureFlight = args['departureFlight'] as Flight;
    returnFlight = args['returnFlight'] as Flight?;
    passengerCounts =
        (args['passengerCounts'] as Map? ?? {}).cast<String, int>();
    totalPassengers = args['totalPassengers'] as int? ?? 1;
    basePrice = (args['basePrice'] as double? ?? 0.0);
    seatPrice = (args['seatPrice'] as double? ?? 0.0);
    selectedSeats = (args['selectedSeats'] as List? ?? []).cast<int>();

    _totalPrice = basePrice + seatPrice;
  }
  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   final args =
  //       ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

  //   if (args != null && mounted) {
  //     setState(() {
  //       departureFlight = args['departureFlight'] as Flight;
  //       returnFlight = args['returnFlight'] as Flight?;
  //       totalPassengers = args['totalPassengers'] as int;
  //     });
  //   }
  // }

  void _toggleSelection(LuggageOption option) {
    setState(() {
      if (_selectedLuggage.contains(option)) {
        _selectedLuggage.remove(option);
      } else {
        _selectedLuggage.removeWhere((o) => o.type == option.type);
        _selectedLuggage.add(option);
      }

      // Calcul du prix des bagages (par passager)
      final luggagePrice =
          _selectedLuggage.fold<double>(0, (sum, o) => sum + o.price) *
              totalPassengers;

      // Mise à jour du total avec tous les composants
      _totalPrice = basePrice + seatPrice + luggagePrice;
    });
  }

  Future<void> _saveLuggageSelection() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      // Show error message and redirect to login
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez_vou_connecter_pour_continuer'.tr()),
          duration: Duration(seconds: 2),
        ),
      );
      // Navigate to login page (adjust the route name as per your app)
      Navigator.pushNamed(context, '/AuthPage');
      return;
    }
    try {
      // Calcul final avec tous les composants
      // Calcul final avec tous les composants
      // final luggagePrice =
      //     _selectedLuggage.fold(0.0, (sum, item) => sum + item.price) *
      //         totalPassengers;
      // final luggagePrice =
      //     _selectedLuggage.fold(0.0, (sum, item) => sum + item.price) *
      //         totalPassengers;
      final luggagePrice =
          _selectedLuggage.fold(0.0, (sum, item) => sum + item.price) *
              totalPassengers;

      final totalWithLuggage = basePrice + seatPrice + luggagePrice;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .update({
        'bookings': FieldValue.arrayUnion([/* ... */]),
        'luggage': _selectedLuggage.map((o) => o.toJson()).toList(),
        'totalPrice': totalWithLuggage,
      });

      // Dans _saveLuggageSelection() de LuggageSelectionPage
      Navigator.pushNamed(context, '/reservationSteps', arguments: {
        'departureFlight': departureFlight,
        'returnFlight': returnFlight,
        'passengerCounts': passengerCounts,
        'totalPassengers': totalPassengers,
        'totalPrice': totalWithLuggage, // ← Ajouter le prix total ici
        'basePrice': basePrice,
        'seatPrice': seatPrice,
        'selectedSeats': selectedSeats, // Doit être List<int>
        'selectedLuggage': _selectedLuggage.map((o) => o.toJson()).toList(),
        'luggagePrice': luggagePrice,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyNotifier = ref.watch(currencyProvider.notifier);
    final user = _auth.currentUser; // Get current user
    final formattedTotal = currencyNotifier.formatPrice(_totalPrice);
    return Scaffold(
      appBar: AppBar(
        title: Text('Sélection_des_bagages'.tr()),
      ),
      body: Column(
        children: [
          if (user == null) // Display message if user is not logged in
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Vous_devez_vous_connecter_pour_procéder_à_la_réservation'.tr(),
                style: TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _luggageOptions.length,
              itemBuilder: (context, index) {
                final option = _luggageOptions[index];
                final formattedPrice =
                    currencyNotifier.formatPrice(option.price);
                return _LuggageCard(
                  option: option,
                  isSelected: _selectedLuggage.contains(option),
                  onTap: () => _toggleSelection(option),
                  formattedPrice: formattedPrice,
                );
              },
            ),
          ),
          _TotalPriceBar(
            formattedTotal: formattedTotal,
            onContinue: _saveLuggageSelection,
            isActive: _selectedLuggage.isNotEmpty && user != null,
            total: _totalPrice,
          ),
        ],
      ),
    );
  }
}

class _LuggageCard extends StatelessWidget {
  final LuggageOption option;
  final bool isSelected;
  final VoidCallback onTap;
  final String formattedPrice;

  const _LuggageCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
    required this.formattedPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              if (option.isFree)
                Align(
                  alignment: Alignment.topCenter, // <-- au lieu de topStart
                  child: _FreeBadge(),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(option.icon, size: 40, color: Colors.blue),
                  const SizedBox(height: 10),
                  Text(
                    option.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    option.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (!option.isFree)
                    Text(
                      formattedPrice, // Utilisation du prix formaté
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                    ),
                ],
              ),
              if (isSelected)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(Icons.check_circle, color: Colors.green),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FreeBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Gratuit'.tr(),
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _TotalPriceBar extends StatelessWidget {
  final double total;
  final VoidCallback onContinue;
  final bool isActive;
  final String formattedTotal;

  const _TotalPriceBar({
    required this.total,
    required this.onContinue,
    required this.isActive,
    required this.formattedTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('${'Total'.tr()}: $formattedTotal',
              // Affichage du total formaté
              style:
                  //  Theme.of(context).textTheme.titleLarge,
                  TextStyle(fontSize: 16)),
          ElevatedButton.icon(
            icon: const Icon(Icons.arrow_forward, size: 20),
            label: Text(
              'Continuer'.tr(),
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
            onPressed: isActive ? onContinue : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class LuggageOption {
  final String title;
  final double price;
  final String type;
  final IconData icon;
  final String description;
  final bool isFree;

  LuggageOption({
    required this.title,
    required this.price,
    required this.type,
    required this.icon,
    required this.description,
    this.isFree = false,
  });
  Map<String, dynamic> toJson() => {
        'title': title,
        'price': price,
        'type': type,
        'description': description,
        'isFree': isFree,
        'iconCode': icon.codePoint,
      };

  factory LuggageOption.fromJson(Map<String, dynamic> json) => LuggageOption(
        title: json['title'],
        price: json['price'].toDouble(),
        type: json['type'],
        description: json['description'],
        isFree: json['isFree'] ?? false,
        icon: _iconFromCode(json['iconCode']), // Conversion depuis Firestore
      );
  static IconData _iconFromCode(int code) =>
      IconData(code, fontFamily: 'MaterialIcons', fontPackage: 'flutter');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LuggageOption &&
          runtimeType == other.runtimeType &&
          type == other.type;

  @override
  int get hashCode => type.hashCode;
}
