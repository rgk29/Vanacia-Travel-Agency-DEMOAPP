import 'package:agencedevoyage/voiture/Cardetails.dart';
import 'package:agencedevoyage/voiture/filtervoiture.dart';

import 'package:agencedevoyage/voiture/recherche.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agencedevoyage/currency_provider.dart';
import 'dart:math';
// Modifier l'import de local.dart
import 'package:agencedevoyage/voiture/local.dart'
    hide CarFilters; // Masque CarFilters de ce fichier

// Importer filtervoiture.dart normalement

class CarSearchResultsPage extends ConsumerStatefulWidget {
  final List<CarModel> carList;
  final int rentalDays;

  const CarSearchResultsPage({
    super.key,
    required this.carList,
    required this.rentalDays,
  });

  @override
  ConsumerState<CarSearchResultsPage> createState() =>
      CarSearchResultsPageState();
}

class CarSearchResultsPageState extends ConsumerState<CarSearchResultsPage> {
  late CarFilters _currentFilters;
  late List<CarModel> _filteredCars;

  @override
  void initState() {
    super.initState();
    // Initialisation des filtres avec les valeurs max trouvées
    final maxPrice = widget.carList.map((c) => c.pricePerDay).reduce(max);
    final maxDeposit = widget.carList.map((c) => c.securityDeposit).reduce(max);

    _currentFilters = CarFilters(
      minPrice: 0,
      maxPrice: maxPrice,
      minDeposit: 0,
      maxDeposit: maxDeposit,
      selectedTypes: {},
      selectedTransmissions: {},
      selectedAgencies: {},
    );

    _filteredCars = _applyFilters(widget.carList);
  }

  List<CarModel> _applyFilters(List<CarModel> cars) {
    return cars.where((car) {
      // Vérification de chaque critère de filtre
      final priceMatch = car.pricePerDay >= _currentFilters.minPrice &&
          car.pricePerDay <= _currentFilters.maxPrice;
      final depositMatch = car.securityDeposit >= _currentFilters.minDeposit &&
          car.securityDeposit <= _currentFilters.maxDeposit;

      final typeMatch = _currentFilters.selectedTypes.isEmpty ||
          _currentFilters.selectedTypes.contains(car.type);

      final transmissionMatch = _currentFilters.selectedTransmissions.isEmpty ||
          _currentFilters.selectedTransmissions.contains(car.transmission);

      final agencyMatch = _currentFilters.selectedAgencies.isEmpty ||
          _currentFilters.selectedAgencies.contains(car.rentalAgency);

      final acMatch =
          _currentFilters.hasAC == null || car.hasAC == _currentFilters.hasAC;

      return priceMatch &&
          depositMatch &&
          typeMatch &&
          transmissionMatch &&
          agencyMatch &&
          acMatch;
    }).toList();
  }

  void _showFilterDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => SmartFilterDialog(
        allCars: widget.carList,
        initialFilters: _currentFilters,
        onApply: (newFilters) {
          setState(() {
            _currentFilters = newFilters;
            _filteredCars = _applyFilters(widget.carList);
          });
        },
      ),
    );
  }

  void _updateFilters(CarFilters newFilters) {
    setState(() {
      _currentFilters = newFilters;
      _filteredCars = _applyFilters(widget.carList);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyNotifier = ref.watch(currencyProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "resultats_recherche".tr(),
          style: theme.textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: primaryColor, // correction ici
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list_rounded, size: 28),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: _buildResultsList(currencyNotifier, theme),
    );
  }

  Widget _buildResultsList(CurrencyNotifier currencyNotifier, ThemeData theme) {
    return _filteredCars.isEmpty
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off_rounded,
                    size: 60, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text('no_results'.tr(),
                    style: theme.textTheme.titleLarge
                        ?.copyWith(color: Colors.grey[600])),
              ],
            ),
          )
        : ListView.separated(
            padding: EdgeInsets.all(16),
            itemCount: _filteredCars.length,
            separatorBuilder: (context, index) => SizedBox(height: 16),
            itemBuilder: (context, index) =>
                _buildCarCard(_filteredCars[index], currencyNotifier, theme),
          );
  }

  Widget _buildCarCard(
      CarModel car, CurrencyNotifier currencyNotifier, ThemeData theme) {
    final totalPrice = car.pricePerDay * widget.rentalDays;
    final formattedPrice = currencyNotifier.formatPrice(totalPrice);
    final formattedDeposit = currencyNotifier.formatPrice(car.securityDeposit);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: 2,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            child: Stack(
              children: [
                Image.asset(car.imageUrl,
                    height: 180, width: double.infinity, fit: BoxFit.cover),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black54, Colors.transparent],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(car.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildFeatureChip(
                        icon: Icons.business_rounded,
                        label: car.rentalAgency,
                        color: Color(0xFF0A6DED)),
                    SizedBox(width: 8),
                    _buildFeatureChip(
                        icon: Icons.settings_rounded,
                        label: car.transmission,
                        color: Color(0xFF00C3FF)),
                  ],
                ),
                SizedBox(height: 12),
                _buildDetailRow(
                    icon: Icons
                        .door_back_door_rounded, // Nouvelle icône pour les portes
                    label:
                        '${car.doors} ${'doors'.tr()}'), // Utilisation de doors
                _buildDetailRow(
                    icon: Icons.ac_unit_rounded,
                    label:
                        '${'ac'.tr()}: ${car.hasAC ? 'yes'.tr() : 'no'.tr()}'),
                _buildDetailRow(
                    icon: Icons.security_rounded,
                    label: '${'deposit'.tr()}: $formattedDeposit'),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('total_price'.tr(),
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600])),
                        Text(formattedPrice,
                            style: theme.textTheme.headlineSmall?.copyWith(
                                color: Color(0xFF0A6DED), fontSize: 16)),
                      ],
                    ),
                    ElevatedButton.icon(
                      icon: Icon(Icons.arrow_forward_rounded, size: 15),
                      label:
                          Text("book_now".tr(), style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _showDetails(car, formattedPrice),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBadge(double rating) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber[700],
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildFeatureChip(
      {required IconData icon, required String label, required Color color}) {
    return Chip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      backgroundColor: color.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildDetailRow({required IconData icon, required String label}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          SizedBox(width: 8),
          Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
        ],
      ),
    );
  }

  void _showDetails(CarModel car, String formattedPrice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CarDetailsPage(car: car, totalPrice: formattedPrice),
      ),
    );
  }
}
