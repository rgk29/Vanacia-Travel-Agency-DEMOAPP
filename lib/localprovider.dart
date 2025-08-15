// Ajoutez ceci dans un nouveau fichier locale_provider.dart
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('fr'));

  void setLocale(Locale newLocale) {
    state = newLocale;
  }
}
