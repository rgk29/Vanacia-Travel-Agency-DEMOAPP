import 'dart:math';

import 'package:agencedevoyage/voiture/local.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class CarFilters {
  double minPrice;
  double maxPrice;
  double minDeposit;
  double maxDeposit;
  Set<String> selectedTypes;
  Set<String> selectedTransmissions;
  Set<String> selectedAgencies;
  bool? hasAC;

  CarFilters({
    required this.minPrice,
    required this.maxPrice,
    required this.minDeposit,
    required this.maxDeposit,
    required this.selectedTypes,
    required this.selectedTransmissions,
    required this.selectedAgencies,
    this.hasAC,
  });

  CarFilters copyWith({
    double? minPrice,
    double? maxPrice,
    double? minDeposit,
    double? maxDeposit,
    Set<String>? selectedTypes,
    Set<String>? selectedTransmissions,
    Set<String>? selectedAgencies,
    bool? hasAC,
  }) {
    return CarFilters(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minDeposit: minDeposit ?? this.minDeposit,
      maxDeposit: maxDeposit ?? this.maxDeposit,
      selectedTypes: selectedTypes ?? this.selectedTypes,
      selectedTransmissions:
          selectedTransmissions ?? this.selectedTransmissions,
      selectedAgencies: selectedAgencies ?? this.selectedAgencies,
      hasAC: hasAC ?? this.hasAC,
    );
  }
}

class SmartFilterDialog extends StatefulWidget {
  final List<CarModel> allCars;
  final CarFilters initialFilters;
  final Function(CarFilters) onApply;

  const SmartFilterDialog({
    super.key,
    required this.allCars,
    required this.initialFilters,
    required this.onApply,
  });

  @override
  SmartFilterDialogState createState() => SmartFilterDialogState();
}

class SmartFilterDialogState extends State<SmartFilterDialog> {
  late CarFilters _currentFilters;
  late double _maxPrice;
  late double _maxDeposit;

  @override
  void initState() {
    super.initState();
    _maxPrice = widget.allCars.map((c) => c.pricePerDay).reduce(max);
    _maxDeposit = widget.allCars.map((c) => c.securityDeposit).reduce(max);
    _currentFilters = widget.initialFilters;
  }

  void _applyFilters() {
    widget.onApply(_currentFilters);
    Navigator.pop(context);
  }

  Widget _buildFilterSection(String title, List<Widget> children,
      {IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              if (icon != null)
                Icon(icon,
                    size: 20, color: Theme.of(context).colorScheme.primary),
              if (icon != null) const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
        ),
        ...children,
        const Divider(height: 32),
      ],
    );
  }

  Widget _buildRangeFilter(
    String title,
    double min,
    double max,
    RangeValues values,
    Function(RangeValues) onChanged, {
    String Function(double)? valueFormatter,
  }) {
    final theme = Theme.of(context);
    final formattedStart =
        valueFormatter?.call(values.start) ?? values.start.toString();
    final formattedEnd =
        valueFormatter?.call(values.end) ?? values.end.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(title, style: theme.textTheme.bodyMedium),
        ),
        RangeSlider(
          values: values,
          min: min,
          max: max,
          divisions: 10,
          labels: RangeLabels(formattedStart, formattedEnd),
          activeColor: theme.colorScheme.primary,
          inactiveColor: theme.colorScheme.primary.withOpacity(0.2),
          onChanged: onChanged,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(formattedStart, style: theme.textTheme.bodySmall),
              Text(formattedEnd, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTypeFilter() {
    final types = widget.allCars.map((c) => c.type).toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('Type_de_vehicule'.tr(),
              style: Theme.of(context).textTheme.bodyMedium),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: types.map((type) {
              return CheckboxListTile(
                title: Text(type),
                value: _currentFilters.selectedTypes.contains(type),
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (selected) => _updateTypes(type, selected ?? false),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _updateTypes(String type, bool selected) {
    setState(() {
      final newTypes = Set<String>.from(_currentFilters.selectedTypes);
      selected ? newTypes.add(type) : newTypes.remove(type);
      _currentFilters = _currentFilters.copyWith(selectedTypes: newTypes);
    });
  }

  Widget _buildTransmissionFilter() {
    final transmissions = widget.allCars.map((c) => c.transmission).toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('Transmission'.tr(),
              style: Theme.of(context).textTheme.bodyMedium),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: transmissions.map((trans) {
              return CheckboxListTile(
                title: Text(trans),
                value: _currentFilters.selectedTransmissions.contains(trans),
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (selected) =>
                    _updateTransmissions(trans, selected ?? false),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _updateTransmissions(String trans, bool selected) {
    setState(() {
      final newTrans = Set<String>.from(_currentFilters.selectedTransmissions);
      selected ? newTrans.add(trans) : newTrans.remove(trans);
      _currentFilters =
          _currentFilters.copyWith(selectedTransmissions: newTrans);
    });
  }

  Widget _buildAgencyFilter() {
    final agencies = widget.allCars.map((c) => c.rentalAgency).toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('Agence_de_location'.tr(),
              style: Theme.of(context).textTheme.bodyMedium),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: agencies.map((agency) {
              return CheckboxListTile(
                title: Text(agency),
                value: _currentFilters.selectedAgencies.contains(agency),
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (selected) =>
                    _updateAgencies(agency, selected ?? false),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _updateAgencies(String agency, bool selected) {
    setState(() {
      final newAgencies = Set<String>.from(_currentFilters.selectedAgencies);
      selected ? newAgencies.add(agency) : newAgencies.remove(agency);
      _currentFilters = _currentFilters.copyWith(selectedAgencies: newAgencies);
    });
  }

  void _resetToDefault() {
    final defaultFilters = CarFilters(
      minPrice: 0,
      maxPrice: _maxPrice,
      minDeposit: 0,
      maxDeposit: _maxDeposit,
      selectedTypes: {},
      selectedTransmissions: {},
      selectedAgencies: {},
      hasAC: null,
    );
    widget.onApply(defaultFilters);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.filter_alt_rounded, color: colorScheme.primary),
          const SizedBox(width: 12),
          Text('Filtres_avances'.tr(), style: theme.textTheme.headlineSmall),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterSection(
                'Prix'.tr(),
                [
                  _buildRangeFilter(
                    'Prix_journalier'.tr(),
                    0,
                    _maxPrice,
                    RangeValues(
                        _currentFilters.minPrice, _currentFilters.maxPrice),
                    (values) => setState(() => _currentFilters =
                        _currentFilters.copyWith(
                            minPrice: values.start, maxPrice: values.end)),
                    valueFormatter: (value) => '${value.round()} ${'DA'.tr()}',
                  ),
                ],
                icon: Icons.attach_money_rounded,
              ),
              _buildFilterSection(
                'Caution'.tr(),
                [
                  _buildRangeFilter(
                    'Montant_de_la_caution'.tr(),
                    0,
                    _maxDeposit,
                    RangeValues(
                        _currentFilters.minDeposit, _currentFilters.maxDeposit),
                    (values) => setState(() => _currentFilters =
                        _currentFilters.copyWith(
                            minDeposit: values.start, maxDeposit: values.end)),
                    valueFormatter: (value) => '${value.round()} ${'DA'.tr()}',
                  ),
                ],
                icon: Icons.security_rounded,
              ),
              _buildFilterSection(
                'Caractéristiques'.tr(),
                [
                  _buildTypeFilter(),
                  const SizedBox(height: 12),
                  _buildTransmissionFilter(),
                  const SizedBox(height: 12),
                  _buildAgencyFilter(),
                ],
                icon: Icons.directions_car_filled_rounded,
              ),
              _buildFilterSection(
                'Options'.tr(),
                [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.ac_unit_rounded,
                            size: 20, color: theme.colorScheme.secondary),
                        const SizedBox(width: 12),
                        Text('Climatisation'.tr(),
                            style: theme.textTheme.bodyMedium),
                        const Spacer(),
                        SizedBox(
                          width: 100,
                          child: DropdownButtonFormField<bool?>(
                            isExpanded: true,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            value: _currentFilters.hasAC,
                            items: [
                              DropdownMenuItem(
                                value: null,
                                child: Text('Indifférent'.tr(),
                                    style: theme.textTheme.bodyMedium),
                              ),
                              DropdownMenuItem(
                                value: true,
                                child: Text('Oui'.tr(),
                                    style: theme.textTheme.bodyMedium),
                              ),
                              DropdownMenuItem(
                                value: false,
                                child: Text('Non'.tr(),
                                    style: theme.textTheme.bodyMedium),
                              ),
                            ],
                            onChanged: (value) => setState(() =>
                                _currentFilters =
                                    _currentFilters.copyWith(hasAC: value)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                icon: Icons.tune_rounded,
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      actions: [
        OutlinedButton.icon(
          icon: const Icon(Icons.restart_alt_rounded),
          label: Text('Réinitialiser'.tr()),
          onPressed: _resetToDefault,
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.error,
            side: BorderSide(color: colorScheme.error),
          ),
        ),
        const Spacer(),
        FilledButton.icon(
          icon: const Icon(Icons.check_rounded),
          label: Text('Appliquer_les_filtres'.tr()),
          onPressed: _applyFilters,
        ),
      ],
    );
  }
}
