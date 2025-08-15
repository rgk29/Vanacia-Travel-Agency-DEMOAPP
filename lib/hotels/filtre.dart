// filters_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agencedevoyage/hotels/local.dart';

class FiltersState {
  final Set<Facilities> selectedFacilities;
  final RangeValues priceRange;
  final bool filtersApplied;

  const FiltersState({
    this.selectedFacilities = const {},
    this.priceRange = const RangeValues(0, double.infinity),
    this.filtersApplied = false,
  });

  FiltersState copyWith({
    Set<Facilities>? selectedFacilities,
    RangeValues? priceRange,
    bool? filtersApplied,
  }) {
    return FiltersState(
      selectedFacilities: selectedFacilities ?? this.selectedFacilities,
      priceRange: priceRange ?? this.priceRange,
      filtersApplied: filtersApplied ?? this.filtersApplied,
    );
  }
}

class FiltersNotifier extends StateNotifier<FiltersState> {
  FiltersNotifier() : super(const FiltersState());

  void updateFacilities(Facilities facility, bool selected) {
    final facilities = Set<Facilities>.from(state.selectedFacilities);
    selected ? facilities.add(facility) : facilities.remove(facility);
    state = state.copyWith(selectedFacilities: facilities);
  }

  void updatePriceRange(RangeValues range) {
    state = state.copyWith(priceRange: range);
  }

  void applyFilters() {
    state = state.copyWith(filtersApplied: true);
  }

  void resetFilters() {
    state = const FiltersState();
  }

  // void reset() {
  //   state = FiltersState();
  // }
}

final filtersProvider = StateNotifierProvider<FiltersNotifier, FiltersState>(
    (ref) => FiltersNotifier());
