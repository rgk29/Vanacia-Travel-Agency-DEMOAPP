import 'package:flutter_riverpod/flutter_riverpod.dart';

final currencyProvider = StateNotifierProvider<CurrencyNotifier, CurrencyState>(
  (ref) => CurrencyNotifier(),
);

class CurrencyState {
  final String currency;
  final Map<String, double> rates;

  const CurrencyState({
    required this.currency,
    this.rates = const {
      'USD': 0.0072,
      'EUR': 0.0067,
      'DZD': 1.0,
    },
  });

  // Ajouter cette méthode pour faciliter l'accès
  double get currentRate => rates[currency] ?? 1.0;

  // Méthode copyWith corrigée
  CurrencyState copyWith({
    String? currency, // 🔥 Nom du paramètre aligné avec le champ
    Map<String, double>? rates,
  }) {
    return CurrencyState(
      currency: currency ?? this.currency, // ✅ Correction ici
      rates: rates ?? this.rates,
    );
  }
}

class CurrencyNotifier extends StateNotifier<CurrencyState> {
  CurrencyNotifier() : super(const CurrencyState(currency: 'DZD'));

  // Méthode corrigée pour mettre à jour la devise
  void setCurrency(String currency) {
    state = state.copyWith(currency: currency); // 🚨 Plus de "selected" !
  }

  String formatPrice(double price) {
    final rate = state.rates[state.currency] ?? 1.0;
    final convertedPrice = price * rate;
    return switch (state.currency) {
      'USD' => '\$${convertedPrice.toStringAsFixed(2)}',
      'EUR' => '€${convertedPrice.toStringAsFixed(2)}',
      _ => '${convertedPrice.toStringAsFixed(2)} DA',
    };
  }
}
