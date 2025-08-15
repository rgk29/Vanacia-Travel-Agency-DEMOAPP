// Ajoutez ceci dans votre fichier currency_provider.dart ou un nouveau fichier providers.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, List<String>>(
        (ref) => FavoritesNotifier());
final authProvider =
    StateNotifierProvider<AuthNotifier, User?>((ref) => AuthNotifier());

class AuthNotifier extends StateNotifier<User?> {
  AuthNotifier() : super(FirebaseAuth.instance.currentUser) {
    // Écoute les changements d'état d'authentification
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      state = user;
    });
  }
}

class FavoritesNotifier extends StateNotifier<List<String>> {
  FavoritesNotifier() : super([]) {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList('favorites') ?? [];
  }

  Future<void> toggleFavorite(String hotelId) async {
    List<String> newFavorites = List.from(state);
    if (newFavorites.contains(hotelId)) {
      newFavorites.remove(hotelId);
    } else {
      newFavorites.add(hotelId);
    }
    state = newFavorites;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', newFavorites);
  }
}
